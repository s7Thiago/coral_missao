// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// Obtém uma assinatura determinística das características do navegador/dispositivo na Web/PWA.
/// Como não muda com o tempo ou limpeza de dados, permite recriar o mesmo ID único caso a storage seja limpa.
String getPlatformFingerprint() {
  try {
    final nav = html.window.navigator;
    final screen = html.window.screen;

    final ua = nav.userAgent;
    final lang = nav.language;
    final platform = nav.platform ?? '';
    final cores = nav.hardwareConcurrency ?? 0;
    final touchPoints = nav.maxTouchPoints ?? 0;
    final screenW = screen?.width ?? 0;
    final screenH = screen?.height ?? 0;
    final colorDepth = screen?.colorDepth ?? 0;
    final tz = DateTime.now().timeZoneOffset.inMinutes;

    return 'WEB|$ua|$lang|$platform|$cores|$touchPoints|$screenW|$screenH|$colorDepth|$tz';
  } catch (_) {
    return 'WEB_FALLBACK';
  }
}
