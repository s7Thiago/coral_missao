import 'package:flutter/material.dart';

/// Controles flutuantes sutis com orientação dinâmica (Vertical ou Horizontal).
class FloatingAlignmentControls extends StatelessWidget {
  final TextAlign textAlign;
  final ValueChanged<TextAlign> onAlignChanged;
  final Axis axis;

  const FloatingAlignmentControls({
    super.key,
    required this.textAlign,
    required this.onAlignChanged,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    const animationDuration = Duration(milliseconds: 300);
    const animationCurve = Curves.fastOutSlowIn;
    final isHorizontal = axis == Axis.horizontal;

    final children = [
      _buildButton(
        icon: Icons.format_align_left_rounded,
        align: TextAlign.left,
        tooltip: 'Alinhar à esquerda',
      ),
      SizedBox(width: isHorizontal ? 4 : 0, height: isHorizontal ? 0 : 4),
      _buildButton(
        icon: Icons.format_align_center_rounded,
        align: TextAlign.center,
        tooltip: 'Centralizar',
      ),
      SizedBox(width: isHorizontal ? 4 : 0, height: isHorizontal ? 0 : 4),
      _buildButton(
        icon: Icons.format_align_right_rounded,
        align: TextAlign.right,
        tooltip: 'Alinhar à direita',
      ),
    ];

    return AnimatedContainer(
      duration: animationDuration,
      curve: animationCurve,
      padding: EdgeInsets.symmetric(
        horizontal: isHorizontal ? 4 : 3,
        vertical: isHorizontal ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF13324D).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: animationDuration,
        curve: animationCurve,
        child: isHorizontal
            ? Row(mainAxisSize: MainAxisSize.min, children: children)
            : Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required TextAlign align,
    required String tooltip,
  }) {
    final isSelected = textAlign == align;

    return InkWell(
      onTap: () => onAlignChanged(align),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A365D).withValues(alpha: 0.9)
              : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            key: ValueKey('${align}_$isSelected'),
            size: 18,
            color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }
}
