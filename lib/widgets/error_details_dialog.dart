import 'package:flutter/material.dart';

/// Componente de diálogo reutilizável e desacoplado para exibição detalhada de erros e exceções.
class ErrorDetailsDialog extends StatelessWidget {
  final String title;
  final dynamic error;

  const ErrorDetailsDialog({
    super.key,
    required this.title,
    required this.error,
  });

  /// Método utilitário para exibir o diálogo em qualquer ponto da aplicação.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required dynamic error,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ErrorDetailsDialog(
        title: title,
        error: error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawErrorStr = error.toString();
    final isPermissionDenied = rawErrorStr.contains('permission-denied') ||
        rawErrorStr.contains('insufficient permissions');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPermissionDenied) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel_rounded, color: Colors.amber, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Permissão Negada no Firestore',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Suas Regras de Segurança (Security Rules) no Firebase Console estão bloqueando o acesso.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Como resolver no Firebase Console:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1. Acesse o Firebase Console (Firestore > Regras).\n'
                      '2. Altere de "allow read, write: if false;" para:\n'
                      '   allow read, write: if true;\n'
                      '3. Clique em Publicar.',
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'Detalhes da Exceção:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: SelectableText(
                rawErrorStr.replaceAll(RegExp(r'^Exception:\s*'), ''),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.red.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    );
  }
}
