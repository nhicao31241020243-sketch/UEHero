import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cv_check.dart';

class CvScoreStore {
  static const historyKey = 'cv_check_history';
  static const bestScoreKey = 'cv_check_best_score';

  Future<List<CvScoreEntry>> entries({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(historyKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((entry) => CvScoreEntry.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  Future<int> bestScore({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final savedBest = prefs.getInt(bestScoreKey) ?? 0;
    final history = await entries(preferences: prefs);
    return history.fold<int>(
      savedBest,
      (best, entry) => math.max(best, entry.score),
    );
  }

  Future<int> lastScore({SharedPreferences? preferences}) async {
    final history = await entries(preferences: preferences);
    return history.isEmpty ? 0 : history.first.score;
  }

  Future<int> previousBest({SharedPreferences? preferences}) async {
    final history = await entries(preferences: preferences);
    if (history.isEmpty) return 0;
    final savedPreviousBest = history.first.previousBest;
    if (savedPreviousBest != null) return savedPreviousBest;
    return history
        .skip(1)
        .fold<int>(0, (best, entry) => math.max(best, entry.score));
  }

  Future<CvScoreRecord> record({
    required int score,
    required String goalId,
    required String target,
    DateTime? createdAt,
    SharedPreferences? preferences,
  }) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final previousBest = await bestScore(preferences: prefs);
    final oldEntries = await entries(preferences: prefs);
    final entry = CvScoreEntry(
      score: score.clamp(0, 100),
      goalId: goalId,
      target: target,
      createdAt: createdAt ?? DateTime.now(),
      previousBest: previousBest,
    );
    final updatedEntries = [entry, ...oldEntries];
    await prefs.setString(
      historyKey,
      jsonEncode(updatedEntries.map((item) => item.toJson()).toList()),
    );
    final updatedBest = math.max(previousBest, entry.score);
    await prefs.setInt(bestScoreKey, updatedBest);
    return CvScoreRecord(
      entry: entry,
      previousBest: previousBest,
      bestScore: updatedBest,
      isFirstCheck: oldEntries.isEmpty,
    );
  }
}

class CvScoreRecord {
  const CvScoreRecord({
    required this.entry,
    required this.previousBest,
    required this.bestScore,
    required this.isFirstCheck,
  });

  final CvScoreEntry entry;
  final int previousBest;
  final int bestScore;
  final bool isFirstCheck;
}

int cvCheckXp({
  required int score,
  required int previousBest,
  required bool isFirstCheck,
}) {
  if (score <= previousBest) return 0;
  final cap = isFirstCheck ? 20 : 50;
  return math.min(cap, (score - previousBest) * 2);
}
