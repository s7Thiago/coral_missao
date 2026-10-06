import 'package:flutter/material.dart';
import '../viewmodels/admin_panel_viewmodel.dart';
import 'vocal_balance_card.dart';

/// Modal desacoplado para visualizar o Dashboard de Equilíbrio Vocal dos Naipes.
class VocalBalanceDialog extends StatelessWidget {
  final AdminPanelViewModel viewModel;

  const VocalBalanceDialog({
    super.key,
    required this.viewModel,
  });

  static Future<void> show(BuildContext context, {required AdminPanelViewModel viewModel}) {
    return showDialog(
      context: context,
      builder: (_) => VocalBalanceDialog(viewModel: viewModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  VocalBalanceCard(viewModel: viewModel),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Fechar',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
