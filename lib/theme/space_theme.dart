import 'package:flutter/material.dart';

abstract final class SpaceTheme {
  // Design tokens
  static const String fontFamily = 'Lexend';

  static const Color bgTop = Color(0xFF050914);
  static const Color bgMid = Color(0xFF0E1033);
  static const Color bgIndigo = Color(0xFF1B1750);
  static const Color bgDusk = Color(0xFF4A2A63);
  static const Color bgRose = Color(0xFF7A3F73);
  static const List<Color> backgroundColors = [
    bgTop,
    bgMid,
    bgIndigo,
    bgDusk,
    bgRose,
  ];
  static const List<double> backgroundStops = [0, 0.3, 0.58, 0.82, 1];

  static const Color glassTint = Color(0x261E2A78);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x66FFFFFF);
  static const Color glow = Color(0xFFFFB454);
  static const Color glowOrange = Color(0xFFFF7A3D);
  static const Color navyButton = Color(0xFF16206B);
  static const Color textPrimary = Colors.white;
  static const Color textMuted = Color(0xB3FFFFFF);
  static const Color constellation = Color(0xFFFFE6A8);

  static const double cardRadius = 28;
  static const double controlRadius = 18;

  static const Color ink = bgTop;
  static const Color glass = glassTint;
  static const Color glassStrong = Color(0x2B8CA0FF);
  static const Color textSecondary = Color(0xFFD9DDF5);
  static const Color blue = Color(0xFF5B7CFF);
  static const Color violet = Color(0xFF8A63FF);

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5E86FF), Color(0xFF5B5BE6), Color(0xFF8A52F0)],
  );

  static const LinearGradient xpGradient = LinearGradient(
    colors: [glow, glowOrange],
  );

  static Widget _gradientButtonBackground(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    final gradient = states.contains(WidgetState.disabled)
        ? const LinearGradient(colors: [Color(0xFF53627C), Color(0xFF424F68)])
        : blueGradient;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(controlRadius),
      ),
      child: child ?? const SizedBox.expand(),
    );
  }

  static ThemeData get data {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fontFamily),
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: base.colorScheme.copyWith(
        surface: const Color(0xE60F1238),
        primary: blue,
        secondary: violet,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: glass,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF0141A47),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        contentTextStyle: const TextStyle(color: textSecondary, height: 1.4),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xF0141A47),
        modalBackgroundColor: Color(0xF0141A47),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Color(0x80FFFFFF),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(backgroundBuilder: _gradientButtonBackground).merge(
          ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF367FFF),
            disabledBackgroundColor: const Color(0xFF46536B),
            disabledForegroundColor: const Color(0xFFB7C5D9),
            elevation: 5,
            shadowColor: blue.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(controlRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(backgroundBuilder: _gradientButtonBackground).merge(
          FilledButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF367FFF),
            disabledBackgroundColor: const Color(0xFF46536B),
            disabledForegroundColor: const Color(0xFFB7C5D9),
            elevation: 5,
            shadowColor: blue.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(controlRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
