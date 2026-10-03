import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/feature_toggle_service.dart';
import '../utils/device_utils.dart';
import 'error_details_dialog.dart';
import 'grant_access_dialog.dart';
import 'json_config_dialog.dart';

/// Componente de menu de contexto desacoplado para testes e ferramentas do Firebase Firestore na Tela Inicial.
class DevFirebaseMenu extends StatelessWidget {
  const DevFirebaseMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      constraints: const BoxConstraints(
        minWidth: 260,
        maxWidth: 320,
      ),
      icon: const Icon(
        Icons.developer_mode_rounded,
        color: Color(0xFF16476B),
      ),
      tooltip: 'Menu Dev & Firebase',
      onSelected: (value) async {
        if (value == 'grant_access') {
          await GrantAccessDialog.show(context);
        } else if (value == 'feature_toggle_adm_panel') {
          await _recordFeatureAccess(
            context,
            featureName: 'adm_panel',
            featureTitle: 'painel adm',
          );
        } else if (value == 'feature_toggle_dev_menu') {
          await _recordFeatureAccess(
            context,
            featureName: 'dev_menu',
            featureTitle: 'dev menu',
          );
        } else if (value == 'view_feature_toggle') {
          await _viewCurrentFeatureToggle(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'FERRAMENTAS FIREBASE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'grant_access',
          child: Row(
            children: [
              Icon(Icons.add_moderator_rounded, size: 20, color: Color(0xFF16476B)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Feature Toggle (Conceder Acesso)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'feature_toggle_adm_panel',
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, size: 20, color: Color(0xFF16476B)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Feature Toggle (Gravar acesso painel adm)',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'feature_toggle_dev_menu',
          child: Row(
            children: [
              Icon(Icons.security_rounded, size: 20, color: Color(0xFF16476B)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Feature Toggle (Gravar acesso dev menu)',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'view_feature_toggle',
          child: Row(
            children: [
              Icon(Icons.data_object_rounded, size: 20, color: Color(0xFF16476B)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ver JSON do Feature Toggle',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Executa o registro de acesso no Firestore para uma determinada funcionalidade/feature
  Future<void> _recordFeatureAccess(
    BuildContext context, {
    required String featureName,
    required String featureTitle,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final featureService = context.read<FeatureToggleService>();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Obtendo DeviceID e gravando acesso para "$featureName"...'),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final deviceId = await DeviceUtils.getDeviceId();

      final updatedConfig = await featureService.addOrUpdateDeviceAccess(
        featureName: featureName,
        username: 'Thiago (Dev)',
        deviceId: deviceId,
        deviceName: 'Celular Atual',
        accessLevel: 'FULL',
      );

      if (context.mounted) {
        await JsonConfigDialog.show(
          context,
          title: '🔥 Acesso Gravado ($featureTitle)!',
          subtitle: 'Dispositivo registrado com sucesso para a feature "$featureName".',
          jsonString: const JsonEncoder.withIndent('  ').convert(updatedConfig.toJson()),
          highlightInfo: 'ID Atual: $deviceId',
        );
      }
    } catch (e) {
      if (context.mounted) {
        await ErrorDetailsDialog.show(
          context,
          title: 'Erro ao Gravar Acesso no Firestore',
          error: e,
        );
      }
    }
  }

  /// Consulta e exibe a configuração atual do Firestore
  Future<void> _viewCurrentFeatureToggle(BuildContext context) async {
    final featureService = context.read<FeatureToggleService>();

    try {
      final deviceId = await DeviceUtils.getDeviceId();
      final config = await featureService.getFeatureToggleConfig();

      if (context.mounted) {
        await JsonConfigDialog.show(
          context,
          title: '📄 Configuração Atual no Firestore',
          subtitle: 'Documento lido de "config/feature_toggle".',
          jsonString: const JsonEncoder.withIndent('  ').convert(config.toJson()),
          highlightInfo: 'ID Atual: $deviceId',
        );
      }
    } catch (e) {
      if (context.mounted) {
        await ErrorDetailsDialog.show(
          context,
          title: 'Erro ao Buscar Dados do Firestore',
          error: e,
        );
      }
    }
  }
}
