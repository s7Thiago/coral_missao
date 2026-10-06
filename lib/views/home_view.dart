import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../viewmodels/repertorio_viewmodel.dart';

import '../widgets/admin_panel_action_button.dart';
import '../widgets/dev_firebase_menu.dart';
import '../widgets/feature_toggle_guard.dart';
import '../widgets/firestore_loading_bar.dart';
import '../widgets/home_app_bar_title.dart';
import '../widgets/offline_status_chip.dart';
import '../widgets/player_overlay.dart';
import '../widgets/repertorio_empty_view.dart';
import '../widgets/repertorio_list_view.dart';
import '../widgets/splash_loading_view.dart';
import '../widgets/vocal_naipe_selector.dart';

/// Tela Principal da aplicação Coral Missão.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RepertorioViewModel>(context, listen: false).loadRepertorio();
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    final hasActiveAudio = audioService.currentVoz != null && audioService.currentItem != null;

    return Scaffold(
      appBar: AppBar(
        title: const HomeAppBarTitle(),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: const [
          OfflineStatusChip(),
          FeatureToggleGuard(
            featureName: 'adm_panel',
            child: AdminPanelActionButton(),
          ),
          FeatureToggleGuard(
            featureName: 'dev_menu',
            child: DevFirebaseMenu(),
          ),
        ],
        bottom: const FirestoreLoadingBar(),
      ),
      body: Stack(
        children: [
          Consumer<RepertorioViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const SplashLoadingView();
              }

              if (viewModel.error != null) {
                return Center(child: Text('Erro: ${viewModel.error}'));
              }

              if (viewModel.repertorio.isEmpty) {
                return RepertorioEmptyView(
                  selectedNaipe: viewModel.selectedNaipe,
                  onResetNaipe: () => viewModel.selectNaipe('TODAS AS VOZES'),
                );
              }

              return RepertorioListView(
                repertorio: viewModel.repertorio,
                hasActiveAudio: hasActiveAudio,
              );
            },
          ),
          // Seletor de naipes flutuante no rodapé
          Consumer<RepertorioViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.isLoading) {
                return const SizedBox.shrink();
              }
              return const VocalNaipeSelector();
            },
          ),
          // Player de Áudio quando ativo
          if (hasActiveAudio)
            PlayerOverlay(item: audioService.currentItem!),
        ],
      ),
    );
  }
}
