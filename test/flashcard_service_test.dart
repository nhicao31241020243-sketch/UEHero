import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/data/decks/interview_deck.dart';
import 'package:uehero/data/decks/power_bi_deck.dart';
import 'package:uehero/data/decks/sql_deck.dart';
import 'package:uehero/data/flashcard_seed.dart';
import 'package:uehero/models/flashcard.dart';
import 'package:uehero/models/flashcard_deck.dart';
import 'package:uehero/services/flashcard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'seed library, favorite, Leitner boxes, streak and custom CRUD',
    () async {
      SharedPreferences.setMockInitialValues({
        'study_flashcards': jsonEncode([
          {
            'question': 'Câu hỏi cũ',
            'answer': 'Câu trả lời cũ',
            'subject': 'Kỹ năng',
            'createdAt': '2026-10-21T00:00:00.000',
            'source': 'interview',
          },
        ]),
      });
      final service = FlashcardService.instance;
      await service.initialize();

      expect(service.decks, hasLength(flashcardSeedDecks.length + 1));
      final practiceDeck = service.decks.firstWhere(
        (deck) => deck.id == FlashcardService.practiceDeckId,
      );
      expect(practiceDeck.cards.single.front, 'Câu hỏi cũ');
      expect(practiceDeck.cards.single.back, 'Câu trả lời cũ');
      expect(
        (await SharedPreferences.getInstance()).getString('study_flashcards'),
        isNull,
      );
      expect(
        service.decks.firstWhere((deck) => deck.id == sqlDeckId).cards,
        hasLength(18),
      );
      expect(
        service.decks.firstWhere((deck) => deck.id == powerBiDeckId).cards,
        hasLength(17),
      );
      expect(
        service.decks.firstWhere((deck) => deck.id == interviewDeckId).cards,
        hasLength(18),
      );

      final firstDay = DateTime(2026, 10, 13, 10);
      await service.toggleFavorite(sqlDeckId, 'sql-01');
      expect(service.favoriteCards.any((card) => card.id == 'sql-01'), isTrue);

      for (var i = 0; i < 3; i++) {
        await service.recordReview(
          sqlDeckId,
          'sql-01',
          known: true,
          at: firstDay,
        );
      }
      final mastered = service.decks
          .firstWhere((deck) => deck.id == sqlDeckId)
          .cards
          .firstWhere((card) => card.id == 'sql-01');
      expect(mastered.box, 3);
      expect(mastered.nextReviewAt, firstDay.add(const Duration(days: 7)));
      expect(
        service.masteredCount(
          service.decks.firstWhere((d) => d.id == sqlDeckId),
        ),
        1,
      );
      expect(service.streak, 1);
      expect(service.totalReviewed, 3);
      expect(service.totalCorrect, 3);

      final nextDay = firstDay.add(const Duration(days: 1));
      await service.recordReview(
        sqlDeckId,
        'sql-01',
        known: false,
        at: nextDay,
      );
      expect(
        service.decks
            .firstWhere((deck) => deck.id == sqlDeckId)
            .cards
            .firstWhere((card) => card.id == 'sql-01')
            .box,
        2,
      );
      expect(service.streak, 2);

      final customDeck = FlashcardDeck(
        id: 'custom-test',
        title: 'Gói tự tạo',
        iconCodePoint: Icons.style_rounded.codePoint,
        colorValue: const Color(0xFF72E0C4).toARGB32(),
        group: FlashcardGroup.tools,
        level: FlashcardLevel.basic,
        description: 'Deck kiểm thử.',
        cards: const [],
        isCustom: true,
      );
      await service.createDeck(customDeck);
      await service.addCard(
        const Flashcard(
          id: 'custom-test-card',
          deckId: 'custom-test',
          type: FlashcardType.tip,
          front: 'Mặt trước',
          back: 'Mặt sau',
        ),
      );
      expect(
        service.decks.firstWhere((deck) => deck.id == 'custom-test').cards,
        hasLength(1),
      );
      await service.addPracticeCards([
        const Flashcard(
          id: 'generated-test-card',
          deckId: FlashcardService.practiceDeckId,
          type: FlashcardType.interview,
          front: 'Câu hỏi luyện tập',
          back: 'Câu trả lời luyện tập',
        ),
      ]);
      final updatedPracticeDeck = service.decks.firstWhere(
        (deck) => deck.id == FlashcardService.practiceDeckId,
      );
      expect(updatedPracticeDeck.cards, hasLength(2));
      expect(updatedPracticeDeck.cards.last.front, 'Câu hỏi luyện tập');
      expect(updatedPracticeDeck.cards.last.back, 'Câu trả lời luyện tập');
      await service.deleteCard('custom-test', 'custom-test-card');
      await service.deleteDeck('custom-test');
      expect(service.decks.any((deck) => deck.id == 'custom-test'), isFalse);
    },
  );
}
