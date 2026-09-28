import 'package:flutter/material.dart';

abstract final class StudioTheme {
  static const canvas = Color(0xFFF5F1EB);
  static const surface = Color(0xFFFFFDFA);
  static const ink = Color(0xFF352D31);
  static const muted = Color(0xFF796E70);
  static const line = Color(0xFFE6DED6);
  static const wine = Color(0xFF9A4358);
  static const coral = Color(0xFFE47754);
  static const apricot = Color(0xFFF4AE73);
  static const mint = Color(0xFF579886);
  static const plum = Color(0xFF8977AA);

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = ink,
  }) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.25);

  static BoxDecoration card({double radius = 24, Color color = surface}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16422B26),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      );
}
