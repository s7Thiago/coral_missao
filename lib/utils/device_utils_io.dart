import 'dart:io';

/// Obtém uma assinatura determinística das características do dispositivo nativo (Android, iOS, Desktop).
String getPlatformFingerprint() {
  try {
    final os = Platform.operatingSystem;
    final osVersion = Platform.operatingSystemVersion;
    final hostname = Platform.localHostname;
    final processors = Platform.numberOfProcessors;
    final tz = DateTime.now().timeZoneOffset.inMinutes;

    return 'IO|$os|$osVersion|$hostname|$processors|$tz';
  } catch (_) {
    return 'IO_FALLBACK';
  }
}
