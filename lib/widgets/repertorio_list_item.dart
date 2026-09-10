import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/repertorio_model.dart';
import '../services/audio_service.dart';
import '../utils/app_colors.dart';
import '../utils/ui_utils.dart';
import '../views/lyrics_view.dart';
import 'download_indicator.dart';
import 'voice_selection_dialog.dart';

class RepertorioListItem extends StatelessWidget {
  final RepertorioItem item;
  final bool isDownloaded;
  final VoidCallback? onPressed;
  final VoidCallback? onPlayPressed;

  const RepertorioListItem({
    super.key,
    required this.item,
    this.isDownloaded = false,
    this.onPressed,
    this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // tag: item.id,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8), // Light blue-grey background
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  // final rect = getWidgetGlobalRect(context);

                  // if (rect != null) {
                  //   customLauncherHero(
                  //     context: context,
                  //     target: VoiceSelectionDialog(item: item),
                  //     originRect: rect,
                  //   );
                  // }
                  customLauncher(
                    context: context,
                    target: VoiceSelectionDialog(item: item),
                    opaque: false,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(
                    16,
                  ), // Increased padding for clearer layout
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // Center vertically
                    children: [
                      // Icon
                      Container(
                        height: 50,
                        width: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5E819D), // Muted blue
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Texts and Badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // Wrap content height
                          children: [
                            Hero(
                              tag: 'titulo_${item.titulo}_${item.id}',
                              child: Material(
                                type: MaterialType.transparency,
                                child: Text(
                                  item.titulo,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Pass 'item' to _buildBadge to access the full Voz object if needed,
                            // but currently _buildBadge only needs the string naipe.
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: item.vozes
                                  .map((voz) => _buildBadge(context, voz))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Action Button & Size
                      _buildActionButton(context),
                    ],
                  ),
                ),
              ),
              // Indicador de download — aparece abaixo quando este item está sendo baixado
              Builder(
                builder: (context) {
                  final audioService = context.watch<AudioService>();
                  final downloadingVoz = item.vozes.cast<Voz?>().firstWhere(
                    (v) => v?.link == audioService.downloadUrl,
                    orElse: () => null,
                  );
                  if (!audioService.isDownloading || downloadingVoz == null) {
                    return const SizedBox.shrink();
                  }
                  return DownloadIndicator(currentVoz: downloadingVoz);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (!item.temLetra) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          customLauncher(
            context: context,
            target: LyricsView(item: item),
            opaque: false,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFD8E4ED),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.article_outlined,
            color: Color(0xFF0D496F),
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, Voz voz) {
    final String voice = voz.naipe;
    final color = AppColors.getVoiceColor(voice);

    final audioService = context.watch<AudioService>();
    final isCurrentVoice = audioService.currentVoz?.link == voz.link;

    return Hero(
      tag: 'badge_${voz.link}_${voz.naipe}',
      child: FittedBox(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrentVoice ? const Color(0xFF16476B) : color,
            borderRadius: BorderRadius.circular(20),
            border: isCurrentVoice
                ? Border.all(color: Colors.white, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...buildAudioVisualizer(context, voz),
              Text(
                voice,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
