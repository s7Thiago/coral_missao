import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/repertorio_viewmodel.dart';

/// Chip discreto e desacoplado para sinalizar estado offline e uso de fallback local.
class OfflineStatusChip extends StatelessWidget {
  const OfflineStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RepertorioViewModel>(
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
    );
  }
}
