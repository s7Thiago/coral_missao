import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';

/// Barra de progresso discreta e reativa para exibição na AppBar quando houver operações assíncronas do Firestore ativas.
class FirestoreLoadingBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final Color? color;

  const FirestoreLoadingBar({
    super.key,
    this.height = 3.0,
    this.color,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<FirestoreService>();

    return ValueListenableBuilder<bool>(
      valueListenable: firestoreService.isLoadingNotifier,
      builder: (context, isLoading, _) {
        if (!isLoading) {
          return SizedBox(height: height);
        }

        return LinearProgressIndicator(
          minHeight: height,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? const Color(0xFF16476B),
          ),
        );
      },
    );
  }
}
