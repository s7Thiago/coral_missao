class EnsaioModel {
  final String idEnsaio;
  final String dataEnsaio; // Formato YYYY-MM-DD
  final List<String> membrosPresentes;
  final List<String> membrosFaltantes;
  final String? observacao;

  const EnsaioModel({
    required this.idEnsaio,
    required this.dataEnsaio,
    this.membrosPresentes = const [],
    this.membrosFaltantes = const [],
    this.observacao,
  });

  factory EnsaioModel.fromJson(Map<String, dynamic> json, {String? id}) {
    final rawPresentes = json['membrosPresentes'] as List<dynamic>? ?? [];
    final rawFaltantes = json['membrosFaltantes'] as List<dynamic>? ?? [];

    return EnsaioModel(
      idEnsaio: id ?? json['idEnsaio']?.toString() ?? json['id']?.toString() ?? '',
      dataEnsaio: json['dataEnsaio']?.toString() ?? '',
      membrosPresentes: rawPresentes.map((e) => e.toString()).toList(),
      membrosFaltantes: rawFaltantes.map((e) => e.toString()).toList(),
      observacao: json['observacao']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idEnsaio': idEnsaio,
      'dataEnsaio': dataEnsaio,
      'membrosPresentes': membrosPresentes,
      'membrosFaltantes': membrosFaltantes,
      if (observacao != null) 'observacao': observacao,
    };
  }

  EnsaioModel copyWith({
    String? idEnsaio,
    String? dataEnsaio,
    List<String>? membrosPresentes,
    List<String>? membrosFaltantes,
    String? observacao,
  }) {
    return EnsaioModel(
      idEnsaio: idEnsaio ?? this.idEnsaio,
      dataEnsaio: dataEnsaio ?? this.dataEnsaio,
      membrosPresentes: membrosPresentes ?? this.membrosPresentes,
      membrosFaltantes: membrosFaltantes ?? this.membrosFaltantes,
      observacao: observacao ?? this.observacao,
    );
  }
}
