import 'package:flutter/material.dart';

import '../../models/flashcard.dart';
import '../../models/flashcard_deck.dart';

Flashcard createSeedCard({
  required String id,
  required String deckId,
  required FlashcardType type,
  required String front,
  required String back,
  String subTopic = '',
  FlashcardCodeLanguage codeLanguage = FlashcardCodeLanguage.none,
  String example = '',
  List<String> quizOptions = const [],
  int? correctChoice,
  FlashcardDifficulty difficulty = FlashcardDifficulty.medium,
  List<String> tags = const [],
}) => Flashcard(
  id: id,
  deckId: deckId,
  type: type,
  front: front,
  back: back,
  subTopic: subTopic,
  codeLanguage: codeLanguage,
  example: example,
  quizOptions: quizOptions,
  correctChoice: correctChoice,
  difficulty: difficulty,
  tags: tags,
);

FlashcardDeck createSeedDeck({
  required String id,
  required String title,
  required IconData icon,
  required Color color,
  required FlashcardGroup group,
  required FlashcardLevel level,
  required String description,
  required List<Flashcard> cards,
}) => FlashcardDeck(
  id: id,
  title: title,
  iconCodePoint: icon.codePoint,
  iconFontFamily: icon.fontFamily,
  colorValue: color.toARGB32(),
  group: group,
  level: level,
  description: description,
  cards: cards,
);
