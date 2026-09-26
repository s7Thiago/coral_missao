import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repertorio_model.dart';
import '../services/audio_service.dart';
import 'floating_lyrics_toolbar.dart';
import 'subtle_player_controls.dart';

enum PlayerAnchorType {
  bottomCenter,
  left,
  right,
  top,
  bottom,
}

/// Envolto interativo para o SubtlePlayerControls que adiciona:
/// - Arraste via clique e segurar (long press) quando no estado PARADO (FAB).
/// - Desabilita reposicionamento durante a reprodução de música, acoplando automaticamente ao rodapé.
/// - Afastamento dinâmico automático com espaçamento perfeito em relação aos controles de texto.
/// - Suporte a acoplamento lateral e vertical em cantos inferiores.
/// - Ancoragem magnética especial para o Centro Inferior da tela.
class DraggableSubtlePlayerControls extends StatefulWidget {
  final RepertorioItem item;
  final ToolbarDockLocation? toolbarDockLocation;

  const DraggableSubtlePlayerControls({
    super.key,
    required this.item,
    this.toolbarDockLocation,
  });

  @override
  State<DraggableSubtlePlayerControls> createState() =>
      _DraggableSubtlePlayerControlsState();
}

class _DraggableSubtlePlayerControlsState
    extends State<DraggableSubtlePlayerControls> {
  bool _isDragging = false;
  bool _hasCustomDragAnchor = false;
  PlayerAnchorType _anchor = PlayerAnchorType.bottomCenter;

  // Posição em tempo real enquanto o usuário arrasta
  Offset _dragOffset = Offset.zero;

  // Posições ancoradas
  double _anchoredX = 0;
  double _anchoredY = 0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const animationDuration = Duration(milliseconds: 380);
    const animationCurve = Curves.fastOutSlowIn;

    final audioService = context.watch<AudioService>();
    final isItemActive = audioService.currentItem?.id == widget.item.id;
    final isPlaying = isItemActive && audioService.isPlaying;
    final position = isItemActive ? audioService.position : Duration.zero;
    final isMusicActive = isItemActive && (isPlaying || position > Duration.zero);

    // Se o player não estiver ativo, assume o estado FAB
    final isStopped = !isMusicActive;

    // Se a música começou a tocar, reseta automaticamente qualquer ancoragem customizada
    // para que o player volte e se acople ao rodapé
    if (!isStopped && _hasCustomDragAnchor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasCustomDragAnchor = false;
            _anchor = PlayerAnchorType.bottomCenter;
          });
        }
      });
    }

    if (_isDragging && isStopped) {
      return Positioned(
        top: (_dragOffset.dy - 30).clamp(40.0, screenSize.height - 80.0),
        left: (_dragOffset.dx - 140).clamp(8.0, screenSize.width - 60.0),
        child: GestureDetector(
          onLongPressMoveUpdate: (details) {
            setState(() {
              _dragOffset = details.globalPosition;
            });
          },
          onLongPressEnd: (details) => _handleDragEnd(details, screenSize),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: 1.05,
            child: SubtlePlayerControls(item: widget.item),
          ),
        ),
      );
    }

    Widget childWidget = GestureDetector(
      // O arraste só é permitido quando a música estiver PARADA (FAB)
      onLongPressStart: isStopped
          ? (details) {
              setState(() {
                _isDragging = true;
                _dragOffset = details.globalPosition;
              });
            }
          : null,
      child: SubtlePlayerControls(item: widget.item),
    );

    // Quando está PARADO (FAB), o player fica 100% centralizado no rodapé
    if (isStopped && !_hasCustomDragAnchor) {
      return AnimatedPositioned(
        duration: animationDuration,
        curve: animationCurve,
        bottom: 8,
        left: 0,
        right: 0,
        child: childWidget,
      );
    }

    // Se o player está ATIVO e o usuário não definiu um arraste manual customizado,
    // a barra do player reage e se alinha do lado oposto ao painel no rodapé com espaçamento perfeito
    if (!_hasCustomDragAnchor && !isStopped) {
      final dock = widget.toolbarDockLocation;
      if (dock == ToolbarDockLocation.bottomLeft ||
          dock == ToolbarDockLocation.bottomLeftVertical) {
        final double leftMargin =
            dock == ToolbarDockLocation.bottomLeftVertical ? 76.0 : 190.0;
        return AnimatedPositioned(
          duration: animationDuration,
          curve: animationCurve,
          bottom: 8,
          right: 8,
          left: leftMargin,
          child: childWidget,
        );
      } else if (dock == ToolbarDockLocation.bottomRight ||
          dock == ToolbarDockLocation.bottomRightVertical) {
        final double rightMargin =
            dock == ToolbarDockLocation.bottomRightVertical ? 76.0 : 190.0;
        return AnimatedPositioned(
          duration: animationDuration,
          curve: animationCurve,
          bottom: 8,
          left: 8,
          right: rightMargin,
          child: childWidget,
        );
      } else {
        return AnimatedPositioned(
          duration: animationDuration,
          curve: animationCurve,
          bottom: 8,
          left: 8,
          right: 8,
          child: childWidget,
        );
      }
    }

    switch (_anchor) {
      case PlayerAnchorType.bottomCenter:
        return AnimatedPositioned(
          duration: animationDuration,
          curve: animationCurve,
          bottom: 8,
          left: 8,
          right: 8,
          child: childWidget,
        );

      case PlayerAnchorType.left:
        return AnimatedPositioned(
          duration: animationDuration,
          curve: animationCurve,
          top: _anchoredY.clamp(60.0, screenSize.height - 120.0),
          left: 8,
          child: SizedBox(
            width: (screenSize.width * 0.85).clamp(240.0, 360.0),
            child: childWidget,
          ),
        );

      case PlayerAnchorType.right:
        return AnimatedPositioned(
          duration: animationDuration,
          curve: animationCurve,
          top: _anchoredY.clamp(60.0, screenSize.height - 120.0),
          right: 8,
          child: SizedBox(
            width: (screenSize.width * 0.85).clamp(240.0, 360.0),
            child: childWidget,
          ),
        );

      case PlayerAnchorType.top:
        return AnimatedPositioned(
          duration: animationDuration,
          curve: animationCurve,
          top: 60,
          left: _anchoredX.clamp(16.0, screenSize.width - 300.0),
          right: null,
          child: SizedBox(
            width: (screenSize.width * 0.9).clamp(260.0, 380.0),
            child: childWidget,
          ),
        );

      case PlayerAnchorType.bottom:
        return AnimatedPositioned(
          duration: animationDuration,
          curve: animationCurve,
          bottom: 16,
          left: _anchoredX.clamp(16.0, screenSize.width - 300.0),
          right: null,
          child: SizedBox(
            width: (screenSize.width * 0.9).clamp(260.0, 380.0),
            child: childWidget,
          ),
        );
    }
  }

  void _handleDragEnd(LongPressEndDetails details, Size screenSize) {
    final dx = details.globalPosition.dx;
    final dy = details.globalPosition.dy;

    // Ponto alvo do centro inferior
    final bottomCenterTarget = Offset(screenSize.width / 2, screenSize.height - 40);
    final distToBottomCenter = (dx - bottomCenterTarget.dx).abs() +
        (dy - bottomCenterTarget.dy).abs();

    // Se estiver próximo do centro inferior (imã do centro inferior)
    if (distToBottomCenter < 140) {
      setState(() {
        _isDragging = false;
        _hasCustomDragAnchor = false;
        _anchor = PlayerAnchorType.bottomCenter;
      });
      return;
    }

    // Distâncias até as 4 bordas
    final distLeft = dx;
    final distRight = screenSize.width - dx;
    final distTop = dy;
    final distBottom = screenSize.height - dy;

    final minDist = [distLeft, distRight, distTop, distBottom]
        .reduce((a, b) => a < b ? a : b);

    setState(() {
      _isDragging = false;
      _hasCustomDragAnchor = true;

      if (minDist == distLeft) {
        _anchor = PlayerAnchorType.left;
        _anchoredY = dy - 30;
      } else if (minDist == distRight) {
        _anchor = PlayerAnchorType.right;
        _anchoredY = dy - 30;
      } else if (minDist == distTop) {
        _anchor = PlayerAnchorType.top;
        _anchoredX = dx - 140;
      } else {
        _anchor = PlayerAnchorType.bottom;
        _anchoredX = dx - 140;
      }
    });
  }
}
