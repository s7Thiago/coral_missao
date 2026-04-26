import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repertorio_model.dart';
import '../services/audio_service.dart';
import '../widgets/download_indicator.dart';

class MusicPlayerView extends StatelessWidget {
  final RepertorioItem item;

  const MusicPlayerView({super.key, required this.item});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final position = audioService.position;
    final duration = audioService.duration;
    final isPlaying = audioService.isPlaying;
    final playbackSpeed = audioService.playbackSpeed;
    final currentVoz = audioService.currentVoz;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Header
            Text(
              'Reproduzindo: ${item.titulo.toUpperCase()}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1B3B5A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Album Art placeholder
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF8BA9C5),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 140,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            DownloadIndicator(currentVoz: currentVoz),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: const Color(0xFF16476B),
                      inactiveTrackColor: const Color(0xFFD4E4F1),
                      thumbColor: const Color(0xFF16476B),
                      overlayColor: const Color(
                        0xFF16476B,
                      ).withValues(alpha: 0.2),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: const TextStyle(
                            color: Color(0xFF5A7894),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            color: Color(0xFF5A7894),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Playback Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: 32,
                  color: const Color(0xFF16476B),
                  onPressed: () {
                    audioService.seek(Duration.zero);
                  },
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: audioService.togglePlayPause,
                  child: Hero(
                    tag: 'play_button_${item.titulo}_${currentVoz?.naipe}',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF043359),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: 32,
                  color: const Color(0xFF16476B),
                  onPressed: () {
                    // Logic to skip if needed
                  },
                ),
              ],
            ),

            // Speed Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: audioService.changeSpeed,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD3E4F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${playbackSpeed}x',
                      style: const TextStyle(
                        color: Color(0xFF16476B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Voice Selection
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecione o Naipe',
                  style: TextStyle(fontSize: 18, color: Color(0xFF1A1A1A)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: item.vozes.map((voz) {
                  final isSelected = currentVoz == voz;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () =>
                          audioService.playVoz(voz, keepPosition: true),
                      borderRadius: BorderRadius.circular(20),
                      child: Hero(
                        tag: 'title_voice_${item.titulo}_${voz.naipe}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF16476B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF16476B)
                                    : const Color(0xFFE0E0E0),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              voz.naipe,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF757575),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1, // Ensaios
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFD3E4F2),
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Ensaios',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
