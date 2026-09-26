import 'package:flutter/material.dart';

/// Cabeçalho flutuante sutil que aparece no topo quando o usuário rola a letra da música.
class FloatingLyricsHeader extends StatelessWidget {
  final String title;
  final bool isVisible;
  final VoidCallback? onClose;
  final TextAlign textAlign;

  const FloatingLyricsHeader({
    super.key,
    required this.title,
    required this.isVisible,
    this.onClose,
    this.textAlign = TextAlign.left,
  });

  CrossAxisAlignment _getCrossAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.left:
      case TextAlign.start:
      default:
        return CrossAxisAlignment.start;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      top: isVisible ? 0 : -60,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC).withValues(alpha: 0.92),
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (onClose != null)
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 28,
                    ),
                    onPressed: onClose,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Fechar',
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: _getCrossAlignment(textAlign),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: textAlign,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A365D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Letra da música',
                        textAlign: textAlign,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
