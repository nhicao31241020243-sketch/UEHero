import 'package:flutter/material.dart';

class HubCardPalette {
  const HubCardPalette({
    required this.top,
    required this.bottom,
    required this.accent,
  });

  final Color top;
  final Color bottom;
  final Color accent;

  static const Map<String, HubCardPalette> _cards = {
    'mercury': HubCardPalette(
      top: Color(0xFF49368F),
      bottom: Color(0xFF2A205D),
      accent: Color(0xFFC6B4FF),
    ),
    'venus': HubCardPalette(
      top: Color(0xFF713A40),
      bottom: Color(0xFF48242D),
      accent: Color(0xFFFFB894),
    ),
    'earth': HubCardPalette(
      top: Color(0xFF28727C),
      bottom: Color(0xFF174752),
      accent: Color(0xFF9AE7D8),
    ),
    'mars': HubCardPalette(
      top: Color(0xFF8C2B49),
      bottom: Color(0xFF581C3B),
      accent: Color(0xFFFFA5B9),
    ),
    'jupiter': HubCardPalette(
      top: Color(0xFF75412C),
      bottom: Color(0xFF49271F),
      accent: Color(0xFFFFCE8C),
    ),
    'saturn': HubCardPalette(
      top: Color(0xFF5B486F),
      bottom: Color(0xFF362D4A),
      accent: Color(0xFFD1B8FF),
    ),
    'uranus': HubCardPalette(
      top: Color(0xFF21627A),
      bottom: Color(0xFF123C5B),
      accent: Color(0xFF9DEBFF),
    ),
    'events': HubCardPalette(
      top: Color(0xFF393C91),
      bottom: Color(0xFF23245F),
      accent: Color(0xFFB5BAFF),
    ),
  };

  static HubCardPalette forActionKey(String actionKey) =>
      _cards[actionKey] ??
      const HubCardPalette(
        top: Color(0xFF393C91),
        bottom: Color(0xFF23245F),
        accent: Color(0xFFB5BAFF),
      );

  static Set<String> get actionKeys => _cards.keys.toSet();
}

class PlanetAssets {
  static const int animationCycleSeconds = 360360;

  static const Map<String, String> _imageByCardTitle = {
    'Job Match': 'mercury',
    'Book Swap': 'venus',
    'Study Buddy': 'earth',
    'Weekly Plan': 'mars',
    'UEH Mentor': 'jupiter',
    'Skill Drills': 'saturn',
    'CV Check': 'uranus',
    'Events': 'mercury',
  };

  static const Map<String, String> _planetByCardTitle = {
    'Job Match': 'mercury',
    'Book Swap': 'venus',
    'Study Buddy': 'earth',
    'Weekly Plan': 'mars',
    'UEH Mentor': 'jupiter',
    'Skill Drills': 'saturn',
    'CV Check': 'uranus',
    'Events': 'events',
  };

  static const Map<String, String> _paths = {
    'mercury': 'assets/images/planets/mercury.png',
    'venus': 'assets/images/planets/venus.png',
    'earth': 'assets/images/planets/earth.png',
    'mars': 'assets/images/planets/mars.png',
    'jupiter': 'assets/images/planets/jupiter.png',
    'saturn': 'assets/images/planets/saturn.png',
    'uranus': 'assets/images/planets/uranus.png',
    'neptune': 'assets/images/planets/neptune.png',
  };

  static const Map<String, double> rotationSeconds = {
    'mercury': 8,
    'venus': 9,
    'earth': 10,
    'mars': 11,
    'jupiter': 12,
    'saturn': 13,
    'uranus': 14,
    'events': 10.5,
  };

  static String forCardTitle(String title) =>
      _paths[_imageByCardTitle[title]] ?? _paths['earth']!;

  static String planetForCardTitle(String title) =>
      _planetByCardTitle[title] ?? 'earth';
}
