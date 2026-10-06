import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/device_utils.dart';

/// Overlay flutuante discreto para exibição da versão do aplicativo e ID do dispositivo em ambiente de teste.
/// Suporta cópia do ID através de pressão longa (Long Press).
class DeviceIdOverlay extends StatelessWidget {
  const DeviceIdOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: Future.wait([
        DeviceUtils.getAppVersion(),
        DeviceUtils.getDeviceId(),
      ]),
      initialData: [
        DeviceUtils.cachedAppVersion ?? 'v1.0.1+1',
        DeviceUtils.cachedDeviceId ?? '',
      ],
      builder: (context, snapshot) {
        final data = snapshot.data;
        final version = (data != null && data.isNotEmpty) ? data[0] : 'v1.0.1+1';
        final id = (data != null && data.length > 1) ? data[1] : '';

        if (id.isEmpty) {
          return const SizedBox.shrink();
        }

        return Material(
          type: MaterialType.transparency,
          child: GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: id));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.copy_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ID copiado: $id',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.only(
                      bottom: 40,
                      left: 16,
                      right: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: const Color(0xFF16476B),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$version | ID: $id',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
