import 'dart:async';
import 'package:coral_missao/widgets/download_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repertorio_model.dart';
import '../services/audio_service.dart';
import '../utils/app_colors.dart';
import '../widgets/audio_visualizer.dart';

class SubtlePlayerControls extends StatefulWidget {
  final RepertorioItem item;

  const SubtlePlayerControls({
    super.key,
    required this.item,
  });

  @override
  State<SubtlePlayerControls> createState() => _SubtlePlayerControlsState();
}

class _SubtlePlayerControlsState extends State<SubtlePlayerControls> {
  bool _isMinimized = false;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_isMinimized) {
      setState(() {
        _isMinimized = false;
      });
    }
    _inactivityTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isMinimized = true;
        });
      }
    });
  }

  void _toggleMinimize() {
    setState(() {
      _isMinimized = !_isMinimized;
    });
    if (!_isMinimized) {
      _resetInactivityTimer();
    } else {
      _inactivityTimer?.cancel();
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final currentVoz = audioService.currentVoz;
    final isItemActive = audioService.currentItem?.id == widget.item.id;
    final isPlaying = isItemActive && audioService.isPlaying;
    final position = isItemActive ? audioService.position : Duration.zero;
    final duration = isItemActive ? audioService.duration : Duration.zero;
    final isMusicPlaying = isItemActive && duration > Duration.zero;
    final hasNaipes = widget.item.vozes.isNotEmpty;

    final double progressPercent = (isMusicPlaying && duration.inMilliseconds > 0)
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    const animationDuration = Duration(milliseconds: 400);
    const animationCurve = Curves.fastOutSlowIn;

    return Listener(
      onPointerDown: (_) => _resetInactivityTimer(),
      child: GestureDetector(
        onTap: () {
          if (_isMinimized) {
            _toggleMinimize();
          } else {
            _resetInactivityTimer();
          }
        },
        child: AnimatedContainer(
          duration: animationDuration,
          curve: animationCurve,
          margin: const EdgeInsets.all(12.0),
          padding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: _isMinimized ? 8.0 : 12.0,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF13324D).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(_isMinimized ? 30 : 24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: _isMinimized ? 8 : 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DownloadIndicator(currentVoz: currentVoz),

              // 1. Full Progress Slider (Visible only when EXPANDED)
              AnimatedSize(
                duration: animationDuration,
                curve: animationCurve,
                child: AnimatedOpacity(
                  duration: animationDuration,
                  curve: animationCurve,
                  opacity: (!_isMinimized && isMusicPlaying) ? 1.0 : 0.0,
                  child: (!_isMinimized && isMusicPlaying)
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildProgressBar(audioService, position, duration),
                            const SizedBox(height: 8),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // 2. Persistent Controls Row (Hero / Shared Elements Movement)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Speed Button (Persistent)
                  _buildSpeedButton(audioService, isItemActive),

                  const SizedBox(width: 8),

                  // Play / Pause Button (Persistent with smooth size scaling)
                  _buildPlayPauseButton(
                    audioService,
                    isItemActive,
                    isPlaying,
                    size: _isMinimized ? 30 : 36,
                  ),

                  const SizedBox(width: 8),

                  // Middle Section: Minimized Progress Info OR Flexible Spacer
                  Expanded(
                    child: AnimatedSize(
                      duration: animationDuration,
                      curve: animationCurve,
                      child: AnimatedOpacity(
                        duration: animationDuration,
                        curve: animationCurve,
                        opacity: _isMinimized ? 1.0 : 0.0,
                        child: _isMinimized
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          currentVoz?.naipe ?? widget.item.titulo,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isMusicPlaying) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: progressPercent,
                                      minHeight: 3,
                                      backgroundColor: Colors.white24,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Replay Button (Persistent)
                  _buildReplayButton(audioService, isItemActive),

                  // Unfold / Expand Icon (Visible only when MINIMIZED)
                  AnimatedSize(
                    duration: animationDuration,
                    curve: animationCurve,
                    child: AnimatedOpacity(
                      duration: animationDuration,
                      curve: animationCurve,
                      opacity: _isMinimized ? 1.0 : 0.0,
                      child: _isMinimized
                          ? Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: IconButton(
                                onPressed: _toggleMinimize,
                                icon: const Icon(
                                  Icons.unfold_more_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Expandir controles',
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),

              // 3. Naipe Selector (Visible only when EXPANDED)
              AnimatedSize(
                duration: animationDuration,
                curve: animationCurve,
                child: AnimatedOpacity(
                  duration: animationDuration,
                  curve: animationCurve,
                  opacity: (!_isMinimized && hasNaipes) ? 1.0 : 0.0,
                  child: (!_isMinimized && hasNaipes)
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10),
                            _buildNaipeSelector(
                              context,
                              audioService,
                              isItemActive,
                              currentVoz,
                              isPlaying,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildNaipeSelector(
    BuildContext context,
    AudioService audioService,
    bool isItemActive,
    Voz? currentVoz,
    bool isPlaying,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.item.vozes.map((voz) {
          final isSelected = isItemActive && currentVoz?.link == voz.link;
          final voiceColor = AppColors.getVoiceColor(voz.naipe);

          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: InkWell(
              onTap: () {
                audioService.playVoz(
                  voz,
                  widget.item,
                  keepPosition: isItemActive,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutQuad,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF388E3C)
                      : voiceColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 1.5)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected && isPlaying) ...[
                      AudioVisualizer(
                        color: Colors.white,
                        isPlaying: true,
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      voz.naipe,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressBar(
    AudioService audioService,
    Duration position,
    Duration duration,
  ) {
    return Row(
      children: [
        Text(
          _formatDuration(position),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 5,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 10,
              ),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white30,
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: position.inMilliseconds.toDouble().clamp(
                0,
                duration.inMilliseconds.toDouble() > 0
                    ? duration.inMilliseconds.toDouble()
                    : 0,
              ),
              min: 0,
              max: duration.inMilliseconds.toDouble() > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1.0,
              onChanged: (value) {
                audioService.seek(
                  Duration(milliseconds: value.toInt()),
                );
              },
            ),
          ),
        ),
        Text(
          _formatDuration(duration),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedButton(AudioService audioService, bool isItemActive) {
    return InkWell(
      onTap: isItemActive ? audioService.changeSpeed : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isItemActive ? '${audioService.playbackSpeed}x' : '1.0x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(
    AudioService audioService,
    bool isItemActive,
    bool isPlaying, {
    double size = 36,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      child: IconButton(
        onPressed: () {
          if (isItemActive) {
            audioService.togglePlayPause();
          } else if (widget.item.vozes.isNotEmpty) {
            audioService.playVoz(widget.item.vozes.first, widget.item);
          }
        },
        iconSize: size,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: Colors.white,
        icon: Icon(
          isPlaying
              ? Icons.pause_circle_filled_rounded
              : Icons.play_circle_fill_rounded,
        ),
      ),
    );
  }

  Widget _buildReplayButton(AudioService audioService, bool isItemActive) {
    return IconButton(
      onPressed: isItemActive
          ? () => audioService.seek(Duration.zero)
          : () => {},
      iconSize: 22,
      color: Colors.white,
      icon: const Icon(Icons.replay_rounded),
    );
  }
}
