import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/membro_coral_model.dart';
import 'firestore_service.dart';

/// Serviço desacoplado responsável pelas operações relativas aos membros do coral na collection 'membro_coral'.
class MembroCoralService {
  final FirestoreService _firestoreService;
  static const String collectionName = 'membro_coral';

  MembroCoralService({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  /// Auxiliar resiliente para carregar o conteúdo JSON tanto via rootBundle quanto via File (fallback para dev).
  Future<String> _loadJsonContent(String assetPath) async {
    try {
      return await rootBundle.loadString(assetPath);
    } catch (e) {
      if (!kIsWeb) {
        try {
          final file = File(assetPath);
          if (await file.exists()) {
            return await file.readAsString();
          }
        } catch (_) {}
      }
      throw Exception(
        'Não foi possível carregar "$assetPath". Se acabou de adicionar a declaração no pubspec.yaml, reinicie completamente a aplicação (Full Restart/Rebuild).\n\nDetalhes: $e',
      );
    }
  }

  /// Popula a collection 'membro_coral' no Firestore a partir do arquivo JSON de ficha cadastral.
  Future<int> seedMembrosCoralFromAsset({String assetPath = 'assets/ficha_cadastral.json'}) async {
    final jsonString = await _loadJsonContent(assetPath);
    final List<dynamic> jsonList = jsonDecode(jsonString);

    if (jsonList.isEmpty) return 0;

    final List<MembroCoralModel> membros = jsonList
        .whereType<Map<String, dynamic>>()
        .map((json) => MembroCoralModel.fromJson(json))
        .toList();

    const chunkSize = 400;
    int savedCount = 0;

    for (var i = 0; i < membros.length; i += chunkSize) {
      final end = (i + chunkSize < membros.length) ? i + chunkSize : membros.length;
      final chunk = membros.sublist(i, end);
      final batch = _firestoreService.batch();

      for (final membro in chunk) {
        final docRef = _firestoreService.instance.collection(collectionName).doc();
        batch.set(docRef, membro.toJson());
        savedCount++;
      }

      await batch.commit();
    }

    return savedCount;
  }

  /// Busca todos os membros cadastrados na collection 'membro_coral'.
  Future<List<MembroCoralModel>> getMembrosCoral() async {
    return _firestoreService.getCollectionAs<MembroCoralModel>(
      collectionPath: collectionName,
      builder: (data, id) => MembroCoralModel.fromJson(data, id: id),
    );
  }

  /// Adiciona um novo corista na collection 'membro_coral' no Firestore.
  Future<String> addMembroCoral(MembroCoralModel membro) async {
    final docId = await _firestoreService.addDocument(
      collectionPath: collectionName,
      data: membro.toJson(),
    );
    return docId;
  }

  /// Atualiza o cadastro de um corista no Firestore.
  Future<void> updateMembroCoral(MembroCoralModel membro) async {
    if (membro.id == null || membro.id!.isEmpty) {
      throw Exception('ID do membro inválido para atualização.');
    }
    await _firestoreService.setDocument(
      collectionPath: collectionName,
      docId: membro.id!,
      data: membro.toJson(),
      merge: true,
    );
  }

  /// Remove o cadastro de um corista da coleção 'membro_coral' no Firestore.
  Future<void> deleteMembroCoral(String docId) async {
    if (docId.isEmpty) {
      throw Exception('ID do membro inválido para remoção.');
    }
    await _firestoreService.deleteDocument(
      collectionPath: collectionName,
      docId: docId,
    );
  }
}
