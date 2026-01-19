class Voz {
  final String naipe;
  final String link;

  Voz({required this.naipe, required this.link});

  factory Voz.fromJson(Map<String, dynamic> json) {
    return Voz(naipe: json['naipe'], link: json['link']);
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

  RepertorioItem({
    required this.id,
    required this.titulo,
    required this.vozes,
    required this.tamanho,
  });

  factory RepertorioItem.fromJson(Map<String, dynamic> json) {
    var list = json['vozes'] as List;
    List<Voz> vozesList = list.map((i) => Voz.fromJson(i)).toList();

    return RepertorioItem(
      id: json['id'],
      titulo: json['titulo'],
      vozes: vozesList,
      tamanho: json['tamanho'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'vozes': vozes.map((v) => v.toJson()).toList(),
      'tamanho': tamanho,
    };
  }
}
