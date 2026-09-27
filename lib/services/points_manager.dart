import 'package:flutter/foundation.dart';

import '../models/event_item.dart';

class PointsManager extends ChangeNotifier {
	PointsManager._();

	static final PointsManager instance = PointsManager._();

	final Map<String, EventItem> _joinedEvents = {};

	int get totalPoints =>
			_joinedEvents.values.fold(0, (total, event) => total + event.trainingPoints);

	List<EventItem> get joinedEvents => List.unmodifiable(_joinedEvents.values);

	bool hasJoined(String title) => _joinedEvents.containsKey(title);

	void joinEvent(EventItem event) {
		if (_joinedEvents.containsKey(event.title)) return;

		_joinedEvents[event.title] = event;
		notifyListeners();
	}
}
