import 'package:flutter/material.dart';

/// Componente de título desacoplado para a AppBar com logo e nome do aplicativo.
class HomeAppBarTitle extends StatelessWidget {
  const HomeAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 36,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        const Text(
          'Repertório Coral',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
