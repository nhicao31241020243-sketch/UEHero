import 'package:flutter/material.dart';

abstract final class SpaceTheme {
  static const Color ink = Color(0xFF07152D);
  static const Color glass = Color(0x1FFFFFFF);
  static const Color glassStrong = Color(0x2B8CCBFF);
  static const Color textSecondary = Color(0xFFD4E4FF);
  static const Color blue = Color(0xFF339DFF);
  static const Color violet = Color(0xFF795CFF);
  static const double cardRadius = 26;
  static const double controlRadius = 18;

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38B7FF), Color(0xFF397CFF), Color(0xFF7658FF)],
  );

  static Widget _gradientButtonBackground(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    final gradient = states.contains(WidgetState.disabled)
        ? const LinearGradient(
            colors: [Color(0xFF53627C), Color(0xFF424F68)],
          )
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
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: base.colorScheme.copyWith(
        surface: const Color(0xE6101D38),
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
        backgroundColor: const Color(0xF0162544),
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
        backgroundColor: Color(0xF0162544),
        modalBackgroundColor: Color(0xF0162544),
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
        style: ButtonStyle(
          backgroundBuilder: _gradientButtonBackground,
        ).merge(
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
        style: ButtonStyle(
          backgroundBuilder: _gradientButtonBackground,
        ).merge(
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
