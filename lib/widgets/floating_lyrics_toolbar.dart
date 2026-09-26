import 'package:flutter/material.dart';
import 'floating_alignment_controls.dart';
import 'floating_font_size_controls.dart';

enum ToolbarDockLocation {
  sideLeft,
  sideRight,
  bottomLeft,
  bottomRight,
  bottomLeftVertical,
  bottomRightVertical,
}

/// Painel flutuante combinado (Alinhamento + Fonte).
/// Suporta:
/// - Orientação dinâmica (Vertical nas laterais, Horizontal no rodapé inferior).
/// - Clique e segurar (long press) com acompanhamento em tempo real do dedo.
/// - Voo animado e magnético para as bordas (laterais, cantos verticais ou rodapé inferior).
/// - Notificação de ancoragem para permitir reação e afastamento do player de áudio.
class FloatingLyricsToolbar extends StatefulWidget {
  final TextAlign textAlign;
  final ValueChanged<TextAlign> onAlignChanged;
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback? onResetFontSize;
  final double bottomOffset;
  final ValueChanged<ToolbarDockLocation>? onDockLocationChanged;

  const FloatingLyricsToolbar({
    super.key,
    required this.textAlign,
    required this.onAlignChanged,
    required this.fontSize,
    required this.onFontSizeChanged,
    this.onResetFontSize,
    this.bottomOffset = 80.0,
    this.onDockLocationChanged,
  });

  @override
  State<FloatingLyricsToolbar> createState() => _FloatingLyricsToolbarState();
}

class _FloatingLyricsToolbarState extends State<FloatingLyricsToolbar> {
  bool _isDragging = false;
  bool _hasCustomPosition = false;

  // Posição em tempo real enquanto o usuário arrasta
  Offset _dragOffset = Offset.zero;

  // Local de ancoragem
  ToolbarDockLocation _dockLocation = ToolbarDockLocation.sideRight;
  double? _anchoredTop;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isRightAligned = widget.textAlign == TextAlign.right;

    // Se ainda não ancorou manualmente, a borda lateral é baseada no alinhamento
    final bool defaultIsRight = !isRightAligned;
    final ToolbarDockLocation currentDock = _hasCustomPosition
        ? _dockLocation
        : (defaultIsRight ? ToolbarDockLocation.sideRight : ToolbarDockLocation.sideLeft);

    final bool isHorizontalDocked =
        currentDock == ToolbarDockLocation.bottomLeft ||
        currentDock == ToolbarDockLocation.bottomRight;

    final Axis axis = isHorizontalDocked ? Axis.horizontal : Axis.vertical;

    const animationDuration = Duration(milliseconds: 380);
    const animationCurve = Curves.fastOutSlowIn;

    const double toolbarVerticalHeight = 210.0;
    final double minBottomGap = widget.bottomOffset + 8.0;
    final double maxAllowedTop = (screenSize.height - minBottomGap - toolbarVerticalHeight)
        .clamp(60.0, screenSize.height);

    final double defaultTop = (screenSize.height - widget.bottomOffset - 220.0)
        .clamp(60.0, maxAllowedTop);
    final double targetTop = _hasCustomPosition && _anchoredTop != null
        ? _anchoredTop!.clamp(60.0, maxAllowedTop)
        : defaultTop;

    // Posições baseadas no tipo de ancoragem
    double? leftPos;
    double? rightPos;
    double? topPos;
    double? bottomPos;

    if (_isDragging) {
      topPos = (_dragOffset.dy - 60).clamp(40.0, screenSize.height - 120.0);
      leftPos = (_dragOffset.dx - 30).clamp(8.0, screenSize.width - 70.0);
    } else if (isHorizontalDocked) {
      bottomPos = 16.0;
      if (currentDock == ToolbarDockLocation.bottomLeft) {
        leftPos = 16.0;
      } else {
        rightPos = 16.0;
      }
    } else if (currentDock == ToolbarDockLocation.bottomLeftVertical) {
      bottomPos = 16.0;
      leftPos = 16.0;
    } else if (currentDock == ToolbarDockLocation.bottomRightVertical) {
      bottomPos = 16.0;
      rightPos = 16.0;
    } else {
      topPos = targetTop;
      if (currentDock == ToolbarDockLocation.sideRight) {
        rightPos = 16.0;
      } else {
        leftPos = 16.0;
      }
    }

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : animationDuration,
      curve: animationCurve,
      top: topPos,
      bottom: bottomPos,
      left: leftPos,
      right: rightPos,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
            _dragOffset = details.globalPosition;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _dragOffset = details.globalPosition;
          });
        },
        onPanEnd: (_) {
          _handleDragEnd(_dragOffset, screenSize);
        },
        onLongPressStart: (details) {
          setState(() {
            _isDragging = true;
            _dragOffset = details.globalPosition;
          });
        },
        onLongPressMoveUpdate: (details) {
          setState(() {
            _dragOffset = details.globalPosition;
          });
        },
        onLongPressEnd: (details) {
          _handleDragEnd(details.globalPosition, screenSize);
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _isDragging ? 1.08 : 1.0,
          child: AnimatedSize(
            duration: animationDuration,
            curve: animationCurve,
            child: isHorizontalDocked
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingAlignmentControls(
                        textAlign: widget.textAlign,
                        onAlignChanged: widget.onAlignChanged,
                        axis: axis,
                      ),
                      const SizedBox(width: 8),
                      FloatingFontSizeControls(
                        fontSize: widget.fontSize,
                        onFontSizeChanged: widget.onFontSizeChanged,
                        onResetFontSize: widget.onResetFontSize,
                        axis: axis,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingAlignmentControls(
                        textAlign: widget.textAlign,
                        onAlignChanged: widget.onAlignChanged,
                        axis: axis,
                      ),
                      const SizedBox(height: 8),
                      FloatingFontSizeControls(
                        fontSize: widget.fontSize,
                        onFontSizeChanged: widget.onFontSizeChanged,
                        onResetFontSize: widget.onResetFontSize,
                        axis: axis,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _handleDragEnd(Offset globalPosition, Size screenSize) {
    final dx = globalPosition.dx;
    final dy = globalPosition.dy;

    const double toolbarVerticalHeight = 210.0;
    final double minBottomGap = widget.bottomOffset + 8.0;
    final double maxAllowedTop = (screenSize.height - minBottomGap - toolbarVerticalHeight)
        .clamp(60.0, screenSize.height);

    final isRightSide = dx >= (screenSize.width / 2);
    final isCornerEdge = dx < 80 || dx > (screenSize.width - 80);

    // Se o usuário soltou na região inferior da tela (onde há risco de sobrepor o player)
    final isBottomRegion = dy >= (screenSize.height - 230.0);

    late ToolbarDockLocation newDock;

    if (isBottomRegion) {
      if (isCornerEdge) {
        newDock = isRightSide
            ? ToolbarDockLocation.bottomRightVertical
            : ToolbarDockLocation.bottomLeftVertical;
      } else {
        newDock = isRightSide
            ? ToolbarDockLocation.bottomRight
            : ToolbarDockLocation.bottomLeft;
      }
    } else {
      newDock = isRightSide
          ? ToolbarDockLocation.sideRight
          : ToolbarDockLocation.sideLeft;
    }

    final double calculatedTop = (dy - 60).clamp(60.0, maxAllowedTop);

    setState(() {
      _isDragging = false;
      _hasCustomPosition = true;
      _dockLocation = newDock;
      _anchoredTop = calculatedTop;
    });

    if (widget.onDockLocationChanged != null) {
      widget.onDockLocationChanged!(newDock);
    }
  }
}
