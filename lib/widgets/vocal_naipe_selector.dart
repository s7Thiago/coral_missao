import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/screen_utils.dart';
import '../viewmodels/repertorio_viewmodel.dart';

class NaipeChipData {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const NaipeChipData({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class VocalNaipeSelector extends StatelessWidget {
  final double bottomMargin;

  const VocalNaipeSelector({
    super.key,
    this.bottomMargin = 16.0,
  });

  static const List<NaipeChipData> naipes = [
    NaipeChipData(
      key: 'SOPRANO',
      label: 'Soprano',
      icon: Icons.face_3_rounded,
      color: AppColors.soprano,
    ),
    NaipeChipData(
      key: 'CONTRALTO',
      label: 'Contralto',
      icon: Icons.record_voice_over_rounded,
      color: AppColors.contralto,
    ),
    NaipeChipData(
      key: 'TENOR',
      label: 'Tenor',
      icon: Icons.face_6_rounded,
      color: AppColors.tenor,
    ),
    NaipeChipData(
      key: 'BAIXO',
      label: 'Baixo',
      icon: Icons.record_voice_over_rounded,
      color: AppColors.baixo,
    ),
    NaipeChipData(
      key: 'TODAS AS VOZES',
      label: 'Todas as Vozes',
      icon: Icons.groups_rounded,
      color: AppColors.todasAsVozes,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RepertorioViewModel>();
    final selectedNaipe = viewModel.selectedNaipe;

    final double maxWidth = context.isDesktop
        ? 680
        : context.isTablet
            ? 600
            : MediaQuery.of(context).size.width * 0.94;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomMargin,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            height: 58,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: naipes.map((naipe) {
                    final isSelected = selectedNaipe.toUpperCase() == naipe.key.toUpperCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _NaipeChipItem(
                        data: naipe,
                        isSelected: isSelected,
                        onTap: () {
                          context.read<RepertorioViewModel>().selectNaipe(naipe.key);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NaipeChipItem extends StatelessWidget {
  final NaipeChipData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _NaipeChipItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = data.color;

    return AnimatedScale(
      scale: isSelected ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor
                  : activeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? activeColor : activeColor.withValues(alpha: 0.35),
                width: isSelected ? 1.8 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  data.icon,
                  size: 18,
                  color: isSelected ? Colors.white : activeColor,
                ),
                const SizedBox(width: 7),
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : activeColor,
                    letterSpacing: 0.2,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
