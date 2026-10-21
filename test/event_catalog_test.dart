import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uehero/models/event_item.dart';
import 'package:uehero/services/event_repository.dart';

class FakeEventRepository implements EventRepository {
  FakeEventRepository(this.items);

  final List<EventItem> items;

  @override
  Future<List<EventItem>> fetchEvents() async => items;

  @override
  Future<void> refresh() async {}

  @override
  Stream<List<EventItem>> watchEvents() => Stream.value(items);
}

EventItem _event({
  required String id,
  required String title,
  String type = 'Cuộc thi',
  DateTime? registrationDeadline,
  DateTime? registrationOpen,
  DateTime? eventStart,
  DateTime? eventEnd,
  bool newSeasonUnknown = false,
  List<String> careers = const [],
  List<String> skills = const [],
  DateTime? createdAt,
}) => EventItem(
  id: id,
  title: title,
  organizer: 'UEH',
  type: type,
  registrationDeadline: registrationDeadline,
  registrationOpen: registrationOpen,
  eventStart: eventStart,
  eventEnd: eventEnd,
  isNewSeasonUnknown: newSeasonUnknown,
  relatedCareers: careers,
  skills: skills,
  createdAt: createdAt,
);

void main() {
  group('EventItem parsing and date-derived status', () {
    test('parses Firestore Timestamps and nullable fields', () {
      final deadline = DateTime(2026, 10, 23, 23, 59);
      final event = EventItem.fromFirestore('official-id', {
        'title': 'Datathon',
        'organizer': 'UEH',
        'type': 'Datathon',
        'registrationDeadline': Timestamp.fromDate(deadline),
        'eventStart': null,
        'relatedCareers': ['Data Analyst'],
        'skills': ['SQL'],
        'posterUrl': null,
        'needsVerification': true,
      });

      expect(event.id, 'official-id');
      expect(event.registrationDeadline, deadline);
      expect(event.eventStart, isNull);
      expect(event.posterUrl, isNull);
      expect(event.relatedCareers, ['Data Analyst']);
      expect(event.needsVerification, isTrue);
    });

    test('calculates opening, open, ended, and unknown-season states', () {
      final now = DateTime(2026, 10, 19, 12);
      expect(
        _event(
          id: 'opening',
          title: 'Opening',
          registrationOpen: DateTime(2026, 10, 20),
        ).statusAt(now),
        EventStatus.openingSoon,
      );
      expect(
        _event(
          id: 'open',
          title: 'Open',
          registrationDeadline: DateTime(2026, 10, 23),
        ).statusAt(now),
        EventStatus.registrationOpen,
      );
      expect(
        _event(
          id: 'ended',
          title: 'Ended',
          eventEnd: DateTime(2026, 10, 18),
        ).statusAt(now),
        EventStatus.ended,
      );
      expect(
        _event(
          id: 'season',
          title: 'Season',
          newSeasonUnknown: true,
        ).statusAt(now),
        EventStatus.newSeasonUnknown,
      );
      expect(
        _event(id: 'unknown', title: 'Unknown').statusAt(now),
        EventStatus.dateUnknown,
      );
    });

    test('computes deadline countdown without a stored status', () {
      final event = _event(
        id: 'countdown',
        title: 'Deadline',
        registrationDeadline: DateTime(2026, 10, 20),
      );

      expect(event.daysUntilDeadline(DateTime(2026, 10, 19, 12)), 2);
      expect(event.daysUntilDeadline(DateTime(2026, 10, 22)), 0);
      expect(event.countdownAt(DateTime(2026, 10, 22)), Duration.zero);
    });
  });

  group('EventCatalog filtering, search, and sorting', () {
    final now = DateTime(2026, 10, 19);
    final events = [
      _event(
        id: 'later',
        title: 'Cuộc thi Phân tích dữ liệu',
        type: 'Cuộc thi',
        careers: ['Data Analyst'],
        skills: ['SQL'],
        registrationDeadline: DateTime(2026, 11, 1),
        createdAt: DateTime(2026, 10, 12),
      ),
      _event(
        id: 'soon',
        title: 'Hội chợ việc làm',
        type: 'Hội chợ việc làm',
        careers: ['Business Analyst'],
        skills: ['Giao tiếp'],
        registrationDeadline: DateTime(2026, 10, 24),
        createdAt: DateTime(2026, 10, 18),
      ),
      _event(
        id: 'deadline-unknown',
        title: 'Workshop kỹ năng',
        type: 'Workshop',
      ),
    ];
    int match(EventItem event) => event.id == 'later'
        ? 88
        : event.id == 'soon'
        ? 45
        : 0;

    test('search ignores Vietnamese diacritics and filters dimensions', () {
      final filtered = EventCatalog.filterAndSort(
        events,
        now: now,
        filters: const EventSearchFilters(
          query: 'hoi cho',
          type: 'Hội chợ việc làm',
          career: 'Business Analyst',
          skill: 'Giao tiếp',
        ),
        matchPercent: match,
      );

      expect(filtered.map((event) => event.id), ['soon']);
    });

    test('sorts by deadline, career match, or newest', () {
      expect(
        EventCatalog.filterAndSort(
          events,
          now: now,
          filters: const EventSearchFilters(sort: EventSort.deadline),
          matchPercent: match,
        ).map((event) => event.id),
        ['soon', 'later', 'deadline-unknown'],
      );
      expect(
        EventCatalog.filterAndSort(
          events,
          now: now,
          filters: const EventSearchFilters(sort: EventSort.match),
          matchPercent: match,
        ).map((event) => event.id).first,
        'later',
      );
      expect(
        EventCatalog.filterAndSort(
          events,
          now: now,
          filters: const EventSearchFilters(sort: EventSort.newest),
          matchPercent: match,
        ).map((event) => event.id).first,
        'soon',
      );
    });

    test('fake repository exposes a live event stream', () async {
      final repository = FakeEventRepository(events);
      expect(await repository.fetchEvents(), events);
      expect(await repository.watchEvents().first, events);
    });
  });
}
