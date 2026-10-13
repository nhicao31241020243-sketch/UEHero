import 'package:flutter/material.dart';

import 'flashcard.dart';

enum FlashcardGroup {
  data('Dữ liệu'),
  tools('Công cụ'),
  analysis('Tư duy phân tích'),
  project('Quản lý dự án'),
  communication('Giao tiếp & Phỏng vấn'),
  english('Tiếng Anh');

  const FlashcardGroup(this.label);

  final String label;

  static FlashcardGroup fromName(String? value) =>
      FlashcardGroup.values.firstWhere(
        (group) => group.name == value,
        orElse: () => FlashcardGroup.data,
      );
}

enum FlashcardLevel {
  basic('Cơ bản'),
  intermediate('Trung cấp'),
  advanced('Nâng cao');

  const FlashcardLevel(this.label);

  final String label;

  static FlashcardLevel fromName(String? value) =>
      FlashcardLevel.values.firstWhere(
        (level) => level.name == value,
        orElse: () => FlashcardLevel.basic,
      );
}

class FlashcardDeck {
  static final Map<int, IconData> _knownIcons = {
    Icons.storage_rounded.codePoint: Icons.storage_rounded,
    Icons.bar_chart_rounded.codePoint: Icons.bar_chart_rounded,
    Icons.table_chart_rounded.codePoint: Icons.table_chart_rounded,
    Icons.code_rounded.codePoint: Icons.code_rounded,
    Icons.view_kanban_rounded.codePoint: Icons.view_kanban_rounded,
    Icons.design_services_rounded.codePoint: Icons.design_services_rounded,
    Icons.fact_check_rounded.codePoint: Icons.fact_check_rounded,
    Icons.account_tree_rounded.codePoint: Icons.account_tree_rounded,
    Icons.lightbulb_outline_rounded.codePoint: Icons.lightbulb_outline_rounded,
    Icons.groups_rounded.codePoint: Icons.groups_rounded,
    Icons.forum_rounded.codePoint: Icons.forum_rounded,
    Icons.record_voice_over_rounded.codePoint: Icons.record_voice_over_rounded,
    Icons.description_rounded.codePoint: Icons.description_rounded,
    Icons.translate_rounded.codePoint: Icons.translate_rounded,
    Icons.style_rounded.codePoint: Icons.style_rounded,
  };

  const FlashcardDeck({
    required this.id,
    required this.title,
    required this.iconCodePoint,
    required this.colorValue,
    required this.group,
    required this.level,
    required this.description,
    required this.cards,
    this.iconFontFamily = 'MaterialIcons',
    this.isCustom = false,
  });

  final String id;
  final String title;
  final int iconCodePoint;
  final String? iconFontFamily;
  final int colorValue;
  final FlashcardGroup group;
  final FlashcardLevel level;
  final String description;
  final List<Flashcard> cards;
  final bool isCustom;

  IconData get icon => _knownIcons[iconCodePoint] ?? Icons.style_rounded;

  Color get color => Color(colorValue);

  FlashcardDeck copyWith({
    String? id,
    String? title,
    int? iconCodePoint,
    String? iconFontFamily,
    int? colorValue,
    FlashcardGroup? group,
    FlashcardLevel? level,
    String? description,
    List<Flashcard>? cards,
    bool? isCustom,
  }) => FlashcardDeck(
    id: id ?? this.id,
    title: title ?? this.title,
    iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    iconFontFamily: iconFontFamily ?? this.iconFontFamily,
    colorValue: colorValue ?? this.colorValue,
    group: group ?? this.group,
    level: level ?? this.level,
    description: description ?? this.description,
    cards: cards ?? this.cards,
    isCustom: isCustom ?? this.isCustom,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'iconCodePoint': iconCodePoint,
    'iconFontFamily': iconFontFamily,
    'colorValue': colorValue,
    'group': group.name,
    'level': level.name,
    'description': description,
    'cards': cards.map((card) => card.toJson()).toList(),
    'isCustom': isCustom,
  };

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) => FlashcardDeck(
    id: json['id'] as String,
    title: json['title'] as String,
    iconCodePoint: (json['iconCodePoint'] as num).toInt(),
    iconFontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
    colorValue: (json['colorValue'] as num).toInt(),
    group: FlashcardGroup.fromName(json['group'] as String?),
    level: FlashcardLevel.fromName(json['level'] as String?),
    description: json['description'] as String? ?? '',
    cards: (json['cards'] as List<dynamic>? ?? const [])
        .map((card) => Flashcard.fromJson(card as Map<String, dynamic>))
        .toList(),
    isCustom: json['isCustom'] as bool? ?? false,
  );
}
