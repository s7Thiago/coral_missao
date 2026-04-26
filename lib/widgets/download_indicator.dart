import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../models/repertorio_model.dart';

enum DownloadIndicatorTheme { light, dark }

class DownloadIndicator extends StatelessWidget {
  final Voz? currentVoz;

  /// [dark] → fundo claro (VoiceSelectionDialog, RepertorioListItem)
  /// [light] → fundo escuro (MiniPlayer)
  final DownloadIndicatorTheme theme;

  const DownloadIndicator({
    super.key,
    required this.currentVoz,
    this.theme = DownloadIndicatorTheme.dark,
  });

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();

    if (!audioService.isDownloading ||
        audioService.downloadUrl != currentVoz?.link) {
      return const SizedBox.shrink();
    }

    final bool isDark = theme == DownloadIndicatorTheme.dark;

    final Color textColor =
        isDark ? const Color(0xFF16476B) : Colors.white.withValues(alpha: 0.9);
    final Color subTextColor =
        isDark ? const Color(0xFF5A7894) : Colors.white.withValues(alpha: 0.6);
    final Color barBg =
        isDark ? const Color(0xFFD3E4F2) : Colors.white.withValues(alpha: 0.25);
    final Color barFill = isDark ? const Color(0xFF16476B) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Salvando áudio para uso offline...',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: audioService.downloadProgress > 0
                  ? audioService.downloadProgress
                  : null,
              minHeight: 6,
              backgroundColor: barBg,
              valueColor: AlwaysStoppedAnimation<Color>(barFill),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(audioService.downloadProgress * 100).toInt()}% concluído',
            style: TextStyle(color: subTextColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
