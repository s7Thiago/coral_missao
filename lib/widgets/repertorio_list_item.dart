import 'package:flutter/material.dart';
import '../models/repertorio_model.dart';
import '../utils/ui_utils.dart';
import '../utils/app_colors.dart';
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
    return Hero(
      tag: item.id,
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
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              customLauncher(
                context: context,
                target: VoiceSelectionDialog(item: item),
                opaque: false, // Ensure transparency for the overlay effect
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
                        Text(
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
                        const SizedBox(height: 8),
                        // Pass 'item' to _buildBadge to access the full Voz object if needed,
                        // but here we are mapping from item.vozes which provides Voz objects.
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: item.vozes
                              .map((voz) => _buildBadge(voz))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Action Button & Size
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(),
                      if (!isDownloaded && item.tamanho.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.tamanho,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDownloaded ? onPlayPressed : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: isDownloaded
                ? const Color(0xFF0D496F) // Dark blue for Play
                : const Color(0xFFD8E4ED), // Light blue for Download
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isDownloaded ? Icons.play_arrow_rounded : Icons.download_rounded,
            color: isDownloaded
                ? Colors.white
                : const Color(0xFF0D496F), // Dark blue icon for download
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(Voz voz) {
    final String voice = voz.naipe;
    final color = AppColors.getVoiceColor(voice);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        voice,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
