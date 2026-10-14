import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/career_progress_config.dart';
import 'points_manager.dart';

class ProgressService extends ChangeNotifier {
  ProgressService._() {
    PointsManager.instance.addListener(_onXpChanged);
  }

  static final instance = ProgressService._();
  static const _pendingAnimationKey = 'career_progress_pending_animation';

  bool get isInitialized => PointsManager.instance.isInitialized;
  int get totalPoints => PointsManager.instance.totalXp;

  Future<void> initialize({SharedPreferences? preferences}) =>
      PointsManager.instance.initialize(preferences: preferences);

  Future<bool> consumePendingAnimation() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_pendingAnimationKey) ?? false;
    if (pending) await prefs.setBool(_pendingAnimationKey, false);
    return pending;
  }

  String rankFor(int points) {
    var rank = careerRanks.first.name;
    for (final candidate in careerRanks) {
      if (points >= candidate.minimumPoints) rank = candidate.name;
    }
    return rank;
  }

  CareerNodeConfig currentNodeFor(int points) {
    var current = careerNodes.first;
    for (final node in careerNodes) {
      if (points >= node.threshold) current = node;
    }
    return current;
  }

  CareerNodeConfig? nextNodeFor(int points) {
    for (final node in careerNodes) {
      if (node.threshold > points) return node;
    }
    return null;
  }

  int pointsToNextNode(int points) =>
      (nextNodeFor(points)?.threshold ?? points) - points;

  void _onXpChanged() => notifyListeners();

  @override
  void dispose() {
    PointsManager.instance.removeListener(_onXpChanged);
    super.dispose();
  }
}
