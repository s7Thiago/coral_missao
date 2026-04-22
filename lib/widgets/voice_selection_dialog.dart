import 'package:flutter/material.dart';
import '../models/repertorio_model.dart';
import '../utils/app_colors.dart';
import '../services/audio_service.dart';
import '../utils/screen_utils.dart';

class VoiceSelectionDialog extends StatefulWidget {
  final RepertorioItem item;

  const VoiceSelectionDialog({super.key, required this.item});

  @override
  State<VoiceSelectionDialog> createState() => _VoiceSelectionDialogState();
}

class _VoiceSelectionDialogState extends State<VoiceSelectionDialog> {
  final AudioService _audioService = AudioService();

  Future<void> _handleVoiceTap(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link indisponível para este naipe.')),
      );
      return;
    }

    try {
      // Verifica se já está baixado
      final bool isCached = await _audioService.estaBaixado(url);

      if (!isCached) {
        // Se não estiver, avisa (opcional) e baixa
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Baixando áudio para reprodução offline...'),
            duration: Duration(seconds: 1),
          ),
        );
        await _audioService.baixarParaOffline(url);
      }

      // Reproduz (agora garantido que está no cache ou tenta buscar de lá)
      await _audioService.tocarAudio(url);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao processar áudio: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    double width;
    if (context.isDesktop) {
      width = 400;
    } else if (context.isTablet) {
      width = MediaQuery.of(context).size.width * 0.5;
    } else {
      width = MediaQuery.of(context).size.width * 0.85;
    }

    return Center(
      child: Hero(
        tag: widget.item.id,
        child: Material(
          type: MaterialType.transparency,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: width,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.titulo,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Selecione um naipe para ouvir/baixar:',
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: widget.item.vozes
                        .map((voz) => _buildVoiceItem(context, voz))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceItem(BuildContext context, Voz voz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFF5F8FA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE1E8ED)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: _buildVoiceIcon(voz.naipe),
          title: Text(
            voz.naipe,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF2C3E50),
            ),
          ),
          trailing: const Icon(
            Icons.play_circle_fill_rounded, // Changed to Play icon
            size: 32, // Increased size for better touch target
            color: Color(0xFF5E819D), // Matches theme
          ),
          onTap: () => _handleVoiceTap(context, voz.link),
        ),
      ),
    );
  }

  Widget _buildVoiceIcon(String naipe) {
    final color = AppColors.getVoiceColor(naipe);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.mic_rounded, color: color, size: 20),
    );
  }
}
