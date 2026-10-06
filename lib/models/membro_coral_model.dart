class MembroCoralModel {
  final String? id;
  final dynamic dataHoraRegistro;
  final String? ativo;
  final String? nome;
  final String? naipeVocal;
  final String? nomeResponsavel;
  final dynamic dataNascimento;
  final dynamic cpf;
  final dynamic rg;
  final dynamic endereco;
  final String? email;
  final dynamic telefone;
  final String? tipoSanguineo;
  final dynamic telefoneEmergencia;
  final String? igreja;
  final List<dynamic> datasEnsaiosPresente;
  final List<dynamic> datasEnsaiosFaltas;

  // Campos calculados dinamicamente para estatísticas do dashboard
  final String? statusGeral;
  final List<String> ultimos4Ensaios;
  final double? assiduidade;

  const MembroCoralModel({
    this.id,
    this.dataHoraRegistro,
    this.ativo,
    this.nome,
    this.naipeVocal,
    this.nomeResponsavel,
    this.dataNascimento,
    this.cpf,
    this.rg,
    this.endereco,
    this.email,
    this.telefone,
    this.tipoSanguineo,
    this.telefoneEmergencia,
    this.igreja,
    this.datasEnsaiosPresente = const [],
    this.datasEnsaiosFaltas = const [],
    this.statusGeral,
    this.ultimos4Ensaios = const [],
    this.assiduidade,
  });

  factory MembroCoralModel.fromJson(Map<String, dynamic> json, {String? id}) {
    final rawUltimos4 = json['ultimos4Ensaios'];
    List<String> ultimos4 = [];
    if (rawUltimos4 is List) {
      ultimos4 = rawUltimos4.map((e) => e.toString()).toList();
    }

    double? assid;
    if (json['assiduidade'] != null) {
      assid = (json['assiduidade'] as num).toDouble();
    }

    return MembroCoralModel(
      id: id ?? json['id']?.toString(),
      dataHoraRegistro: json['dataHoraRegistro'],
      ativo: json['ativo']?.toString(),
      nome: json['nome']?.toString(),
      naipeVocal: json['naipeVocal']?.toString(),
      nomeResponsavel: json['nomeResponsavel']?.toString(),
      dataNascimento: json['dataNascimento'],
      cpf: json['cpf'],
      rg: json['rg'],
      endereco: json['endereco'],
      email: json['email']?.toString(),
      telefone: json['telefone'],
      tipoSanguineo: json['tipoSanguineo']?.toString(),
      telefoneEmergencia: json['telefoneEmergencia'],
      igreja: json['igreja']?.toString(),
      datasEnsaiosPresente: (json['datasEnsaiosPresente'] as List<dynamic>?)?.toList() ?? [],
      datasEnsaiosFaltas: (json['datasEnsaiosFaltas'] as List<dynamic>?)?.toList() ?? [],
      statusGeral: json['statusGeral']?.toString(),
      ultimos4Ensaios: ultimos4,
      assiduidade: assid,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'dataHoraRegistro': dataHoraRegistro,
      'ativo': ativo,
      'nome': nome,
      'naipeVocal': naipeVocal,
      'nomeResponsavel': nomeResponsavel,
      'dataNascimento': dataNascimento,
      'cpf': cpf,
      'rg': rg,
      'endereco': endereco,
      'email': email,
      'telefone': telefone,
      'tipoSanguineo': tipoSanguineo,
      'telefoneEmergencia': telefoneEmergencia,
      'igreja': igreja,
      'datasEnsaiosPresente': datasEnsaiosPresente,
      'datasEnsaiosFaltas': datasEnsaiosFaltas,
      'statusGeral': statusGeralCalculado,
      'ultimos4Ensaios': ultimos4EnsaiosCalculados,
      'assiduidade': assiduidadeCalculada,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Retorna as iniciais do nome do corista (ex: "Mariana Albuquerque" -> "MA").
  String get initials {
    final trimmed = (nome ?? '').trim();
    if (trimmed.isEmpty) return '??';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  /// Retorna o valor calculado de assiduidade (0.0 a 1.0).
  double get assiduidadeCalculada {
    if (assiduidade != null) return assiduidade!;
    final pres = datasEnsaiosPresente.length;
    final falt = datasEnsaiosFaltas.length;
    final total = pres + falt;
    if (total == 0) return 1.0;
    return (pres / total).clamp(0.0, 1.0);
  }

  /// Retorna a lista dos últimos 4 ensaios (ex: ["P", "P", "F", "N"]).
  List<String> get ultimos4EnsaiosCalculados {
    if (ultimos4Ensaios.isNotEmpty) return ultimos4Ensaios;
    // Se não tiver explícito, simula baseado no histórico recente
    final pres = datasEnsaiosPresente.length;
    final falt = datasEnsaiosFaltas.length;
    final total = pres + falt;
    if (total == 0) return const ["N", "N", "N", "N"];
    final list = <String>[];
    for (int i = 0; i < 4; i++) {
      if (i < pres) {
        list.add("P");
      } else if (i < total) {
        list.add("F");
      } else {
        list.add("N");
      }
    }
    return list;
  }

  /// Retorna o status geral calculado dinamicamente.
  String get statusGeralCalculado {
    if (ativo == 'n') return 'Licença / Inativo';

    // Verifica se possui 3 ou mais faltas consecutivas nos ensaios recentes
    final u4 = ultimos4EnsaiosCalculados;
    int faltasConsecutivas = 0;
    for (int i = u4.length - 1; i >= 0; i--) {
      if (u4[i] == 'F') {
        faltasConsecutivas++;
      } else if (u4[i] == 'P') {
        break;
      }
    }
    if (faltasConsecutivas >= 3) return 'Faltoso Crítico';

    final pres = datasEnsaiosPresente.length;
    final falt = datasEnsaiosFaltas.length;
    final total = pres + falt;
    if (total == 0) return 'Ativo';
    final assid = assiduidadeCalculada;
    if (assid < 0.60 && total >= 3) return 'Faltoso Crítico';

    if (statusGeral != null && statusGeral!.isNotEmpty && statusGeral != 'Faltoso Crítico') {
      return statusGeral!;
    }

    if (assid >= 0.90) return 'Ativo Pleno';
    if (assid >= 0.75) return 'Ativo';
    return 'Regular';
  }

  MembroCoralModel copyWith({
    String? id,
    dynamic dataHoraRegistro,
    String? ativo,
    String? nome,
    String? naipeVocal,
    String? nomeResponsavel,
    dynamic dataNascimento,
    dynamic cpf,
    dynamic rg,
    dynamic endereco,
    String? email,
    dynamic telefone,
    String? tipoSanguineo,
    dynamic telefoneEmergencia,
    String? igreja,
    List<dynamic>? datasEnsaiosPresente,
    List<dynamic>? datasEnsaiosFaltas,
    String? statusGeral,
    List<String>? ultimos4Ensaios,
    double? assiduidade,
  }) {
    return MembroCoralModel(
      id: id ?? this.id,
      dataHoraRegistro: dataHoraRegistro ?? this.dataHoraRegistro,
      ativo: ativo ?? this.ativo,
      nome: nome ?? this.nome,
      naipeVocal: naipeVocal ?? this.naipeVocal,
      nomeResponsavel: nomeResponsavel ?? this.nomeResponsavel,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      cpf: cpf ?? this.cpf,
      rg: rg ?? this.rg,
      endereco: endereco ?? this.endereco,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      tipoSanguineo: tipoSanguineo ?? this.tipoSanguineo,
      telefoneEmergencia: telefoneEmergencia ?? this.telefoneEmergencia,
      igreja: igreja ?? this.igreja,
      datasEnsaiosPresente: datasEnsaiosPresente ?? this.datasEnsaiosPresente,
      datasEnsaiosFaltas: datasEnsaiosFaltas ?? this.datasEnsaiosFaltas,
      statusGeral: statusGeral ?? this.statusGeral,
      ultimos4Ensaios: ultimos4Ensaios ?? this.ultimos4Ensaios,
      assiduidade: assiduidade ?? this.assiduidade,
    );
  }
}
