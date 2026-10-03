import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/feature_toggle_service.dart';
import '../utils/device_utils.dart';
import 'error_details_dialog.dart';
import 'json_config_dialog.dart';

/// Modal desacoplado com formulário intuitivo para conceder ou atualizar acesso a features e dispositivos no Firestore.
class GrantAccessDialog extends StatefulWidget {
  const GrantAccessDialog({super.key});

  /// Método estático utilitário para exibir o modal.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const GrantAccessDialog(),
    );
  }

  @override
  State<GrantAccessDialog> createState() => _GrantAccessDialogState();
}

class _GrantAccessDialogState extends State<GrantAccessDialog> {
  final _formKey = GlobalKey<FormState>();

  final _featureController = TextEditingController(text: 'adm_panel');
  final _userController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _deviceNameController = TextEditingController(text: 'Celular');
  String _accessLevel = 'FULL'; // 'FULL' | 'READ_ONLY'

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fillCurrentDeviceId();
  }

  /// Pré-preenche o Device ID com o identificador único do dispositivo atual
  Future<void> _fillCurrentDeviceId() async {
    final currentId = await DeviceUtils.getDeviceId();
    if (mounted && _deviceIdController.text.isEmpty) {
      setState(() {
        _deviceIdController.text = currentId;
      });
    }
  }

  @override
  void dispose() {
    _featureController.dispose();
    _userController.dispose();
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final featureService = context.read<FeatureToggleService>();
    final featureName = _featureController.text.trim();
    final username = _userController.text.trim();
    final deviceId = _deviceIdController.text.trim();
    final deviceName = _deviceNameController.text.trim();

    try {
      final updatedConfig = await featureService.addOrUpdateDeviceAccess(
        featureName: featureName,
        username: username,
        deviceId: deviceId,
        deviceName: deviceName,
        accessLevel: _accessLevel,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Fecha o formulário
        await JsonConfigDialog.show(
          context,
          title: '✅ Acesso Concedido!',
          subtitle: 'Permissão para a feature "$featureName" foi salva com sucesso.',
          jsonString: const JsonEncoder.withIndent('  ').convert(updatedConfig.toJson()),
          highlightInfo: 'ID: $deviceId',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await ErrorDetailsDialog.show(
          context,
          title: 'Erro ao Conceder Acesso',
          error: e,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.add_moderator_rounded, color: Color(0xFF16476B), size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Conceder Acesso (Feature Toggle)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preencha os dados abaixo para autorizar uma funcionalidade para um dispositivo:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // Campo Nome da Feature
              TextFormField(
                controller: _featureController,
                decoration: InputDecoration(
                  labelText: 'Nome da Feature',
                  hintText: 'ex: adm_panel, dev_menu, relatorios',
                  prefixIcon: const Icon(Icons.extension_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe o nome da feature';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Campo Nome do Usuário (Dono do Dispositivo)
              TextFormField(
                controller: _userController,
                decoration: InputDecoration(
                  labelText: 'Dono do Dispositivo (Usuário)',
                  hintText: 'ex: Nathalia, Geovani',
                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe o nome do usuário';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Campo Device ID
              TextFormField(
                controller: _deviceIdController,
                decoration: InputDecoration(
                  labelText: 'Device ID',
                  hintText: 'ex: DEV-BB12-3456-7890',
                  prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    tooltip: 'Usar ID deste dispositivo',
                    onPressed: _fillCurrentDeviceId,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe o Device ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Campo Nome do Dispositivo
              TextFormField(
                controller: _deviceNameController,
                decoration: InputDecoration(
                  labelText: 'Nome do Dispositivo',
                  hintText: 'ex: Celular, Notebook',
                  prefixIcon: const Icon(Icons.devices_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe um nome para o dispositivo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Campo Nível de Acesso (FULL | READ_ONLY)
              DropdownButtonFormField<String>(
                initialValue: _accessLevel,
                decoration: InputDecoration(
                  labelText: 'Nível de Acesso',
                  prefixIcon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'FULL',
                    child: Text('Acesso Total (FULL)'),
                  ),
                  DropdownMenuItem(
                    value: 'READ_ONLY',
                    child: Text('Apenas Leitura (READ_ONLY)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _accessLevel = val);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: const Text('Conceder Acesso'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16476B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
