import 'package:flutter/material.dart';
import '../models/repertorio_model.dart';
import '../utils/screen_utils.dart';
import 'repertorio_list_item.dart';

/// Componente desacoplado para exibição da lista de músicas do repertório.
class RepertorioListView extends StatelessWidget {
  final List<RepertorioItem> repertorio;
  final bool hasActiveAudio;

  const RepertorioListView({
    super.key,
    required this.repertorio,
    required this.hasActiveAudio,
  });

  @override
  Widget build(BuildContext context) {
    final double maxWidth = context.isDesktop
        ? 800
        : context.isTablet
            ? 700
            : MediaQuery.of(context).size.width;

    return ListView.builder(
      padding: EdgeInsets.only(
        top: 8,
        bottom: hasActiveAudio ? 180 : 100,
      ),
      itemCount: repertorio.length,
      itemBuilder: (context, index) {
        final RepertorioItem item = repertorio[index];
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
            ),
            child: RepertorioListItem(
              key: ValueKey(item.id),
              item: item,
              isDownloaded: false,
              onPressed: () {},
              onPlayPressed: () {},
            ),
          ),
        );
      },
    );
  }
}
