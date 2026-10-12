import 'package:flutter/foundation.dart';

import '../models/event_item.dart';

class PointsManager extends ChangeNotifier {
  PointsManager._();

  static final PointsManager instance = PointsManager._();

  final Map<String, EventItem> _joinedEvents = {};
  int _cvPoints = 0;
  int _jobApplicationPoints = 0;
  int _spentPoints = 0;

  int get totalPoints =>
      (_cvPoints +
              _jobApplicationPoints +
              _joinedEvents.values.fold(
                0,
                (total, event) => total + event.trainingPoints,
              ) -
              _spentPoints)
          .toInt();

  List<EventItem> get joinedEvents => List.unmodifiable(_joinedEvents.values);

  bool hasJoined(String title) => _joinedEvents.containsKey(title);

  void joinEvent(EventItem event) {
    if (_joinedEvents.containsKey(event.title)) return;

    _joinedEvents[event.title] = event;
    notifyListeners();
  }

  void addCvPoints(int points) {
    if (points <= 0) return;
    _cvPoints += points;
    notifyListeners();
  }

  void addJobApplicationPoints(int points) {
    if (points <= 0) return;
    _jobApplicationPoints += points;
    notifyListeners();
  }

  bool trySpendPoints(int points) {
    if (points <= 0 || totalPoints < points) {
      return false;
    }
    _spentPoints += points;
    notifyListeners();
    return true;
  }
}
