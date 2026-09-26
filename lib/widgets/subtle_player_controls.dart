import 'dart:async';
import 'package:coral_missao/widgets/download_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repertorio_model.dart';
import '../services/audio_service.dart';
import '../utils/app_colors.dart';
import '../widgets/audio_visualizer.dart';

/// Controles sutis de player de áudio com 3 estados morficados e animados:
/// 1. PARADO (FAB): Transforma-se suavemente em formato de Floating Action Button circular quando a música está parada.
/// 2. MINIMIZADO: Barra sutil horizontal com progresso e controles básicos.
/// 3. EXPANDIDO: Barra completa com controle de velocidade, slider de busca e seletor de naipes.
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
  bool _isMinimized = true;
  Timer? _inactivityTimer;

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audioService = context.watch<AudioService>();
    if (audioService.shouldExpandPlayer) {
      audioService.shouldExpandPlayer = false;
      if (_isMinimized) {
        _isMinimized = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<AudioService>().setPlayerExpanded(true);
            _resetInactivityTimer();
          }
        });
      }
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_isMinimized) {
      setState(() {
        _isMinimized = false;
      });
      context.read<AudioService>().setPlayerExpanded(true);
    }
    _inactivityTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isMinimized = true;
        });
        context.read<AudioService>().setPlayerExpanded(false);
      }
    });
  }

  void _toggleMinimize() {
    final newMinimized = !_isMinimized;
    setState(() {
      _isMinimized = newMinimized;
    });
    context.read<AudioService>().setPlayerExpanded(!newMinimized);
    if (!newMinimized) {
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
    final isMusicActive = isItemActive && (isPlaying || position > Duration.zero);
    final isMusicPlaying = isItemActive && duration > Duration.zero;
    final hasNaipes = widget.item.vozes.isNotEmpty;

    // Se o player não estiver ativo nem pausado (ou seja, está PARADO), assume o estado FAB
    final isStopped = !isMusicActive;

    const animationDuration = Duration(milliseconds: 380);
    const animationCurve = Curves.fastOutSlowIn;

    final double progressPercent =
        (isMusicPlaying && duration.inMilliseconds > 0)
            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

    Widget playerBody = Listener(
      onPointerDown: (_) {
        if (!isStopped) _resetInactivityTimer();
      },
      child: GestureDetector(
        onTap: () {
          if (isStopped) {
            setState(() {
              _isMinimized = false;
            });
            _resetInactivityTimer();
            if (widget.item.vozes.isNotEmpty) {
              audioService.playVoz(widget.item.vozes.first, widget.item);
            }
          } else if (_isMinimized) {
            _toggleMinimize();
          } else {
            _resetInactivityTimer();
          }
        },
        child: AnimatedContainer(
          duration: animationDuration,
          curve: animationCurve,
          margin: isStopped
              ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)
              : EdgeInsets.zero,
          padding: EdgeInsets.symmetric(
            horizontal: isStopped ? 0.0 : 12.0,
            vertical: isStopped
                ? 0.0
                : (_isMinimized ? 6.0 : 10.0),
          ),
          width: isStopped ? 54.0 : double.infinity,
          height: isStopped ? 54.0 : null,
          decoration: BoxDecoration(
            color: const Color(0xFF13324D).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(
              isStopped ? 27.0 : (_isMinimized ? 30.0 : 24.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isStopped ? 0.3 : 0.2),
                blurRadius: isStopped ? 12 : (_isMinimized ? 8 : 14),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: animationCurve,
              switchOutCurve: animationCurve,
              child: isStopped
                  ? _buildStoppedFabContent(key: const ValueKey('stopped_fab'))
                  : _buildActivePlayerContent(
                      key: const ValueKey('active_player'),
                      audioService: audioService,
                      currentVoz: currentVoz,
                      isItemActive: isItemActive,
                      isPlaying: isPlaying,
                      position: position,
                      duration: duration,
                      isMusicPlaying: isMusicPlaying,
                      hasNaipes: hasNaipes,
                      progressPercent: progressPercent,
                      animationDuration: animationDuration,
                      animationCurve: animationCurve,
                    ),
            ),
          ),
        ),
      );

    return isStopped ? Center(child: playerBody) : playerBody;
  }

  /// Conteúdo interno quando o player está no estado PARADO (FAB circular com Play)
  Widget _buildStoppedFabContent({required Key key}) {
    return Container(
      key: key,
      width: 54,
      height: 54,
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  /// Conteúdo interno quando o player está ATIVO (Barra Minimizada ou Expandida)
  Widget _buildActivePlayerContent({
    required Key key,
    required AudioService audioService,
    required Voz? currentVoz,
    required bool isItemActive,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    required bool isMusicPlaying,
    required bool hasNaipes,
    required double progressPercent,
    required Duration animationDuration,
    required Curve animationCurve,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        DownloadIndicator(currentVoz: currentVoz),

        // 1. Full Progress Slider (Visível apenas quando EXPANDIDO)
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
                      const SizedBox(height: 6),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // 2. Linha Principal de Controles
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Botão de Velocidade
            _buildSpeedButton(audioService, isItemActive),

            const SizedBox(width: 6),

            // Botão Play / Pause
            _buildPlayPauseButton(
              audioService,
              isItemActive,
              isPlaying,
              size: _isMinimized ? 28 : 34,
            ),

            const SizedBox(width: 6),

            // Seção Central com FittedBox para impedir overflow em telas menores
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

            const SizedBox(width: 6),

            // Botão de PARAR (Stop)
            _buildStopButton(audioService, isItemActive),

            // Ícone de Expandir (Visível apenas quando MINIMIZADO)
            AnimatedSize(
              duration: animationDuration,
              curve: animationCurve,
              child: AnimatedOpacity(
                duration: animationDuration,
                curve: animationCurve,
                opacity: _isMinimized ? 1.0 : 0.0,
                child: _isMinimized
                    ? Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: IconButton(
                          onPressed: _toggleMinimize,
                          icon: const Icon(
                            Icons.unfold_more_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),

        // 3. Seletor de Naipes (Visível apenas quando EXPANDIDO)
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
    );
  }

  // --- Widgets Auxiliares ---
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
          horizontal: 8,
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
            fontSize: 11,
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
    double size = 32,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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

  /// Botão de Parar (Stop) - Para a reprodução e reseta o áudio
  Widget _buildStopButton(AudioService audioService, bool isItemActive) {
    return IconButton(
      onPressed: isItemActive
          ? () async {
              setState(() {
                _isMinimized = true;
              });
              await audioService.stop();
            }
          : null,
      iconSize: 20,
      color: Colors.white,
      icon: const Icon(Icons.stop_rounded),
    );
  }
}
