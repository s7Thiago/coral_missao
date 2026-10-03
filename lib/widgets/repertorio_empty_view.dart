import 'package:flutter/material.dart';

/// Componente visual desacoplado exibido quando o repertório filtrado ou total estiver vazio.
class RepertorioEmptyView extends StatelessWidget {
  final String selectedNaipe;
  final VoidCallback onResetNaipe;

  const RepertorioEmptyView({
    super.key,
    required this.selectedNaipe,
    required this.onResetNaipe,
  });

  @override
  Widget build(BuildContext context) {
    final isTodasVozes = selectedNaipe == 'TODAS AS VOZES';

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
              isTodasVozes
                  ? 'Nenhum dado encontrado.'
                  : 'Nenhuma música encontrada para o naipe $selectedNaipe.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5E819D),
              ),
            ),
            if (!isTodasVozes) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onResetNaipe,
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
}
