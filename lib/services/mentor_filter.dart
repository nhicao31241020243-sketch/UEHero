import '../config/it_fields.dart';
import '../models/mentor_model.dart';

List<Mentor> filterAndSortMentors({
  required List<Mentor> mentors,
  String query = '',
  String? fieldId,
  String? targetFieldId,
  bool onlyAvailable = false,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final filtered = mentors.where((mentor) {
    final matchesField = fieldId == '__goal__'
        ? targetFieldId != null && mentor.fieldIds.contains(targetFieldId)
        : fieldId == null || mentor.fieldIds.contains(fieldId);
    final matchesAvailability =
        !onlyAvailable || mentor.availableSlots.isNotEmpty;
    final searchable = [
      mentor.name,
      mentor.title,
      mentor.bio,
      ...mentor.topics.map((topic) => topic.label),
      ...mentor.fieldIds.map((id) => itFieldName(id) ?? id),
    ].join(' ').toLowerCase();
    final matchesQuery =
        normalizedQuery.isEmpty || searchable.contains(normalizedQuery);
    return matchesField && matchesAvailability && matchesQuery;
  }).toList();

  if (targetFieldId != null) {
    filtered.sort((first, second) {
      final firstMatches = first.fieldIds.contains(targetFieldId);
      final secondMatches = second.fieldIds.contains(targetFieldId);
      if (firstMatches == secondMatches) return 0;
      return firstMatches ? -1 : 1;
    });
  }
  return List.unmodifiable(filtered);
}
