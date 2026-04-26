import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repertorio_model.dart';
import '../services/audio_service.dart';
import '../views/music_player_view.dart';
import 'mini_player.dart';

class PlayerOverlay extends StatefulWidget {
  final RepertorioItem item;

  const PlayerOverlay({super.key, required this.item});

  @override
  State<PlayerOverlay> createState() => _PlayerOverlayState();
}

class _PlayerOverlayState extends State<PlayerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    if (_controller.isDismissed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _handleVerticalUpdate(DragUpdateDetails details) {
    // screenHeight might be slightly different if we don't have it, but we can use context.size
    final height = MediaQuery.of(context).size.height;
    _controller.value -= details.primaryDelta! / height;
  }

  void _handleVerticalEnd(DragEndDetails details) {
    if (_controller.isDismissed || _controller.isCompleted) return;

    if (details.primaryVelocity! < -300) {
      // Fling up
      _controller.forward();
    } else if (details.primaryVelocity! > 300) {
      // Fling down
      _controller.reverse();
    } else if (_controller.value > 0.5) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final currentVoz = audioService.currentVoz;

    if (currentVoz == null) return const SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;

        // Minimized layout parameters
        const double pillHeight = 64.0;
        const double pillBottomMargin = 96.0; // Above NavigationBar
        const double pillSideMargin = 160.0;

        final double currentHeight = lerpDouble(
          pillHeight,
          screenHeight,
          progress,
        )!;
        final double currentBottom = lerpDouble(pillBottomMargin, 0, progress)!;
        final double currentSide = lerpDouble(pillSideMargin, 0, progress)!;
        final double currentRadius = lerpDouble(32, 0, progress)!;

        return Positioned(
          bottom: currentBottom,
          left: currentSide,
          right: currentSide,
          height: currentHeight,
          child: GestureDetector(
            onVerticalDragUpdate: _handleVerticalUpdate,
            onVerticalDragEnd: _handleVerticalEnd,
            child: Material(
              color: Colors.transparent,
              elevation: lerpDouble(8, 0, progress)!,
              borderRadius: BorderRadius.circular(currentRadius),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  // Background color fades from the pill's color to the full player's color
                  color: Color.lerp(
                    const Color(0xFF1B3B5A),
                    const Color(0xFFF5F9FA),
                    progress,
                  ),
                ),
                child: OverflowBox(
                  maxHeight: screenHeight,
                  maxWidth: screenWidth,
                  alignment: Alignment.bottomCenter,
                  child: Stack(
                    children: [
                      // Full Screen Player View
                      if (progress > 0)
                        Opacity(
                          opacity: progress,
                          child: IgnorePointer(
                            ignoring: progress < 1.0,
                            child: SizedBox(
                              height: screenHeight,
                              width: screenWidth,
                              child: MusicPlayerView(item: widget.item),
                            ),
                          ),
                        ),

                      // Mini Pill Player View
                      if (progress < 1)
                        Opacity(
                          opacity: 1.0 - progress,
                          child: IgnorePointer(
                            ignoring: progress > 0.0,
                            child: SizedBox(
                              height: pillHeight,
                              width: screenWidth - (pillSideMargin * 2),
                              child: Align(
                                alignment: Alignment.center,
                                child: MiniPlayer(
                                  item: widget.item,
                                  onTap: _toggleExpand,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
