import 'package:flutter_test/flutter_test.dart';
import 'package:coral_missao/models/membro_coral_model.dart';

void main() {
  group('MembroCoralModel Tests', () {
    test('Converte JSON para MembroCoralModel e vice-versa corretamente', () {
      final sampleJson = {
        "dataHoraRegistro": 45690.41609677083,
        "ativo": "s",
        "nome": "Aline Rodrigues Ferreira ",
        "naipeVocal": "Soprano",
        "nomeResponsavel": "Responsavel Teste",
        "dataNascimento": 34707,
        "cpf": "120.215.216-30 ",
        "rg": 3977407,
        "endereco": "Quadra 6A conjunto B Lote 5 Arapoangas",
        "email": "alinerodrigues1139@gmail.com",
        "telefone": 61998407309,
        "tipoSanguineo": "O+",
        "telefoneEmergencia": 61998407309,
        "igreja": "IASD Arapoangas Central ",
        "datasEnsaiosPresente": ["2026-01-10"],
        "datasEnsaiosFaltas": []
      };

      final model = MembroCoralModel.fromJson(sampleJson, id: 'doc_123');

      expect(model.id, equals('doc_123'));
      expect(model.nome, equals('Aline Rodrigues Ferreira '));
      expect(model.naipeVocal, equals('Soprano'));
      expect(model.nomeResponsavel, equals('Responsavel Teste'));
      expect(model.ativo, equals('s'));
      expect(model.dataNascimento, equals(34707));
      expect(model.cpf, equals('120.215.216-30 '));
      expect(model.rg, equals(3977407));
      expect(model.email, equals('alinerodrigues1139@gmail.com'));
      expect(model.datasEnsaiosPresente, contains('2026-01-10'));

      final jsonOut = model.toJson();
      expect(jsonOut['nome'], equals('Aline Rodrigues Ferreira '));
      expect(jsonOut['naipeVocal'], equals('Soprano'));
      expect(jsonOut['id'], equals('doc_123'));
    });

    test('Calcula Faltoso Crítico quando possui 3 faltas consecutivas nos ultimos4Ensaios', () {
      final membro = const MembroCoralModel(
        id: '1',
        nome: 'João Silva',
        ativo: 's',
        ultimos4Ensaios: ['P', 'F', 'F', 'F'],
        assiduidade: 0.75,
      );

      expect(membro.statusGeralCalculado, equals('Faltoso Crítico'));
    });

    test('Não considera Faltoso Crítico quando possui apenas 1 falta e ensaios sem registro N', () {
      final membro = const MembroCoralModel(
        id: '2',
        nome: 'Maria Souza',
        ativo: 's',
        ultimos4Ensaios: ['N', 'N', 'N', 'F'],
        datasEnsaiosPresente: [],
        datasEnsaiosFaltas: ['2026-03-01'],
        assiduidade: 0.0,
      );

      expect(membro.statusGeralCalculado, equals('Regular'));
    });
  });
}
