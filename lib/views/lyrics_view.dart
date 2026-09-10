import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/repertorio_model.dart';
import '../services/audio_service.dart';
import '../widgets/subtle_player_controls.dart';

class LyricsView extends StatefulWidget {
  final RepertorioItem item;
  final bool showPlayerControls;
  final bool showCloseButton;
  final bool showTitle;
  final bool showAlignmentControls;
  final TextAlign defaultTextAlign;

  const LyricsView({
    super.key,
    required this.item,
    this.showPlayerControls = true,
    this.showCloseButton = true,
    this.showTitle = true,
    this.showAlignmentControls = true,
    this.defaultTextAlign = TextAlign.left,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  double _fontSize = 18.0;
  double _baseFontSize = 18.0;
  late TextAlign _textAlign;

  @override
  void initState() {
    super.initState();
    _textAlign = widget.defaultTextAlign;
  }

  void _resetFontSize() {
    setState(() {
      _fontSize = 18.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final isPlayingOrActive =
        audioService.currentItem?.id == widget.item.id ||
        audioService.isPlaying;

    final String fullText = widget.item.letra.isNotEmpty
        ? widget.item.letra.join('\n')
        : 'Nenhuma letra disponível para esta música.';

    return HeroControllerScope(
      controller: HeroController(),
      child: Material(
        color: const Color(0xFFF7FAFC),
        child: SafeArea(
          top: widget.showCloseButton,
          bottom: widget.showPlayerControls,
          child: Stack(
            children: [
              Column(
                children: [
                  // Header Bar
                  if (widget.showCloseButton || widget.showTitle)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          if (widget.showCloseButton)
                            IconButton(
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 30,
                              ),
                              onPressed: () => Navigator.of(context).maybePop(),
                              tooltip: 'Fechar',
                            ),
                          if (widget.showTitle)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.item.titulo,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A365D),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text(
                                    'Letra da música',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF718096),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Reset Font Size Button
                          IconButton(
                            icon: const Icon(Icons.format_size_rounded),
                            tooltip: 'Tamanho original (${_fontSize.toInt()}pt)',
                            onPressed: _resetFontSize,
                          ),
                        ],
                      ),
                    ),

                  // Controls Bar for Text Alignment
                  if (widget.showAlignmentControls)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      color: const Color(0xFFEDF2F7),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Alinhamento:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                          Row(
                            children: [
                              _buildAlignButton(
                                icon: Icons.format_align_left_rounded,
                                align: TextAlign.left,
                              ),
                              _buildAlignButton(
                                icon: Icons.format_align_center_rounded,
                                align: TextAlign.center,
                              ),
                              _buildAlignButton(
                                icon: Icons.format_align_right_rounded,
                                align: TextAlign.right,
                              ),
                              _buildAlignButton(
                                icon: Icons.format_align_justify_rounded,
                                align: TextAlign.justify,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Pinch-to-zoom area & Lyrics text view
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: (details) {
                        _baseFontSize = _fontSize;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          _fontSize = (_baseFontSize * details.scale).clamp(
                            12.0,
                            48.0,
                          );
                        });
                      },
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 20,
                          bottom: widget.showPlayerControls ? 140 : 20,
                        ),
                        physics: const BouncingScrollPhysics(),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 80),
                          child: Text(
                            fullText,
                            textAlign: _textAlign,
                            style: TextStyle(
                              fontSize: _fontSize,
                              height: 1.6,
                              color: const Color(0xFF2D3748),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Floating Subtle Audio Controls
              if (widget.showPlayerControls &&
                  (isPlayingOrActive || widget.item.vozes.isNotEmpty))
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: SubtlePlayerControls(item: widget.item),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlignButton({required IconData icon, required TextAlign align}) {
    final isSelected = _textAlign == align;
    return IconButton(
      icon: Icon(icon, size: 20),
      color: isSelected ? const Color(0xFF1A365D) : const Color(0xFFA0AEC0),
      style: isSelected
          ? IconButton.styleFrom(backgroundColor: const Color(0xFFCBD5E0))
          : null,
      onPressed: () {
        setState(() {
          _textAlign = align;
        });
      },
      visualDensity: VisualDensity.compact,
    );
  }
}
