import '../config/it_fields.dart';
import '../models/mentor_model.dart';

enum MentorSort {
  goal,
  rating,
  soonest;

  String get label => switch (this) {
    MentorSort.goal => 'Hợp mục tiêu',
    MentorSort.rating => 'Đánh giá cao',
    MentorSort.soonest => 'Lịch trống sớm nhất',
  };
}

DateTime? _earliestSlot(Mentor mentor) => mentor.availableSlots.isEmpty
    ? null
    : (List<DateTime>.of(mentor.availableSlots)..sort()).first;

List<Mentor> filterAndSortMentors({
  required List<Mentor> mentors,
  String query = '',
  String? fieldId,
  String? targetFieldId,
  bool onlyAvailable = false,
  Set<String>? onlyIds,
  MentorSort sort = MentorSort.goal,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final filtered = mentors.where((mentor) {
    final matchesField = fieldId == '__goal__'
        ? targetFieldId != null && mentor.fieldIds.contains(targetFieldId)
        : fieldId == null || mentor.fieldIds.contains(fieldId);
    final matchesAvailability =
        !onlyAvailable || mentor.availableSlots.isNotEmpty;
    final matchesIds = onlyIds == null || onlyIds.contains(mentor.id);
    final searchable = [
      mentor.name,
      mentor.title,
      mentor.bio,
      ...mentor.topics.map((topic) => topic.label),
      ...mentor.fieldIds.map((id) => itFieldName(id) ?? id),
    ].join(' ').toLowerCase();
    final matchesQuery =
        normalizedQuery.isEmpty || searchable.contains(normalizedQuery);
    return matchesField && matchesAvailability && matchesIds && matchesQuery;
  }).toList();

  switch (sort) {
    case MentorSort.rating:
      filtered.sort(
        (first, second) => (second.rating ?? 0).compareTo(first.rating ?? 0),
      );
    case MentorSort.soonest:
      filtered.sort((first, second) {
        final a = _earliestSlot(first);
        final b = _earliestSlot(second);
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      });
    case MentorSort.goal:
      if (targetFieldId != null) {
        filtered.sort((first, second) {
          final firstMatches = first.fieldIds.contains(targetFieldId);
          final secondMatches = second.fieldIds.contains(targetFieldId);
          if (firstMatches == secondMatches) return 0;
          return firstMatches ? -1 : 1;
        });
      }
  }
  return List.unmodifiable(filtered);
}
