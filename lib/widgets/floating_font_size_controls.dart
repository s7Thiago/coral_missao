import 'dart:async';
import 'package:flutter/material.dart';

/// Controles flutuantes interativos para ajuste do tamanho da fonte.
/// Suporta orientação dinâmica (Vertical ou Horizontal).
class FloatingFontSizeControls extends StatefulWidget {
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback? onResetFontSize;
  final double minFontSize;
  final double maxFontSize;
  final Axis axis;

  const FloatingFontSizeControls({
    super.key,
    required this.fontSize,
    required this.onFontSizeChanged,
    this.onResetFontSize,
    this.minFontSize = 12.0,
    this.maxFontSize = 48.0,
    this.axis = Axis.vertical,
  });

  @override
  State<FloatingFontSizeControls> createState() =>
      _FloatingFontSizeControlsState();
}

class _FloatingFontSizeControlsState extends State<FloatingFontSizeControls> {
  bool _isExpanded = false;
  bool _isDragging = false;
  Timer? _inactivityTimer;
  double _dragStartFontSize = 18.0;

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isExpanded) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _startInactivityTimer();
    } else {
      _inactivityTimer?.cancel();
    }
  }

  void _changeFontSize(double delta) {
    final newSize =
        (widget.fontSize + delta).clamp(widget.minFontSize, widget.maxFontSize);
    widget.onFontSizeChanged(newSize);
    if (_isExpanded) {
      _startInactivityTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    const animationDuration = Duration(milliseconds: 300);
    const animationCurve = Curves.fastOutSlowIn;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Overlay de feedback com o tamanho atual quando arrastando (Posicionado em Stack sem alterar o alinhamento da Row)
        if (_isDragging)
          Positioned(
            top: -34,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _isDragging ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF13324D).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${widget.fontSize.toInt()} pt',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // Botão principal flutuante / Container Expandido com animações suaves
        AnimatedContainer(
          duration: animationDuration,
          curve: animationCurve,
          padding: const EdgeInsets.all(3),
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
            child: AnimatedSwitcher(
              duration: animationDuration,
              switchInCurve: animationCurve,
              switchOutCurve: animationCurve,
              child: _isExpanded
                  ? _buildExpandedControls(
                      key: ValueKey('expanded_${widget.axis}'),
                      axis: widget.axis,
                    )
                  : _buildSingleFab(key: const ValueKey('single')),
            ),
          ),
        ),
      ],
    );
  }

  /// Botão único compacto no estado padrão (suporta toque simples e arrasto)
  Widget _buildSingleFab({required Key key}) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: _toggleExpanded,
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
          _dragStartFontSize = widget.fontSize;
        });
      },
      onPanUpdate: (details) {
        final deltaScale = -details.delta.dy / 8.0 + details.delta.dx / 8.0;
        final newSize = (_dragStartFontSize + deltaScale)
            .clamp(widget.minFontSize, widget.maxFontSize);
        _dragStartFontSize = newSize;
        widget.onFontSizeChanged(newSize);
      },
      onPanEnd: (_) {
        setState(() {
          _isDragging = false;
        });
      },
      onPanCancel: () {
        setState(() {
          _isDragging = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF1A365D).withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.format_size_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Botões expansíveis (+) e (-) (Vertical ou Horizontal)
  Widget _buildExpandedControls({required Key key, required Axis axis}) {
    final isHorizontal = axis == Axis.horizontal;

    final children = [
      _buildActionButton(
        icon: isHorizontal ? Icons.remove_rounded : Icons.add_rounded,
        tooltip: isHorizontal ? 'Diminuir fonte' : 'Aumentar fonte',
        onTap: () => _changeFontSize(isHorizontal ? -2.0 : 2.0),
      ),
      SizedBox(width: isHorizontal ? 4 : 0, height: isHorizontal ? 0 : 4),
      GestureDetector(
        onTap: () {
          if (widget.onResetFontSize != null) {
            widget.onResetFontSize!();
            _startInactivityTimer();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            '${widget.fontSize.toInt()}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      SizedBox(width: isHorizontal ? 4 : 0, height: isHorizontal ? 0 : 4),
      _buildActionButton(
        icon: isHorizontal ? Icons.add_rounded : Icons.remove_rounded,
        tooltip: isHorizontal ? 'Aumentar fonte' : 'Diminuir fonte',
        onTap: () => _changeFontSize(isHorizontal ? 2.0 : -2.0),
      ),
    ];

    if (isHorizontal) {
      return Row(key: key, mainAxisSize: MainAxisSize.min, children: children);
    }

    return Column(key: key, mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF1A365D).withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
