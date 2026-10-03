import 'package:flutter/material.dart';

/// Componente de diálogo reutilizável para exibição formatada de estruturas e dados em JSON.
class JsonConfigDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String jsonString;
  final String? highlightInfo;

  const JsonConfigDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.jsonString,
    this.highlightInfo,
  });

  /// Método utilitário para exibir o diálogo formatado.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String jsonString,
    String? highlightInfo,
  }) {
    return showDialog(
      context: context,
      builder: (_) => JsonConfigDialog(
        title: title,
        subtitle: subtitle,
        jsonString: jsonString,
        highlightInfo: highlightInfo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (highlightInfo != null && highlightInfo!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16476B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_android_rounded, size: 16, color: Color(0xFF16476B)),
                    const SizedBox(width: 6),
                    Text(
                      highlightInfo!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16476B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Conteúdo JSON:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                jsonString,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFF4EC9B0),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
