import '../config/gpa_conversion_config.dart';

enum GpaEntryMode { score10, letter }

class GpaCourse {
  const GpaCourse({
    required this.id,
    required this.name,
    required this.credits,
    required this.mode,
    required this.gradeValue,
    required this.createdAt,
    this.excludeFromGpa = false,
    this.isRetake = false,
  });

  final String id;
  final String name;
  final int credits;
  final GpaEntryMode mode;
  final double gradeValue;
  final DateTime createdAt;
  final bool excludeFromGpa;
  final bool isRetake;

  GpaGradeBand get gradeBand => mode == GpaEntryMode.score10
      ? gradeBandForScore10(gradeValue)
      : gradeBandForLabel(gpaGradeBands[gradeValue.toInt()].label);

  double get gradePoint => gradeBand.points;

  GpaCourse copyWith({
    String? id,
    String? name,
    int? credits,
    GpaEntryMode? mode,
    double? gradeValue,
    DateTime? createdAt,
    bool? excludeFromGpa,
    bool? isRetake,
  }) => GpaCourse(
    id: id ?? this.id,
    name: name ?? this.name,
    credits: credits ?? this.credits,
    mode: mode ?? this.mode,
    gradeValue: gradeValue ?? this.gradeValue,
    createdAt: createdAt ?? this.createdAt,
    excludeFromGpa: excludeFromGpa ?? this.excludeFromGpa,
    isRetake: isRetake ?? this.isRetake,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'credits': credits,
    'mode': mode.name,
    'gradeValue': gradeValue,
    'createdAt': createdAt.toIso8601String(),
    'excludeFromGpa': excludeFromGpa,
    'isRetake': isRetake,
  };

  factory GpaCourse.fromJson(Map<String, dynamic> json) => GpaCourse(
    id: json['id'] as String,
    name: json['name'] as String,
    credits: (json['credits'] as num).toInt(),
    mode: GpaEntryMode.values.byName(json['mode'] as String),
    gradeValue: (json['gradeValue'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    excludeFromGpa: json['excludeFromGpa'] as bool? ?? false,
    isRetake: json['isRetake'] as bool? ?? false,
  );
}

class GpaSemester {
  const GpaSemester({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.courses,
    this.isCompleted = false,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<GpaCourse> courses;
  final bool isCompleted;

  GpaSemester copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<GpaCourse>? courses,
    bool? isCompleted,
  }) => GpaSemester(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    courses: courses ?? this.courses,
    isCompleted: isCompleted ?? this.isCompleted,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'courses': courses.map((course) => course.toJson()).toList(),
    'isCompleted': isCompleted,
  };

  factory GpaSemester.fromJson(Map<String, dynamic> json) => GpaSemester(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    courses: (json['courses'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GpaCourse.fromJson)
        .toList(growable: false),
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

class GpaSnapshot {
  const GpaSnapshot({
    required this.currentGpa,
    required this.previousSemesterGpa,
    required this.earnedCredits,
    required this.gpaCredits,
    required this.semesterGpas,
    required this.cumulativeGpas,
    required this.countedCourses,
  });

  final double currentGpa;
  final double? previousSemesterGpa;
  final int earnedCredits;
  final int gpaCredits;
  final List<double?> semesterGpas;
  final List<double?> cumulativeGpas;
  final List<GpaCourse> countedCourses;

  double? get semesterChange =>
      previousSemesterGpa == null ? null : currentGpa - previousSemesterGpa!;

  static GpaSnapshot fromSemesters(List<GpaSemester> semesters) {
    final ordered = [...semesters]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final attempts = <String, List<(GpaCourse, String, DateTime)>>{};
    List<(GpaCourse, String, DateTime)> activeAttempts() {
      final active = <(GpaCourse, String, DateTime)>[];
      for (final group in attempts.values) {
        if (group.any((attempt) => attempt.$1.isRetake)) {
          final sorted = [...group]
            ..sort((a, b) {
              final semesterOrder = a.$3.compareTo(b.$3);
              return semesterOrder != 0
                  ? semesterOrder
                  : a.$1.createdAt.compareTo(b.$1.createdAt);
            });
          active.add(sorted.last);
        } else {
          active.addAll(group);
        }
      }
      return active;
    }

    final semesterGpas = <double?>[];
    final cumulativeGpas = <double?>[];
    for (final semester in ordered) {
      for (final course in semester.courses) {
        if (course.excludeFromGpa || course.name.trim().isEmpty) continue;
        final key = course.name.trim().toLowerCase();
        attempts.putIfAbsent(key, () => []).add((
          course,
          semester.id,
          semester.createdAt,
        ));
      }
      final active = activeAttempts();
      semesterGpas.add(
        _weightedAverage(
          active
              .where((attempt) => attempt.$2 == semester.id)
              .map((attempt) => attempt.$1),
        ),
      );
      cumulativeGpas.add(_weightedAverage(active.map((attempt) => attempt.$1)));
    }
    final counted = activeAttempts()
        .map((attempt) => attempt.$1)
        .toList(growable: false);
    final totalCredits = counted.fold<int>(0, (sum, c) => sum + c.credits);
    final earnedCredits = counted
        .where((course) => course.gradePoint > 0)
        .fold<int>(0, (sum, course) => sum + course.credits);
    final totalQuality = counted.fold<double>(
      0,
      (sum, c) => sum + c.gradePoint * c.credits,
    );
    final currentGpa = totalCredits == 0 ? 0.0 : totalQuality / totalCredits;

    final previous = cumulativeGpas.length >= 2
        ? cumulativeGpas[cumulativeGpas.length - 2]
        : null;
    return GpaSnapshot(
      currentGpa: currentGpa,
      previousSemesterGpa: previous,
      earnedCredits: earnedCredits,
      gpaCredits: totalCredits,
      semesterGpas: List.unmodifiable(semesterGpas),
      cumulativeGpas: List.unmodifiable(cumulativeGpas),
      countedCourses: List.unmodifiable(counted),
    );
  }

  static double? _weightedAverage(Iterable<GpaCourse> courses) {
    var credits = 0;
    var quality = 0.0;
    for (final course in courses) {
      credits += course.credits;
      quality += course.gradePoint * course.credits;
    }
    return credits == 0 ? null : quality / credits;
  }
}

double? requiredGpaAverage({
  required double currentGpa,
  required int earnedCredits,
  required int gpaCredits,
  required int programCredits,
  required double targetGpa,
}) {
  final remaining = programCredits - earnedCredits;
  if (remaining <= 0) return null;
  return (targetGpa * (gpaCredits + remaining) - currentGpa * gpaCredits) /
      remaining;
}
