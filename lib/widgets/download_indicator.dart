import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../models/repertorio_model.dart';

class DownloadIndicator extends StatelessWidget {
  final Voz? currentVoz;

  const DownloadIndicator({super.key, required this.currentVoz});

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();

    if (!audioService.isDownloading || audioService.downloadUrl != currentVoz?.link) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Salvando áudio para uso offline...",
            style: TextStyle(
              color: Color(0xFF16476B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: audioService.downloadProgress > 0 ? audioService.downloadProgress : null,
              minHeight: 8,
              backgroundColor: const Color(0xFFD3E4F2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16476B)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${(audioService.downloadProgress * 100).toInt()}% concluído",
            style: const TextStyle(
              color: Color(0xFF5A7894),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
