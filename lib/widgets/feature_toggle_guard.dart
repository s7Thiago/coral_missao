import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/feature_toggle_service.dart';
import '../utils/device_utils.dart';

/// Componente visual desacoplado que oculta ou exibe um widget filho ([child]) com base no controle de acesso (Feature Toggle) do Firestore.
///
/// Assinatura esperada:
/// - [featureName]: Nome identificador da funcionalidade (ex: 'adm_panel')
/// - [deviceId]: (Opcional) ID único do dispositivo. Se não informado, busca dinamicamente via [DeviceUtils.getDeviceId()].
/// - [child]: O widget que só será visível caso o dispositivo possua acesso liberado.
/// - [fallback]: O widget exibido quando o acesso for negado (padrão: `SizedBox.shrink()`).
class FeatureToggleGuard extends StatelessWidget {
  final String featureName;
  final String? deviceId;
  final Widget child;
  final Widget fallback;

  const FeatureToggleGuard({
    super.key,
    required this.featureName,
    required this.child,
    this.deviceId,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    final featureService = context.watch<FeatureToggleService>();

    return FutureBuilder<String>(
      future: (deviceId != null && deviceId!.isNotEmpty)
          ? Future.value(deviceId!)
          : DeviceUtils.getDeviceId(),
      builder: (context, deviceSnapshot) {
        if (!deviceSnapshot.hasData || deviceSnapshot.data!.isEmpty) {
          return fallback;
        }

        final currentDeviceId = deviceSnapshot.data!;

        return StreamBuilder<bool>(
          stream: featureService.streamDeviceAccess(
            featureName: featureName,
            deviceId: currentDeviceId,
          ),
          builder: (context, accessSnapshot) {
            if (accessSnapshot.connectionState == ConnectionState.waiting &&
                !accessSnapshot.hasData) {
              return fallback;
            }

            final hasAccess = accessSnapshot.data ?? false;

            if (hasAccess) {
              return child;
            } else {
              return fallback;
            }
          },
        );
      },
    );
  }
}
