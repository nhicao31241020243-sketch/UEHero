import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/career_goal_config.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import 'cv_score_store.dart';
import 'points_manager.dart';

class GoalProgressService extends ChangeNotifier {
  GoalProgressService._() {
    FlashcardService.instance.addListener(_changed);
    PointsManager.instance.addListener(_changed);
  }

  static final instance = GoalProgressService._();
  final _flashcards = FlashcardService.instance;
  final _xp = PointsManager.instance;
  int _cvBestScore = 0;
  CareerGoal selectedGoal = careerGoals.first;

  Future<void> initialize() async {
    await _flashcards.initialize();
    await _xp.initialize();
    final prefs = await SharedPreferences.getInstance();
    selectedGoal = goalForStoredName(prefs.getString('career_goal'));
    _cvBestScore = await CvScoreStore().bestScore(preferences: prefs);
    notifyListeners();
  }

  double criterionProgress(CareerGoal goal, String criterionId) {
    final criterion = goal.criteria.firstWhere(
      (item) => item.id == criterionId,
      orElse: () => const GoalCriterion(
        id: 'missing',
        label: '',
        weight: 0,
        enabled: false,
      ),
    );
    if (!criterion.enabled) return 0;
    if (criterionId == 'cv') return _cvBestScore / 100;
    if (criterionId != 'flashcard') return 0;
    final cards = <Flashcard>[
      for (final deck in _flashcards.decks)
        if (goal.deckIds.contains(deck.id)) ...deck.cards,
    ];
    if (cards.isEmpty) return 0;
    return cards.where((card) => card.box >= 3).length / cards.length;
  }

  double totalProgress(CareerGoal goal) {
    final enabled = goal.criteria.where((criterion) => criterion.enabled);
    final totalWeight = enabled.fold<int>(0, (sum, item) => sum + item.weight);
    if (totalWeight == 0) return 0;
    final weighted = enabled.fold<double>(
      0,
      (sum, item) => sum + criterionProgress(goal, item.id) * item.weight,
    );
    return weighted / totalWeight;
  }

  int flashcardXpToday() {
    final now = DateTime.now();
    return _xp.entries
        .where(
          (entry) =>
              entry.source == 'flashcard' &&
              entry.createdAt.year == now.year &&
              entry.createdAt.month == now.month &&
              entry.createdAt.day == now.day,
        )
        .fold(0, (sum, entry) => sum + entry.amount);
  }

  void _changed() => notifyListeners();

  @override
  void dispose() {
    _flashcards.removeListener(_changed);
    PointsManager.instance.removeListener(_changed);
    super.dispose();
  }
}
