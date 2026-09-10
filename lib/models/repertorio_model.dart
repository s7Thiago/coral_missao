class Voz {
  final String naipe;
  final String link;

  Voz({required this.naipe, required this.link});

  factory Voz.fromJson(Map<String, dynamic> json) {
    return Voz(
      naipe: json['naipe']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'naipe': naipe, 'link': link};
  }
}

class RepertorioItem {
  final String id;
  final String titulo;
  final List<Voz> vozes;
  final String tamanho;
  final List<String> letra;

  RepertorioItem({
    required this.id,
    required this.titulo,
    required this.vozes,
    required this.tamanho,
    required this.letra,
  });

  factory RepertorioItem.fromJson(Map<String, dynamic> json) {
    var rawVozes = json['vozes'];
    List<Voz> vozesList = [];
    if (rawVozes is List) {
      vozesList = rawVozes
          .whereType<Map>()
          .map((i) => Voz.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }

    var rawLetra = json['letra'];
    List<String> letraList = [];
    if (rawLetra is List) {
      letraList = rawLetra.map((e) => e?.toString() ?? '').toList();
    }

    return RepertorioItem(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      vozes: vozesList,
      tamanho: json['tamanho']?.toString() ?? '',
      letra: letraList,
    );
  }

  bool get temLetra {
    return letra.isNotEmpty && letra.any((line) => line.trim().isNotEmpty);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'vozes': vozes.map((v) => v.toJson()).toList(),
      'tamanho': tamanho,
      'letra': letra,
    };
  }
}
