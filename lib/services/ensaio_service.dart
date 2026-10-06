import '../models/ensaio_model.dart';
import '../models/membro_coral_model.dart';
import 'firestore_service.dart';

/// Serviço desacoplado responsável por gerenciar a coleção 'ensaios' e atualizar as estatísticas dos coristas.
class EnsaioService {
  final FirestoreService _firestoreService;
  static const String collectionName = 'ensaios';
  static const String membrosCollection = 'membro_coral';

  EnsaioService({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  /// Busca o registro de ensaio para uma data específica (Formato YYYY-MM-DD).
  Future<EnsaioModel?> getEnsaioPorData(String dataEnsaio) async {
    final list = await _firestoreService.getCollectionAs<EnsaioModel>(
      collectionPath: collectionName,
      builder: (data, id) => EnsaioModel.fromJson(data, id: id),
      queryBuilder: (query) => query.where('dataEnsaio', isEqualTo: dataEnsaio).limit(1),
    );
    if (list.isNotEmpty) return list.first;
    return null;
  }

  /// Busca a lista completa de ensaios gravados.
  Future<List<EnsaioModel>> getTodosEnsaios() async {
    return _firestoreService.getCollectionAs<EnsaioModel>(
      collectionPath: collectionName,
      builder: (data, id) => EnsaioModel.fromJson(data, id: id),
      queryBuilder: (query) => query.orderBy('dataEnsaio', descending: true),
    );
  }

  /// Salva ou atualiza um documento de ensaio no Firestore.
  Future<void> salvarEnsaio(EnsaioModel ensaio) async {
    await _firestoreService.setDocument(
      collectionPath: collectionName,
      docId: ensaio.idEnsaio,
      data: ensaio.toJson(),
    );
  }

  /// Zera (reset) todas as presenças e faltas gravadas para determinado ensaio.
  Future<void> resetarEnsaio(String idEnsaio) async {
    await _firestoreService.updateDocument(
      collectionPath: collectionName,
      docId: idEnsaio,
      data: {
        'membrosPresentes': [],
        'membrosFaltantes': [],
      },
    );
  }

  /// Recalcula e atualiza no Firestore o 'statusGeral', 'ultimos4Ensaios' e 'assiduidade' dos coristas.
  Future<void> recalcularEstatisticaMembros({
    required List<MembroCoralModel> membros,
    required List<EnsaioModel> todosEnsaios,
  }) async {
    if (membros.isEmpty) return;

    // Filtra apenas ensaios que possuem pelo menos 1 presença ou 1 falta gravada
    final ensaiosValidos = todosEnsaios
        .where((e) => e.membrosPresentes.isNotEmpty || e.membrosFaltantes.isNotEmpty)
        .toList()
      ..sort((a, b) => a.dataEnsaio.compareTo(b.dataEnsaio));

    final batch = _firestoreService.batch();

    for (final membro in membros) {
      if (membro.id == null || membro.id!.isEmpty) continue;

      int presencas = membro.datasEnsaiosPresente.length;
      int faltas = membro.datasEnsaiosFaltas.length;
      final ultimos4 = <String>[];
      int faltasConsecutivasRecentes = 0;
      bool contandoFaltasConsecutivas = true;

      // Percorre os ensaios válidos do mais recente para o mais antigo
      final ensaiosRecentes = ensaiosValidos.reversed.toList();
      for (final ensaio in ensaiosRecentes) {
        final estavaPresente = ensaio.membrosPresentes.contains(membro.id);
        final estavaFaltante = ensaio.membrosFaltantes.contains(membro.id);

        if (estavaPresente) {
          presencas++;
          if (ultimos4.length < 4) ultimos4.insert(0, "P");
          contandoFaltasConsecutivas = false;
        } else if (estavaFaltante) {
          faltas++;
          if (ultimos4.length < 4) ultimos4.insert(0, "F");
          if (contandoFaltasConsecutivas) {
            faltasConsecutivasRecentes++;
          }
        }
      }

      // Preenche os ensaios restantes com "N" (Sem Registro / Não Realizado)
      while (ultimos4.length < 4) {
        ultimos4.insert(0, "N");
      }

      final total = presencas + faltas;
      final double assiduidade = total > 0 ? (presencas / total).clamp(0.0, 1.0) : 1.0;

      String statusGeral;
      if (membro.ativo == 'n') {
        statusGeral = 'Licença / Inativo';
      } else if (total == 0) {
        statusGeral = 'Ativo';
      } else if (faltasConsecutivasRecentes >= 3 || assiduidade < 0.60) {
        statusGeral = 'Faltoso Crítico';
      } else if (assiduidade >= 0.90) {
        statusGeral = 'Ativo Pleno';
      } else if (assiduidade >= 0.75) {
        statusGeral = 'Ativo';
      } else {
        statusGeral = 'Regular';
      }

      final docRef = _firestoreService.instance.collection(membrosCollection).doc(membro.id);
      batch.update(docRef, {
        'statusGeral': statusGeral,
        'ultimos4Ensaios': ultimos4,
        'assiduidade': assiduidade,
      });
    }

    await batch.commit();
  }
}
