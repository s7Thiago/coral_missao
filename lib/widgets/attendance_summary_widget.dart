import 'package:flutter/material.dart';
import '../models/membro_coral_model.dart';

/// Widget resumido e desacoplado que combina de forma limpa e minimalista:
/// Status Geral, Últimos 4 Ensaios e Porcentagem de Assiduidade.
class AttendanceSummaryWidget extends StatelessWidget {
  final MembroCoralModel membro;
  final bool compact;

  const AttendanceSummaryWidget({
    super.key,
    required this.membro,
    this.compact = false,
  });

  Widget _buildDot(String tipo, {double size = 8}) {
    if (tipo == 'P') {
      // Presente: Verde sólido
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF12B76A),
          shape: BoxShape.circle,
        ),
      );
    } else if (tipo == 'F') {
      // Falta: Vermelho sólido
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFF04438),
          shape: BoxShape.circle,
        ),
      );
    } else if (tipo == 'J') {
      // Justificado: Azul claro sólido
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF38BDF8),
          shape: BoxShape.circle,
        ),
      );
    } else {
      // "N" ou Sem Registro: Anel cinza opaco com borda suave delicada
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = membro.statusGeralCalculado;
    final assiduidade = membro.assiduidadeCalculada;
    final ultimos4 = membro.ultimos4EnsaiosCalculados;

    final percentText = '${(assiduidade * 100).toInt()}%';

    Color statusBg;
    Color statusText;
    IconData? statusIcon;

    if (status == 'Ativo Pleno') {
      statusBg = const Color(0xFFD1FADF);
      statusText = const Color(0xFF027A48);
    } else if (status == 'Ativo') {
      statusBg = const Color(0xFFECFDF3);
      statusText = const Color(0xFF12B76A);
    } else if (status == 'Regular') {
      statusBg = const Color(0xFFF2F4F7);
      statusText = const Color(0xFF344054);
    } else if (status == 'Faltoso Crítico') {
      statusBg = const Color(0xFFFEE4E2);
      statusText = const Color(0xFFB42318);
      statusIcon = Icons.priority_high_rounded;
    } else {
      statusBg = const Color(0xFFF2F4F7);
      statusText = const Color(0xFF667085);
    }

    Color barColor;
    if (assiduidade >= 0.85) {
      barColor = const Color(0xFF16476B);
    } else if (assiduidade >= 0.60) {
      barColor = const Color(0xFF0284C7);
    } else {
      barColor = const Color(0xFFD92D20);
    }

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (statusIcon != null) ...[
                  Icon(statusIcon, size: 12, color: statusText),
                  const SizedBox(width: 3),
                ],
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: statusText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 4 Pontos dos ensaios recentes
              Row(
                mainAxisSize: MainAxisSize.min,
                children: ultimos4.map((tipo) => _buildDot(tipo, size: 7)).toList(),
              ),
              const SizedBox(width: 8),
              // Assiduidade %
              Text(
                percentText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: barColor,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusText,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusText,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // 4 Pontos
        Row(
          children: ultimos4.map((tipo) => _buildDot(tipo, size: 9)).toList(),
        ),
        const SizedBox(width: 16),
        // Assiduidade Bar
        SizedBox(
          width: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                percentText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: assiduidade,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFEAECF0),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
