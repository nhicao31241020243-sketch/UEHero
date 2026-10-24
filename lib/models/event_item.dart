import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';

class EventItem {
  const EventItem({
    this.id = '',
    required this.title,
    required this.organizer,
    this.type = 'Sự kiện',
    this.organizerLogoUrl,
    this.sponsorLogoUrls = const [],
    this.relatedCareers = const [],
    this.skills = const [],
    this.posterUrl,
    this.registrationOpen,
    this.registrationDeadline,
    this.eventStart,
    this.eventEnd,
    this.format,
    this.audience,
    this.location,
    this.participationUrl,
    this.statusNote,
    this.previousSeason,
    this.officialUrl,
    this.sourceUrl,
    this.verifiedAt,
    this.needsVerification = false,
    this.createdAt,
    this.updatedAt,
    this.description = '',
    this.timeline,
    this.isNewSeasonUnknown = false,
    this.isRecurring = false,
    this.notes,
    this.trainingPoints = 10,
    this.image,
    this.tag = '',
  });

  final String id;
  final String title;
  final String organizer;
  final String type;
  final String? organizerLogoUrl;
  final List<String> sponsorLogoUrls;
  final List<String> relatedCareers;
  final List<String> skills;
  final String? posterUrl;
  final DateTime? registrationOpen;
  final DateTime? registrationDeadline;
  final DateTime? eventStart;
  final DateTime? eventEnd;
  final String? format;
  final String? audience;
  final String? location;
  final String? participationUrl;
  final String? statusNote;
  final String? previousSeason;
  final String? officialUrl;
  final String? sourceUrl;
  final DateTime? verifiedAt;
  final bool needsVerification;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String description;
  final String? timeline;
  final bool isNewSeasonUnknown;
  final bool isRecurring;
  final String? notes;
  final int trainingPoints;
  final String? image;
  final String tag;

  List<String> get careerTags => relatedCareers;
  String? get imageUrl => posterUrl ?? image;
  String? get lastSeason => previousSeason;
  String? get linkUrl => participationUrl;

  factory EventItem.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    DateTime? date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    String? text(dynamic value) =>
        value is String && value.trim().isNotEmpty ? value.trim() : null;

    return EventItem(
      id: text(data['id']) ?? documentId,
      title: text(data['title']) ?? text(data['name']) ?? '',
      organizer: text(data['organizer']) ?? '',
      type: text(data['type']) ?? text(data['category']) ?? 'Sự kiện',
      organizerLogoUrl: text(data['organizerLogoUrl']),
      sponsorLogoUrls: _strings(data['sponsorLogoUrls']),
      relatedCareers: _strings(data['relatedCareers'] ?? data['careerTags']),
      skills: _strings(data['skills']),
      posterUrl: text(data['posterUrl'] ?? data['imageUrl']),
      registrationOpen: date(data['registrationOpen']),
      registrationDeadline: date(data['registrationDeadline']),
      eventStart: date(data['eventStart']),
      eventEnd: date(data['eventEnd']),
      format: text(data['format']),
      audience: text(data['audience']),
      location: text(data['location']),
      participationUrl: text(data['participationUrl']),
      statusNote: text(data['statusNote']),
      previousSeason: text(data['previousSeason'] ?? data['lastSeason']),
      officialUrl: text(data['officialUrl']),
      sourceUrl: text(data['sourceUrl']),
      verifiedAt: date(data['verifiedAt']),
      needsVerification: data['needsVerification'] as bool? ?? false,
      createdAt: date(data['createdAt']),
      updatedAt: date(data['updatedAt']),
      description: text(data['description']) ?? '',
      timeline: text(data['timeline']),
      isNewSeasonUnknown: data['isNewSeasonUnknown'] as bool? ?? false,
      isRecurring: data['isRecurring'] as bool? ?? false,
      notes: text(data['notes']),
      trainingPoints: (data['trainingPoints'] as num?)?.toInt() ?? 10,
    );
  }

  factory EventItem.fromMap(Map<String, dynamic> data) =>
      EventItem.fromFirestore(
        data['id'] is String ? data['id'] as String : '',
        data,
      );

  static List<String> _strings(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  EventStatus statusAt(DateTime now) {
    if (isNewSeasonUnknown) return EventStatus.newSeasonUnknown;

    if (registrationOpen == null &&
        registrationDeadline == null &&
        eventStart == null &&
        eventEnd == null) {
      return EventStatus.dateUnknown;
    }

    final opening = registrationOpen;
    if (opening != null && now.isBefore(opening)) {
      return EventStatus.openingSoon;
    }

    final deadline = registrationDeadline;
    if (deadline != null && !now.isAfter(_endOfDay(deadline))) {
      return EventStatus.registrationOpen;
    }

    if (eventEnd != null && now.isAfter(eventEnd!)) {
      return EventStatus.ended;
    }
    if (eventStart != null && now.isBefore(eventStart!)) {
      return EventStatus.closedUpcoming;
    }
    if (deadline != null && now.isAfter(_endOfDay(deadline))) {
      return eventEnd != null && now.isBefore(eventEnd!)
          ? EventStatus.closedUpcoming
          : EventStatus.ended;
    }
    if (eventEnd != null && !now.isAfter(eventEnd!)) {
      return EventStatus.closedUpcoming;
    }
    return EventStatus.ended;
  }

  Duration? countdownAt(DateTime now) {
    final deadline = registrationDeadline;
    if (deadline == null) return null;
    final end = _endOfDay(deadline);
    if (now.isAfter(end)) return Duration.zero;
    return end.difference(now);
  }

  int? daysUntilDeadline(DateTime now) {
    final remaining = countdownAt(now);
    if (remaining == null) return null;
    if (remaining == Duration.zero) return 0;
    return (remaining.inHours / 24).ceil();
  }

  static DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}

enum EventStatus {
  registrationOpen,
  openingSoon,
  closedUpcoming,
  ended,
  newSeasonUnknown,
  dateUnknown,
}

enum EventSort { deadline, match, newest }

class EventSearchFilters {
  const EventSearchFilters({
    this.query = '',
    this.type,
    this.career,
    this.skill,
    this.status,
    this.from,
    this.to,
    this.format,
    this.sort = EventSort.deadline,
  });

  final String query;
  final String? type;
  final String? career;
  final String? skill;
  final EventStatus? status;
  final DateTime? from;
  final DateTime? to;
  final String? format;
  final EventSort sort;
}

class EventCatalog {
  const EventCatalog._();

  static List<EventItem> filterAndSort(
    Iterable<EventItem> events, {
    required DateTime now,
    required EventSearchFilters filters,
    required int Function(EventItem event) matchPercent,
  }) {
    final query = _normalize(filters.query.trim());
    final result = events.where((event) {
      if (query.isNotEmpty && !_searchableText(event).contains(query)) {
        return false;
      }
      if (filters.type != null &&
          _normalize(event.type) != _normalize(filters.type!)) {
        return false;
      }
      if (filters.career != null &&
          !event.relatedCareers.any(
            (career) => _normalize(career) == _normalize(filters.career!),
          )) {
        return false;
      }
      if (filters.skill != null &&
          !event.skills.any(
            (skill) => _normalize(skill) == _normalize(filters.skill!),
          )) {
        return false;
      }
      if (filters.status != null && event.statusAt(now) != filters.status) {
        return false;
      }
      if (filters.format != null &&
          _normalize(event.format ?? '') != _normalize(filters.format!)) {
        return false;
      }
      final relevantDate = event.registrationDeadline ?? event.eventStart;
      if (filters.from != null &&
          (relevantDate == null || relevantDate.isBefore(filters.from!))) {
        return false;
      }
      if (filters.to != null &&
          (relevantDate == null || relevantDate.isAfter(filters.to!))) {
        return false;
      }
      return true;
    }).toList();

    switch (filters.sort) {
      case EventSort.deadline:
        result.sort((a, b) {
          final aDate = a.registrationDeadline ?? DateTime(9999);
          final bDate = b.registrationDeadline ?? DateTime(9999);
          final compared = aDate.compareTo(bDate);
          return compared == 0 ? a.title.compareTo(b.title) : compared;
        });
      case EventSort.match:
        result.sort((a, b) => matchPercent(b).compareTo(matchPercent(a)));
      case EventSort.newest:
        result.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(0);
          final bDate = b.createdAt ?? DateTime(0);
          return bDate.compareTo(aDate);
        });
    }
    return result;
  }

  static String _searchableText(EventItem event) => _normalize(
    [
      event.title,
      event.organizer,
      event.type,
      event.description,
      event.location ?? '',
      ...event.relatedCareers,
      ...event.skills,
    ].join(' '),
  );

  static String _normalize(String value) =>
      removeDiacritics(value).replaceAll('đ', 'd').toLowerCase();
}
