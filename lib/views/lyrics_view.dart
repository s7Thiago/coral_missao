import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/repertorio_model.dart';
import '../services/audio_service.dart';
import '../widgets/draggable_subtle_player_controls.dart';
import '../widgets/floating_lyrics_header.dart';
import '../widgets/floating_lyrics_toolbar.dart';

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
    this.defaultTextAlign = TextAlign.center,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  double _fontSize = 18.0;
  double _baseFontSize = 18.0;
  late TextAlign _textAlign;
  late ScrollController _scrollController;
  bool _showFloatingHeader = false;
  ToolbarDockLocation? _toolbarDockLocation;

  @override
  void initState() {
    super.initState();
    _textAlign = widget.defaultTextAlign;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.showTitle) {
      final shouldShow =
          _scrollController.hasClients && _scrollController.offset > 50;
      if (shouldShow != _showFloatingHeader) {
        setState(() {
          _showFloatingHeader = shouldShow;
        });
      }
    }
  }

  void _resetFontSize() {
    setState(() {
      _fontSize = 18.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final isItemActive = audioService.currentItem?.id == widget.item.id;
    final isPlaying = isItemActive && audioService.isPlaying;
    final position = isItemActive ? audioService.position : Duration.zero;
    final isMusicActive = isItemActive && (isPlaying || position > Duration.zero);
    final isPlayingOrActive = isItemActive || isPlaying;

    // Calcula o offset inferior dinâmico para evitar sobreposição quando o player muda de tamanho
    final isPlayerExpanded = audioService.isPlayerExpanded && isMusicActive;
    double dynamicBottomOffset = 70.0;
    if (widget.showPlayerControls && isMusicActive) {
      dynamicBottomOffset = isPlayerExpanded ? 165.0 : 88.0;
    }

    final String rawMarkdown = widget.item.letra.isNotEmpty
        ? widget.item.letra.join('\n')
        : 'Nenhuma letra disponível para esta música.';

    // Garante que quebras de linha simples dentro da mesma estrofe tenham '  \n' (soft break),
    // enquanto estrofes mantêm a separação por parágrafos do Markdown ('\n\n').
    final String formattedMarkdown = rawMarkdown
        .split('\n\n')
        .map((stanza) =>
            stanza.split('\n').map((line) => line.trimRight()).join('  \n'))
        .join('\n\n');

    final wrapAlign = _getWrapAlignment(_textAlign);

    return HeroControllerScope(
      controller: HeroController(),
      child: Material(
        color: const Color(0xFFF7FAFC),
        child: SafeArea(
          top: widget.showCloseButton,
          bottom: widget.showPlayerControls,
          child: Stack(
            children: [
              // Área principal da letra com suporte a pinça (zoom) e rolagem
              GestureDetector(
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
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: widget.showPlayerControls ? 140 : 20,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: _crossAlignmentFromTextAlign(_textAlign),
                      children: [
                        // Título Inline da Música (Scrollável com a letra e acompanhando o alinhamento selecionado)
                        if (widget.showCloseButton || widget.showTitle)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Row(
                              children: [
                                if (widget.showCloseButton)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 30,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 44,
                                      height: 44,
                                    ),
                                  ),
                                if (widget.showTitle)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          _crossAlignmentFromTextAlign(_textAlign),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.item.titulo,
                                          textAlign: _textAlign,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A365D),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Letra da música',
                                          textAlign: _textAlign,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF718096),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (widget.showCloseButton && widget.showTitle)
                                  const SizedBox(width: 44),
                              ],
                            ),
                          ),

                        // Corpo da Letra em Markdown
                        MarkdownBody(
                          data: formattedMarkdown,
                          selectable: true,
                          fitContent: false,
                          styleSheet: MarkdownStyleSheet(
                            textAlign: wrapAlign,
                            h1Align: wrapAlign,
                            h2Align: wrapAlign,
                            h3Align: wrapAlign,
                            h4Align: wrapAlign,
                            h5Align: wrapAlign,
                            h6Align: wrapAlign,
                            unorderedListAlign: wrapAlign,
                            orderedListAlign: wrapAlign,
                            blockquoteAlign: wrapAlign,
                            codeblockAlign: wrapAlign,
                            p: TextStyle(
                              fontSize: _fontSize,
                              height: 1.6,
                              color: const Color(0xFF2D3748),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                            h1: TextStyle(
                              fontSize: _fontSize * 1.4,
                              height: 1.4,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A365D),
                            ),
                            h2: TextStyle(
                              fontSize: _fontSize * 1.25,
                              height: 1.4,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2B6CB0),
                            ),
                            h3: TextStyle(
                              fontSize: _fontSize * 1.1,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                            strong: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A202C),
                            ),
                            em: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                            blockquote: TextStyle(
                              fontSize: _fontSize,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF4A5568),
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: const Color(0xFFEDF2F7),
                              borderRadius: BorderRadius.circular(4),
                              border: const Border(
                                left: BorderSide(
                                  color: Color(0xFF3182CE),
                                  width: 4,
                                ),
                              ),
                            ),
                            blockquotePadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            pPadding: const EdgeInsets.only(bottom: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Cabeçalho Flutuante Sutil (Acompanha o alinhamento da letra)
              if (widget.showTitle)
                FloatingLyricsHeader(
                  title: widget.item.titulo,
                  isVisible: _showFloatingHeader,
                  textAlign: _textAlign,
                  onClose: widget.showCloseButton
                      ? () => Navigator.of(context).maybePop()
                      : null,
                ),

              // Painel Flutuante Combinado de Controles (Alinhamento + Fonte + Orientação Dinâmica + Drag & Drop)
              if (widget.showAlignmentControls)
                FloatingLyricsToolbar(
                  textAlign: _textAlign,
                  onAlignChanged: (newAlign) {
                    setState(() {
                      _textAlign = newAlign;
                    });
                  },
                  fontSize: _fontSize,
                  onFontSizeChanged: (newSize) {
                    setState(() {
                      _fontSize = newSize;
                    });
                  },
                  onResetFontSize: _resetFontSize,
                  bottomOffset: dynamicBottomOffset,
                  onDockLocationChanged: (location) {
                    setState(() {
                      _toolbarDockLocation = location;
                    });
                  },
                ),

              // Player de Áudio Flutuante e Arrastável com Ancoragem Magnética e Reação Dinâmica
              if (widget.showPlayerControls &&
                  (isPlayingOrActive || widget.item.vozes.isNotEmpty))
                DraggableSubtlePlayerControls(
                  item: widget.item,
                  toolbarDockLocation: _toolbarDockLocation,
                ),
            ],
          ),
        ),
      ),
    );
  }

  CrossAxisAlignment _crossAlignmentFromTextAlign(TextAlign align) {
    switch (align) {
      case TextAlign.left:
      case TextAlign.start:
        return CrossAxisAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      case TextAlign.center:
      default:
        return CrossAxisAlignment.center;
    }
  }

  WrapAlignment _getWrapAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.left:
      case TextAlign.start:
        return WrapAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return WrapAlignment.end;
      case TextAlign.center:
      default:
        return WrapAlignment.center;
    }
  }
}
