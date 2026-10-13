import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/flashcard_seed.dart';
import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';

class FlashcardService extends ChangeNotifier {
  FlashcardService._();

  static final FlashcardService instance = FlashcardService._();
  static const storageKey = 'flashcard_library_v1';

  List<FlashcardDeck> _decks = [];
  Set<String> _hiddenDeckIds = {};
  bool _initialized = false;
  int _streak = 0;
  String? _lastStudyDate;
  int _totalReviewed = 0;
  int _totalCorrect = 0;

  bool get isInitialized => _initialized;
  int get streak => _streak;
  int get totalReviewed => _totalReviewed;
  int get totalCorrect => _totalCorrect;

  List<FlashcardDeck> get decks => List.unmodifiable(
    _decks.where((deck) => !_hiddenDeckIds.contains(deck.id)),
  );

  List<Flashcard> get favoriteCards => [
    for (final deck in decks)
      for (final card in deck.cards)
        if (card.isFavorite) card,
  ];

  List<Flashcard> get dueCards {
    final now = DateTime.now();
    return [
      for (final deck in decks)
        for (final card in deck.cards)
          if (card.nextReviewAt == null || !card.nextReviewAt!.isAfter(now))
            card,
    ];
  }

  Future<void> initialize() async {
    if (_initialized) return;
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(storageKey);
    if (saved == null) {
      _decks = List.of(flashcardSeedDecks);
    } else {
      final decoded = jsonDecode(saved);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Flashcard storage must be a JSON object.');
      }
      final savedDecks = (decoded['decks'] as List<dynamic>? ?? const [])
          .map((item) => FlashcardDeck.fromJson(item as Map<String, dynamic>))
          .toList();
      _decks = _mergeSeedDecks(savedDecks);
      _hiddenDeckIds = (decoded['hiddenDeckIds'] as List<dynamic>? ?? const [])
          .cast<String>()
          .toSet();
      _streak = (decoded['streak'] as num?)?.toInt() ?? 0;
      _lastStudyDate = decoded['lastStudyDate'] as String?;
      _totalReviewed = (decoded['totalReviewed'] as num?)?.toInt() ?? 0;
      _totalCorrect = (decoded['totalCorrect'] as num?)?.toInt() ?? 0;
    }
    _initialized = true;
    await _persist();
    notifyListeners();
  }

  List<FlashcardDeck> _mergeSeedDecks(List<FlashcardDeck> savedDecks) {
    final byId = {for (final deck in savedDecks) deck.id: deck};
    for (final seed in flashcardSeedDecks) {
      final oldDeck = byId[seed.id];
      if (oldDeck == null) {
        byId[seed.id] = seed;
        continue;
      }
      final storedCards = {for (final card in oldDeck.cards) card.id: card};
      for (final card in seed.cards) {
        storedCards.putIfAbsent(card.id, () => card);
      }
      byId[seed.id] = oldDeck.copyWith(cards: storedCards.values.toList());
    }
    return byId.values.toList();
  }

  Future<void> createDeck(FlashcardDeck deck) async {
    _requireInitialized();
    if (_decks.any((existing) => existing.id == deck.id)) {
      throw ArgumentError.value(deck.id, 'deck.id', 'Deck ID already exists.');
    }
    _decks = [..._decks, deck.copyWith(isCustom: true)];
    await _persistAndNotify();
  }

  Future<void> updateDeck(FlashcardDeck deck) async {
    _requireInitialized();
    final index = _decks.indexWhere((item) => item.id == deck.id);
    if (index < 0) {
      throw ArgumentError.value(deck.id, 'deck.id', 'Deck not found.');
    }
    _decks[index] = deck;
    await _persistAndNotify();
  }

  Future<void> deleteDeck(String deckId) async {
    _requireInitialized();
    _decks.removeWhere((deck) => deck.id == deckId);
    _hiddenDeckIds.add(deckId);
    await _persistAndNotify();
  }

  Future<void> resetDeckProgress(String deckId) async {
    final deck = _findDeck(deckId);
    final resetCards = deck.cards
        .map((card) => card.copyWith(box: 0, clearNextReviewAt: true))
        .toList();
    await updateDeck(deck.copyWith(cards: resetCards));
  }

  Future<void> addCard(Flashcard card) async {
    final deck = _findDeck(card.deckId);
    if (deck.cards.any((existing) => existing.id == card.id)) {
      throw ArgumentError.value(card.id, 'card.id', 'Card ID already exists.');
    }
    await updateDeck(deck.copyWith(cards: [...deck.cards, card]));
  }

  Future<void> updateCard(Flashcard card) async {
    final deck = _findDeck(card.deckId);
    final index = deck.cards.indexWhere((item) => item.id == card.id);
    if (index < 0) {
      throw ArgumentError.value(card.id, 'card.id', 'Card not found.');
    }
    final cards = [...deck.cards]..[index] = card;
    await updateDeck(deck.copyWith(cards: cards));
  }

  Future<void> deleteCard(String deckId, String cardId) async {
    final deck = _findDeck(deckId);
    await updateDeck(
      deck.copyWith(
        cards: deck.cards.where((card) => card.id != cardId).toList(),
      ),
    );
  }

  Future<void> toggleFavorite(String deckId, String cardId) async {
    final card = _findDeck(deckId).cards.firstWhere(
      (item) => item.id == cardId,
      orElse: () =>
          throw ArgumentError.value(cardId, 'cardId', 'Card not found.'),
    );
    await updateCard(card.copyWith(isFavorite: !card.isFavorite));
  }

  Future<Flashcard> recordReview(
    String deckId,
    String cardId, {
    required bool known,
    DateTime? at,
  }) async {
    final deck = _findDeck(deckId);
    final index = deck.cards.indexWhere((card) => card.id == cardId);
    if (index < 0) {
      throw ArgumentError.value(cardId, 'cardId', 'Card not found.');
    }
    final card = deck.cards[index];
    final now = at ?? DateTime.now();
    final box = known ? (card.box + 1).clamp(0, 3) : (card.box - 1).clamp(0, 3);
    final nextAt = known
        ? now.add(_intervalForBox(box))
        : (box == 0 ? now : now.add(const Duration(minutes: 10)));
    final reviewed = card.copyWith(box: box, nextReviewAt: nextAt);
    final cards = [...deck.cards]..[index] = reviewed;
    _decks[_decks.indexWhere((item) => item.id == deckId)] = deck.copyWith(
      cards: cards,
    );
    _totalReviewed++;
    if (known) _totalCorrect++;
    _recordStudyDay(now);
    await _persistAndNotify();
    return reviewed;
  }

  Duration _intervalForBox(int box) => switch (box) {
    1 => const Duration(days: 1),
    2 => const Duration(days: 3),
    >= 3 => const Duration(days: 7),
    _ => const Duration(minutes: 10),
  };

  void _recordStudyDay(DateTime at) {
    final today = _dateKey(at);
    if (_lastStudyDate == today) return;
    final yesterday = _dateKey(at.subtract(const Duration(days: 1)));
    _streak = _lastStudyDate == yesterday ? _streak + 1 : 1;
    _lastStudyDate = today;
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  FlashcardDeck _findDeck(String id) => _decks.firstWhere(
    (deck) => deck.id == id && !_hiddenDeckIds.contains(id),
    orElse: () => throw ArgumentError.value(id, 'deckId', 'Deck not found.'),
  );

  double masteryProgress(FlashcardDeck deck) {
    if (deck.cards.isEmpty) return 0;
    var total = 0.0;
    var mastered = 0.0;
    for (final card in deck.cards) {
      final weight = switch (card.difficulty) {
        FlashcardDifficulty.easy => 1.0,
        FlashcardDifficulty.medium => 1.5,
        FlashcardDifficulty.hard => 2.0,
      };
      total += weight;
      if (card.box >= 3) mastered += weight;
    }
    return mastered / total;
  }

  int masteredCount(FlashcardDeck deck) =>
      deck.cards.where((card) => card.box >= 3).length;

  void _requireInitialized() {
    if (!_initialized) {
      throw StateError('Call initialize() before using FlashcardService.');
    }
  }

  Future<void> _persistAndNotify() async {
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    final data = {
      'version': 1,
      'decks': _decks.map((deck) => deck.toJson()).toList(),
      'hiddenDeckIds': _hiddenDeckIds.toList(),
      'streak': _streak,
      'lastStudyDate': _lastStudyDate,
      'totalReviewed': _totalReviewed,
      'totalCorrect': _totalCorrect,
    };
    final saved = await preferences.setString(storageKey, jsonEncode(data));
    if (!saved) throw StateError('Could not persist flashcard library.');
  }
}
