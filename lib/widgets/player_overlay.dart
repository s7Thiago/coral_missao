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

class _PlayerOverlayState extends State<PlayerOverlay> {
  final DraggableScrollableController _controller = DraggableScrollableController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_controller.isAttached) {
      final size = _controller.size;
      // If expanded more than 40% of the screen, we consider it expanded
      if (size > 0.4 && !_isExpanded) {
        setState(() => _isExpanded = true);
      } else if (size <= 0.4 && _isExpanded) {
        setState(() => _isExpanded = false);
      }
    }
  }

  void _toggleExpand() {
    if (_controller.isAttached) {
      if (_isExpanded) {
        _controller.animateTo(
          0.12, // Approximate min size
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _controller.animateTo(
          1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final currentVoz = audioService.currentVoz;

    if (currentVoz == null) return const SizedBox.shrink();

    // Calculate min size based on screen height
    final screenHeight = MediaQuery.of(context).size.height;
    // MiniPlayer is 72 height + 16 margins = 88. Let's add a bit for safety.
    final minSize = 90 / screenHeight;

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: minSize,
      minChildSize: minSize,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: [minSize, 1.0],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _isExpanded ? const Color(0xFFF5F9FA) : Colors.transparent,
            borderRadius: _isExpanded 
              ? const BorderRadius.vertical(top: Radius.circular(24)) 
              : null,
            boxShadow: _isExpanded 
              ? [const BoxShadow(color: Colors.black26, blurRadius: 10)] 
              : null,
          ),
          child: Stack(
            children: [
              // We use SingleChildScrollView to make it scrollable as required by DraggableScrollableSheet
              SingleChildScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  height: screenHeight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isExpanded ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !_isExpanded,
                      child: MusicPlayerView(item: widget.item),
                    ),
                  ),
                ),
              ),
              
              // Mini Player sits on top and fades out when expanding
              if (!_isExpanded)
                 AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isExpanded ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: _isExpanded,
                    child: MiniPlayer(
                      item: widget.item,
                      onTap: _toggleExpand,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
