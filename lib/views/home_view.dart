import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/repertorio_viewmodel.dart';
import '../models/repertorio_model.dart';
import '../services/audio_service.dart';
import '../widgets/repertorio_list_item.dart';
import '../widgets/player_overlay.dart';
import '../widgets/vocal_naipe_selector.dart';
import '../utils/screen_utils.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is ready or just call it.
    // listen: false is crucial here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RepertorioViewModel>(context, listen: false).loadRepertorio();
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final hasActiveAudio = audioService.currentVoz != null && audioService.currentItem != null;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Repertório Coral'),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            actions: [
              Consumer<RepertorioViewModel>(
                builder: (context, viewModel, _) {
                  if (!viewModel.isUsingLocalFallback) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Tooltip(
                      message: 'Sem conexão — exibindo repertório salvo',
                      child: Chip(
                        avatar: const Icon(
                          Icons.wifi_off_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Offline',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: const Color(0xFF5E819D),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Consumer<RepertorioViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.error != null) {
                return Center(child: Text('Erro: ${viewModel.error}'));
              }

              if (viewModel.repertorio.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_off_rounded,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          viewModel.selectedNaipe == 'TODAS AS VOZES'
                              ? 'Nenhum dado encontrado.'
                              : 'Nenhuma música encontrada para o naipe ${viewModel.selectedNaipe}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5E819D),
                          ),
                        ),
                        if (viewModel.selectedNaipe != 'TODAS AS VOZES') ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => viewModel.selectNaipe('TODAS AS VOZES'),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Exibir todas as vozes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16476B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: hasActiveAudio ? 180 : 100,
                ),
                itemCount: viewModel.repertorio.length,
                itemBuilder: (context, index) {
                  final RepertorioItem item = viewModel.repertorio[index];
                  return Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutQuad,
                      constraints: BoxConstraints(
                        maxWidth: context.isDesktop
                            ? 800
                            : context.isTablet
                            ? 700
                            : MediaQuery.of(context).size.width,
                      ),
                      child: RepertorioListItem(
                        item: item,
                        isDownloaded: false,
                        onPressed: () {
                          // TODO: Implement download logic
                          print('Download ${item.titulo}');
                        },
                        onPlayPressed: () {
                          // TODO: Implement play logic
                          print('Play ${item.titulo}');
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Componente flutuante fixo de seleção de naipes na parte inferior
        const VocalNaipeSelector(),
        // Overlay do Player de Áudio quando ativo (exibido acima da seleção de naipes)
        if (hasActiveAudio)
          PlayerOverlay(item: audioService.currentItem!),
      ],
    );
  }
}

