import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/repertorio_viewmodel.dart';
import '../models/repertorio_model.dart';
import '../widgets/repertorio_list_item.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repertório Coral'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
            return const Center(child: Text('Nenhum dado encontrado.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
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
    );
  }
}
