import 'package:flutter/material.dart';

class AppColors {
  // Voice Colors
  static const Color soprano = Color(0xFFE91E63);
  static const Color contralto = Color(0xFFFF9800);
  static const Color tenor = Color(0xFF4CAF50);
  static const Color baixo = Color(0xFF2196F3);
  static const Color voiceDefault = Color(0xFF9E9E9E);

  static Color getVoiceColor(String voice) {
    final v = voice.toUpperCase();
    if (v.contains('SOPRANO')) return soprano;
    if (v.contains('CONTRALTO')) return contralto;
    if (v.contains('TENOR')) return tenor;
    if (v.contains('BAIXO')) return baixo;
    return voiceDefault;
  }
}
