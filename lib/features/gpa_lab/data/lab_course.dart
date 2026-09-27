class LabCourse {
  final String id;
  final String name;
  final int credits;

  double? gradePoint;

  LabCourse({
    required this.id,
    required this.name,
    required this.credits,
    this.gradePoint,
  });
}
