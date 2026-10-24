import 'package:flutter/material.dart';

import '../models/flashcard_deck.dart';

class DeckPalette {
  const DeckPalette._();

  static const colors = [
    Color(0xFFC6283D),
    Color(0xFFAD235F),
    Color(0xFF6636A8),
    Color(0xFF1558A6),
    Color(0xFFB74716),
    Color(0xFF28743A),
    Color(0xFF805300),
    Color(0xFF087367),
    Color(0xFF176D83),
    Color(0xFF39469A),
    Color(0xFF8D2B74),
    Color(0xFF85451F),
    Color(0xFFB72F2F),
    Color(0xFF4C368E),
    Color(0xFF1D6276),
    Color(0xFF70511A),
  ];

  static const _groupStarts = {
    FlashcardGroup.data: 0,
    FlashcardGroup.tools: 3,
    FlashcardGroup.analysis: 6,
    FlashcardGroup.project: 9,
    FlashcardGroup.communication: 10,
    FlashcardGroup.english: 11,
  };

  static Color colorForGroup(FlashcardGroup group) =>
      colors[_groupStarts[group] ?? 0];

  static Color colorFor(FlashcardDeck deck) {
    final start = _groupStarts[deck.group] ?? 0;
    return colors[(start + _stableHash(deck.id) % 3) % colors.length];
  }

  static Map<String, Color> assign(Iterable<FlashcardDeck> decks) {
    final assignments = <String, Color>{};
    final used = <int>{};
    var previous = -1;
    for (final deck in decks) {
      final start = _groupStarts[deck.group] ?? 0;
      var index = (start + _stableHash(deck.id) % 3) % colors.length;
      if (used.contains(index)) {
        var offset = 1;
        while (offset < colors.length &&
            (used.contains((index + offset) % colors.length) ||
                (index + offset) % colors.length == previous)) {
          offset++;
        }
        index = (index + offset) % colors.length;
      }
      if (used.length == colors.length) used.clear();
      if (index == previous) index = (index + 1) % colors.length;
      assignments[deck.id] = colors[index];
      used.add(index);
      previous = index;
    }
    return assignments;
  }

  static Color darker(Color color, [double amount = 0.28]) =>
      Color.lerp(color, Colors.black, amount)!;

  static Color foreground(Color color) {
    final luminance = color.computeLuminance();
    final whiteContrast = 1.05 / (luminance + 0.05);
    final blackContrast = (luminance + 0.05) / 0.05;
    return whiteContrast >= blackContrast
        ? Colors.white
        : const Color(0xFF17131B);
  }

  static int _stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class DeckIconMap {
  const DeckIconMap._();

  static const defaultEmoji = '✨';

  static const _byId = {
    'skill-python-data': '🐍',
    'skill-excel': '📊',
    'skill-jira-confluence': '🗂️',
    'skill-figma-wireframe': '🎨',
    'skill-requirements': '📋',
    'skill-process-modeling': '🔀',
    'skill-business-frameworks': '💡',
    'skill-agile-scrum': '🚀',
    'skill-stakeholder-communication': '🗣️',
    'skill-interview': '🎙️',
    'skill-cv-email': '📄',
    'skill-english-jd': '📚',
    'skill-sql': '🗄️',
    'skill-power-bi': '📈',
  };

  static String emojiFor(FlashcardDeck deck) =>
      _byId[deck.id] ?? _emojiForTitle(deck.title) ?? defaultEmoji;

  static String? _emojiForTitle(String title) {
    final value = title.toLowerCase();
    if (value.contains('python')) return '🐍';
    if (value.contains('excel')) return '📊';
    if (value.contains('jira') || value.contains('kanban')) return '🗂️';
    if (value.contains('figma') || value.contains('design')) return '🎨';
    if (value.contains('requirement')) return '📋';
    if (value.contains('agile') || value.contains('scrum')) return '🚀';
    if (value.contains('business') || value.contains('framework')) return '💡';
    if (value.contains('sql') || value.contains('database')) return '🗄️';
    if (value.contains('interview')) return '🎙️';
    if (value.contains('communication') || value.contains('stakeholder')) {
      return '🗣️';
    }
    return null;
  }
}
