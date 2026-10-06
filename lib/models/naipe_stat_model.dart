/// Modelo desacoplado para representar as estatísticas de equilíbrio vocal de um naipe.
class NaipeStatModel {
  final String nomeNaipe;
  final int countVozes;
  final double assiduidadeMedia;

  const NaipeStatModel({
    required this.nomeNaipe,
    required this.countVozes,
    required this.assiduidadeMedia,
  });

  int get assiduidadePercent => (assiduidadeMedia * 100).round();

  bool get precisaAtencao => countVozes > 0 && assiduidadeMedia < 0.85;
}
