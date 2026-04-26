import 'package:flutter/material.dart';
import 'dart:math' as math;

class AudioVisualizer extends StatefulWidget {
  final Color color;
  final bool isPlaying;
  final double size;

  const AudioVisualizer({
    super.key,
    required this.color,
    required this.isPlaying,
    this.size = 20.0,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
      _controller.animateTo(0.1, duration: const Duration(milliseconds: 300)); // Animate to a calm state
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double heightOffset = 0.0;
              if (widget.isPlaying) {
                // Each bar uses a different sine wave offset to look random
                double time = _controller.value * 2 * math.pi;
                double phase = index * (math.pi / 2);
                heightOffset = (math.sin(time + phase) + 1) / 2;
              } else {
                heightOffset = 0.2; // Static size when paused
              }

              return Container(
                width: widget.size / 6,
                height: math.max(widget.size * 0.2, widget.size * heightOffset),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.size / 12),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
