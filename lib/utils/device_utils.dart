import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

import 'device_utils_stub.dart'
    if (dart.library.html) 'device_utils_web.dart'
    if (dart.library.io) 'device_utils_io.dart';

class DeviceUtils {
  static String? _cachedDeviceId;
  static const String _storageKey = 'app_device_id';

  /// Retorna o identificador único do dispositivo de forma persistente e cross-platform.
  /// 
  /// Funciona em Web, PWA, Android, iOS e Desktop sem gerar erros.
  /// Mesmo que o usuário limpe os dados do app/navegador, a assinatura determinística de hardware/navegador
  /// é recalculada e gera exatamente o mesmo ID.
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      Box box;
      if (Hive.isBoxOpen('kitsCoral')) {
        box = Hive.box('kitsCoral');
      } else {
        box = await Hive.openBox('kitsCoral');
      }

      final String? savedId = box.get(_storageKey);
      if (savedId != null && savedId.isNotEmpty) {
        _cachedDeviceId = savedId;
        return savedId;
      }

      final generatedId = _generateDeviceId();
      await box.put(_storageKey, generatedId);
      _cachedDeviceId = generatedId;
      return generatedId;
    } catch (_) {
      final generatedId = _generateDeviceId();
      _cachedDeviceId = generatedId;
      return generatedId;
    }
  }

  /// Retorna o ID síncrono previamente em cache (pode ser null se ainda não foi inicializado).
  static String? get cachedDeviceId => _cachedDeviceId;

  /// Gera um identificador único com base no hash SHA-256 da assinatura da plataforma.
  static String _generateDeviceId() {
    final rawFingerprint = getPlatformFingerprint();
    final bytes = utf8.encode(rawFingerprint);
    final digest = sha256.convert(bytes);
    final hex = digest.toString().toUpperCase();

    // Formato amigável e único: DEV-XXXX-XXXX-XXXX
    return 'DEV-${hex.substring(0, 4)}-${hex.substring(4, 8)}-${hex.substring(8, 12)}';
  }
}
