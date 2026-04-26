import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repertorio_model.dart';
import '../services/audio_service.dart';
import '../utils/app_colors.dart';
import 'download_indicator.dart';

class MiniPlayer extends StatelessWidget {
  final RepertorioItem item;
  final VoidCallback onTap;

  const MiniPlayer({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final currentVoz = audioService.currentVoz;
    final isPlaying = audioService.isPlaying;

    if (currentVoz == null) return const SizedBox.shrink();

    final color = AppColors.getVoiceColor(currentVoz.naipe);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3B5A),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Voice Badge
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Naipe
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentVoz.naipe,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Play/Pause Button
                  IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: audioService.togglePlayPause,
                  ),
                  // Close Button
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: audioService.stopAndClear,
                  ),
                ],
              ),
            ),
            // Indicador de download sutil abaixo da pílula
            if (audioService.isDownloading &&
                audioService.downloadUrl == currentVoz.link)
              DownloadIndicator(
                currentVoz: currentVoz,
                theme: DownloadIndicatorTheme.light,
              ),
          ],
        ),
      ),
    );
  }
}
