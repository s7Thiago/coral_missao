import 'package:flutter/material.dart';
import '../utils/ui_utils.dart';
import '../views/admin_panel_view.dart';

/// Botão de ação na AppBar para acesso ao Painel Administrativo.
class AdminPanelActionButton extends StatelessWidget {
  const AdminPanelActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.menu_book_rounded,
        color: Color(0xFF16476B),
      ),
      tooltip: 'Painel ADM',
      onPressed: () {
        customLauncher(
          context: context,
          target: const AdminPanelView(),
          opaque: true,
        );
      },
    );
  }
}
