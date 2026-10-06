import 'package:flutter/material.dart';
import '../models/naipe_stat_model.dart';
import '../viewmodels/admin_panel_viewmodel.dart';

/// Componente desacoplado que exibe o card de "Equilíbrio Vocal dos Naipes",
/// apresentando a contagem de vozes e a assiduidade média por naipe.
class VocalBalanceCard extends StatelessWidget {
  final AdminPanelViewModel viewModel;

  const VocalBalanceCard({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final stats = viewModel.statsNaipes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Equilíbrio Vocal dos Naipes',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Assiduidade consolidada por seção (Último mês)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: Color(0xFFB45309),
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Lista de Seções Vocais
          ...stats.map((stat) => _buildNaipeRow(context, stat)),
        ],
      ),
    );
  }

  Widget _buildNaipeRow(BuildContext context, NaipeStatModel stat) {
    final color = _getNaipeColor(stat.nomeNaipe);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Marcador de cor
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                stat.nomeNaipe,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                '${stat.countVozes} vozes',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${stat.assiduidadePercent}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (stat.precisaAtencao) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ATENÇÃO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Barra de Progresso do Naipe
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stat.assiduidadeMedia,
              minHeight: 7,
              backgroundColor: const Color(0xFFEEF2FF),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNaipeColor(String nomeNaipe) {
    if (nomeNaipe.contains('Soprano')) return const Color(0xFF1E3A8A);
    if (nomeNaipe.contains('Contralto')) return const Color(0xFF065F46);
    if (nomeNaipe.contains('Tenor')) return const Color(0xFF92400E);
    return const Color(0xFF1E3A8A); // Baixos & Barítonos
  }
}
