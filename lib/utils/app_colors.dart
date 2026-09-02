import 'package:flutter/material.dart';

class AppColors {
  // Voice Colors
  static const Color soprano = Color.fromARGB(255, 233, 74, 127);
  static const Color contralto = Color.fromARGB(255, 255, 123, 0);
  static const Color tenor = Color.fromARGB(255, 8, 187, 47);
  static const Color baixo = Color.fromARGB(255, 20, 124, 209);
  static const Color todasAsVozes = Color.fromARGB(255, 49, 138, 108);
  static const Color voiceDefault = Color(0xFF9E9E9E);

  static Color getVoiceColor(String voice) {
    final v = voice.toUpperCase();
    if (v.contains('SOPRANO')) return soprano;
    if (v.contains('CONTRALTO')) return contralto;
    if (v.contains('TENOR')) return tenor;
    if (v.contains('BAIXO')) return baixo;
    if (v.contains('TODAS AS VOZES')) return todasAsVozes;
    return voiceDefault;
  }
}
