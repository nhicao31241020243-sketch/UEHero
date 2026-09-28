import '../gpa_tracker/logic/gpa_calculator.dart';

/// Demo grade scale, not a statement about UEH's official regulations.
class StudioGrade {
  final String label;
  final int units;
  const StudioGrade(this.label, this.units);
  double get point => units / 100;

  static const values = <StudioGrade>[
    StudioGrade('F', 0),
    StudioGrade('D', 100),
    StudioGrade('D+', 150),
    StudioGrade('C', 200),
    StudioGrade('C+', 250),
    StudioGrade('B', 300),
    StudioGrade('B+', 350),
    StudioGrade('A-', 370),
    StudioGrade('A', 400),
  ];

  static StudioGrade fromUnits(int units) => values.firstWhere(
    (g) => g.units == units,
    orElse: () =>
        throw ArgumentError.value(units, 'units', 'Unknown demo grade'),
  );

  static StudioGrade nearest(double point) {
    if (!point.isFinite) {
      throw ArgumentError.value(point, 'point');
    }
    var best = values.first;
    for (final grade in values.skip(1)) {
      if ((grade.point - point).abs() < (best.point - point).abs())
        best = grade;
    }
    return best;
  }
}

class StudioCourse {
  final String id;
  final String name;
  final String code;
  final int credits;
  final int colorValue;
  const StudioCourse({
    required this.id,
    required this.name,
    required this.code,
    required this.credits,
    required this.colorValue,
  });
}

class ACreditPlan {
  final int credits;
  final List<String> courseIds;
  ACreditPlan(this.credits, Iterable<String> ids)
    : courseIds = List<String>.unmodifiable(ids);
}

/// Immutable scenario. Grades/quality points are stored in hundredths.
/// Decisions compare integers; rounding is exclusively for display.
class StudioScenario {
  final int completedCredits;
  final int completedQualityUnits;
  final int targetUnits;
  final List<StudioCourse> courses;
  final Map<String, int> grades;

  StudioScenario({
    required this.completedCredits,
    required this.completedQualityUnits,
    required this.targetUnits,
    required Iterable<StudioCourse> courses,
    Map<String, int> grades = const {},
  }) : courses = List<StudioCourse>.unmodifiable(courses),
       grades = Map<String, int>.unmodifiable(grades) {
    if (completedCredits < 0 ||
        completedQualityUnits < 0 ||
        completedQualityUnits > completedCredits * 400) {
      throw ArgumentError('Invalid completed credit/quality-point totals');
    }
    if (targetUnits < 200 || targetUnits > 400) {
      throw ArgumentError('Target must be between 2.00 and 4.00');
    }
    final ids = <String>{};
    for (final c in this.courses) {
      if (c.id.isEmpty || c.name.isEmpty || c.credits <= 0 || !ids.add(c.id)) {
        throw ArgumentError('Courses need unique IDs and positive credits');
      }
    }
    if (this.courses.isEmpty) throw ArgumentError('A term needs a course');
    for (final entry in this.grades.entries) {
      if (!ids.contains(entry.key))
        throw ArgumentError('Unknown course: ${entry.key}');
      StudioGrade.fromUnits(entry.value);
    }
  }

  static const demoCourses = <StudioCourse>[
    StudioCourse(
      id: 'ai_project',
      name: 'Dự án A.I.',
      code: 'AI',
      credits: 3,
      colorValue: 0xFF9A4358,
    ),
    StudioCourse(
      id: 'internship',
      name: 'Kiến tập - TI',
      code: 'TI',
      credits: 5,
      colorValue: 0xFFF4AE73,
    ),
    StudioCourse(
      id: 'mobile_dev',
      name: 'Lập trình di động',
      code: 'MB',
      credits: 3,
      colorValue: 0xFF579886,
    ),
    StudioCourse(
      id: 'database',
      name: 'Cơ sở dữ liệu',
      code: 'DB',
      credits: 3,
      colorValue: 0xFF6D91AD,
    ),
    StudioCourse(
      id: 'testing',
      name: 'Kiểm thử phần mềm',
      code: 'QA',
      credits: 3,
      colorValue: 0xFF8977AA,
    ),
    StudioCourse(
      id: 'uiux',
      name: 'Thiết kế UI/UX',
      code: 'UX',
      credits: 3,
      colorValue: 0xFFE47754,
    ),
  ];

  factory StudioScenario.demo() => StudioScenario(
    completedCredits: 77,
    completedQualityUnits: 26719,
    targetUnits: 350,
    courses: demoCourses,
    grades: const {
      'ai_project': 350,
      'internship': 350,
      'mobile_dev': 400,
      'database': 300,
      'testing': 350,
      'uiux': 400,
    },
  );

  double get currentGpa => completedCredits == 0
      ? 0
      : completedQualityUnits / (100 * completedCredits);
  double get target => targetUnits / 100;
  int get totalFutureCredits => courses.fold<int>(0, (n, c) => n + c.credits);
  int get plannedCredits => courses
      .where((c) => grades.containsKey(c.id))
      .fold<int>(0, (n, c) => n + c.credits);
  int get unplannedCredits => totalFutureCredits - plannedCredits;
  int get futureQualityUnits =>
      courses.fold<int>(0, (n, c) => n + c.credits * (grades[c.id] ?? 0));
  int get plannedCount => grades.length;
  bool get isComplete => plannedCount == courses.length;
  int get finalCredits => completedCredits + totalFutureCredits;

  /// Reuses the project's credit-weighted calculator. Unplanned is not F.
  double get projectedGpa => GpaCalculator.projectedGpa(
    currentGpa: currentGpa,
    completedCredits: completedCredits,
    futureCourses: [
      for (final c in courses)
        if (grades.containsKey(c.id))
          FutureCourseResult(
            credits: c.credits,
            gradePoint: grades[c.id]! / 100,
          ),
    ],
  );

  /// Completion bounds holding the currently assigned grades fixed.
  double get termFloor =>
      (completedQualityUnits + futureQualityUnits) / (100 * finalCredits);
  double get termCeilingWithPlan =>
      (completedQualityUnits + futureQualityUnits + unplannedCredits * 400) /
      (100 * finalCredits);
  double get allACeiling =>
      (completedQualityUnits + totalFutureCredits * 400) / (100 * finalCredits);
  double get requiredWholeTermMean =>
      (targetUnits * finalCredits - completedQualityUnits) /
      (100 * totalFutureCredits);
  double? get requiredUnplannedMean => unplannedCredits == 0
      ? null
      : (targetUnits * finalCredits -
                completedQualityUnits -
                futureQualityUnits) /
            (100 * unplannedCredits);

  bool get targetPossibleFromBase =>
      completedQualityUnits + totalFutureCredits * 400 >=
      targetUnits * finalCredits;
  bool get targetPossibleWithPlan =>
      completedQualityUnits + futureQualityUnits + unplannedCredits * 400 >=
      targetUnits * finalCredits;
  bool get fullScenarioMeetsTarget =>
      isComplete &&
      completedQualityUnits + futureQualityUnits >= targetUnits * finalCredits;

  StudioCourse course(String id) => courses.firstWhere(
    (c) => c.id == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'Unknown course'),
  );

  StudioScenario copy({Map<String, int>? grades, int? targetUnits}) =>
      StudioScenario(
        completedCredits: completedCredits,
        completedQualityUnits: completedQualityUnits,
        targetUnits: targetUnits ?? this.targetUnits,
        courses: courses,
        grades: grades ?? this.grades,
      );

  StudioScenario setGrade(String id, int? units) {
    course(id);
    final next = Map<String, int>.of(grades);
    if (units == null) {
      next.remove(id);
    } else {
      StudioGrade.fromUnits(units);
      next[id] = units;
    }
    return copy(grades: next);
  }

  /// Smallest feasible whole-course bundle at A, all other courses at B+.
  /// This is an alternate full-term scenario, not an edit of the current plan.
  ACreditPlan? get minimumACreditPlan {
    if (!targetPossibleFromBase) {
      return null;
    }
    final reachable = <int, List<String>>{0: <String>[]};
    for (final c in courses) {
      final before = Map<int, List<String>>.of(reachable);
      for (final e in before.entries) {
        reachable.putIfAbsent(e.key + c.credits, () => [...e.value, c.id]);
      }
    }
    final totals = reachable.keys.toList()..sort();
    for (final aCredits in totals) {
      final units =
          completedQualityUnits + totalFutureCredits * 350 + aCredits * 50;
      if (units >= targetUnits * finalCredits) {
        return ACreditPlan(aCredits, reachable[aCredits]!);
      }
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'schema': 'uehero.gpa-studio.v3',
    'syntheticDemo': true,
    'gradeScale': {for (final g in StudioGrade.values) g.label: g.point},
    'completedCredits': completedCredits,
    'completedQualityUnits': completedQualityUnits,
    'targetUnits': targetUnits,
    'courses': [
      for (final c in courses)
        {
          'id': c.id,
          'name': c.name,
          'code': c.code,
          'credits': c.credits,
          'gradeUnits': grades[c.id],
        },
    ],
    'partialProjectedGpa': projectedGpa,
    'plannedCredits': plannedCredits,
    'termRange': [termFloor, termCeilingWithPlan],
  };
}
