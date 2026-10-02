import 'package:flutter/material.dart';

class Mascot {
  const Mascot({
    required this.id,
    required this.name,
    required this.title,
    required this.model3dUrl,
    required this.primaryColor,
    required this.traits,
    required this.stats,
    required this.emoji,
  });

  final String id;
  final String name;
  final String title;
  final String model3dUrl;
  final Color primaryColor;
  final List<String> traits;
  final Map<String, String> stats;
  final String emoji;

  static const animalModel = 'assets/3d/animal_bag.glb';

  static const List<Mascot> collection = [
    Mascot(
      id: 'fox-coder',
      name: 'Cáo Coder',
      title: 'Chuyên sửa bug 2h sáng',
      model3dUrl: animalModel,
      primaryColor: Color(0xFFFF8A8A),
      traits: ['Ngu Vi mô', 'Thích vibe coding'],
      stats: {'Sức cày': '99/100', 'Độ cọc': '80%', 'IQ Vi Mô': '5/100'},
      emoji: '🦊',
    ),
    Mascot(
      id: 'owl-knowledge',
      name: 'Cú Tri Thức',
      title: 'Thức đêm gánh team',
      model3dUrl: animalModel,
      primaryColor: Color(0xFFC39EA0),
      traits: ['Thèm ăn 24/7', 'Ghi chú đủ màu'],
      stats: {'Sức cày': '95/100', 'Độ tập trung': '88%', 'Pin xã hội': '12%'},
      emoji: '🦉',
    ),
    Mascot(
      id: 'cat-micro',
      name: 'Mèo Vi Mô',
      title: 'Cân cả đường cung lẫn đường cầu',
      model3dUrl: animalModel,
      primaryColor: Color(0xFF5CD895),
      traits: ['Thèm ăn 24/7', 'Hay cáu giận'],
      stats: {'IQ Vi Mô': '99/100', 'Độ cọc': '80%', 'Độ chill': '75%'},
      emoji: '🐱',
    ),
  ];
}

class MascotSelection {
  MascotSelection._();

  static Mascot? selected;
}
