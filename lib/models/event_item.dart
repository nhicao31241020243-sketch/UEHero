class EventItem {
  final String id;
  final String title;
  final String organizer;
  final String type;
  final List<String> careerTags;
  final List<String> skills;
  final DateTime? registrationOpen;
  final DateTime? registrationDeadline;
  final DateTime? eventStart;
  final DateTime? eventEnd;
  final String? location;
  final String? fee;
  final String? officialUrl;
  final String? sourceUrl;
  final String? imageUrl;
  final String? lastSeason;
  final bool isRecurring;
  final String? notes;
  final DateTime? verifiedAt;

  // Kept for the legacy points screen and old event data.
  final String? image;
  final String tag;
  final int trainingPoints;
  final String description;

  const EventItem({
    this.id = '',
    required this.title,
    required this.organizer,
    this.type = '',
    this.careerTags = const [],
    this.skills = const [],
    this.registrationOpen,
    this.registrationDeadline,
    this.eventStart,
    this.eventEnd,
    this.location,
    this.fee,
    this.officialUrl,
    this.sourceUrl,
    this.imageUrl,
    this.lastSeason,
    this.isRecurring = false,
    this.notes,
    this.verifiedAt,
    this.image,
    this.tag = '',
    this.trainingPoints = 0,
    this.description = '',
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    DateTime? date(dynamic value) =>
        value is String ? DateTime.tryParse(value) : null;

    return EventItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      organizer: json['organizer'] as String? ?? '',
      type: json['type'] as String? ?? '',
      careerTags: _strings(json['careerTags']),
      skills: _strings(json['skills']),
      registrationOpen: date(json['registrationOpen']),
      registrationDeadline: date(json['registrationDeadline']),
      eventStart: date(json['eventStart']),
      eventEnd: date(json['eventEnd']),
      location: json['location'] as String?,
      fee: json['fee'] as String?,
      officialUrl: json['officialUrl'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      lastSeason: json['lastSeason'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      notes: json['notes'] as String?,
      verifiedAt: date(json['verifiedAt']),
    );
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  EventStatus statusAt(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final deadline = registrationDeadline == null
        ? null
        : DateTime(
            registrationDeadline!.year,
            registrationDeadline!.month,
            registrationDeadline!.day,
            23,
            59,
            59,
          );
    if (registrationOpen != null && today.isBefore(registrationOpen!)) {
      return EventStatus.openingSoon;
    }
    if (deadline != null && !now.isAfter(deadline)) {
      return EventStatus.registrationOpen;
    }
    if (isRecurring &&
        registrationOpen == null &&
        registrationDeadline == null &&
        eventStart == null &&
        eventEnd == null) {
      return EventStatus.newSeasonUnknown;
    }
    if (eventEnd != null && now.isAfter(eventEnd!)) {
      return EventStatus.ended;
    }
    if ((deadline != null && now.isAfter(deadline)) &&
        (eventStart == null || !now.isBefore(eventStart!))) {
      return EventStatus.ended;
    }
    if (deadline != null && now.isAfter(deadline)) {
      return EventStatus.closedUpcoming;
    }
    if (eventStart != null && now.isBefore(eventStart!)) {
      return EventStatus.closedUpcoming;
    }
    if (eventEnd == null && deadline != null && now.isAfter(deadline)) {
      return EventStatus.ended;
    }
    return EventStatus.ended;
  }
}

enum EventStatus {
  openingSoon,
  registrationOpen,
  closedUpcoming,
  ended,
  newSeasonUnknown,
}
