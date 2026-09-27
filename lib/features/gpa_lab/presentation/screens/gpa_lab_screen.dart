import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../gpa_tracker/logic/gpa_calculator.dart';
import '../../data/anonymized_courses.dart';
import '../../data/lab_course.dart';

class GpaLabScreen extends StatefulWidget {
  const GpaLabScreen({super.key});

  @override
  State<GpaLabScreen> createState() => _GpaLabScreenState();
}

class _GpaLabScreenState extends State<GpaLabScreen> {
  static const double currentGpa = 3.47;
  static const int completedCredits = 77;
  static const double targetGpa = 3.50;

  static const Map<String, double> gradeZones = {
    'B': 3.0,
    'B+': 3.5,
    'A-': 3.7,
    'A': 4.0,
  };

  final Map<String, double> assignedGrades = {};

  String? lastCourseName;
  String? lastGradeLabel;
  double? lastImpact;

  double _calculateProjected(Map<String, double> grades) {
    final futureCourses = labCourses
        .where((course) => grades.containsKey(course.id))
        .map(
          (course) => FutureCourseResult(
            credits: course.credits,
            gradePoint: grades[course.id]!,
          ),
        )
        .toList();

    if (futureCourses.isEmpty) {
      return currentGpa;
    }

    return GpaCalculator.projectedGpa(
      currentGpa: currentGpa,
      completedCredits: completedCredits,
      futureCourses: futureCourses,
    );
  }

  double get projectedGpa => _calculateProjected(assignedGrades);

  void _assignGrade(LabCourse course, String gradeLabel, double grade) {
    final before = projectedGpa;

    final nextGrades = Map<String, double>.from(assignedGrades)
      ..[course.id] = grade;

    final after = _calculateProjected(nextGrades);

    setState(() {
      assignedGrades[course.id] = grade;
      lastCourseName = course.name;
      lastGradeLabel = gradeLabel;
      lastImpact = after - before;
    });
  }

  void _resetLab() {
    setState(() {
      assignedGrades.clear();
      lastCourseName = null;
      lastGradeLabel = null;
      lastImpact = null;
    });
  }

  List<LabCourse> _coursesForGrade(double grade) {
    return labCourses
        .where((course) => assignedGrades[course.id] == grade)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final projected = projectedGpa;
    final reachedTarget = projected >= targetGpa;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPA Physics Lab',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Thả môn học vào mức điểm bạn kỳ vọng',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _resetLab,
                    tooltip: 'Reset',
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Academic truth layer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: _Metric(
                        label: 'CURRENT',
                        value: '3.47',
                        muted: true,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 42,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          const Text(
                            'PROJECTED',
                            style: TextStyle(
                              color: AppColors.brandSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 0.92,
                                    end: 1.0,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              projected.toStringAsFixed(2),
                              key: ValueKey(projected.toStringAsFixed(3)),
                              style: TextStyle(
                                color: reachedTarget
                                    ? AppColors.success
                                    : AppColors.brandSoft,
                                fontSize: 33,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 42,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                    const Expanded(
                      child: _Metric(
                        label: 'TARGET',
                        value: '3.50',
                        muted: true,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.40),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _GraphiteTablePainter()),
                    ),

                    // Subtle recessed inner edge
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(29),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.035),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Positioned(
                      left: 22,
                      top: 20,
                      child: Text(
                        'COURSES',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    // Free pucks / course tray
                    Positioned(
                      left: 24,
                      right: 24,
                      top: 52,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: labCourses
                            .where(
                              (course) =>
                                  !assignedGrades.containsKey(course.id),
                            )
                            .map((course) => _CoursePuck(course: course))
                            .toList(),
                      ),
                    ),

                    // Small center cue: the empty space is intentional
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 196,
                      child: IgnorePointer(
                        child: Column(
                          children: [
                            Icon(
                              Icons.south_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PHYSICS FIELD',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.08),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Grade wells
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 66,
                      child: Row(
                        children: gradeZones.entries.map((entry) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: _GradeWell(
                                label: entry.key,
                                grade: entry.value,
                                courses: _coursesForGrade(entry.value),
                                onAccept: (course) {
                                  _assignGrade(course, entry.key, entry.value);
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Impact strip
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: lastCourseName == null
                            ? Text(
                                'Kéo một môn vào hốc điểm để mô phỏng GPA',
                                key: const ValueKey('empty'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.58,
                                  ),
                                  fontSize: 11,
                                ),
                              )
                            : Row(
                                key: ValueKey(
                                  '$lastCourseName-$lastGradeLabel',
                                ),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$lastCourseName → $lastGradeLabel',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${(lastImpact ?? 0) >= 0 ? '+' : ''}'
                                    '${(lastImpact ?? 0).toStringAsFixed(3)} GPA',
                                    style: TextStyle(
                                      color: (lastImpact ?? 0) >= 0
                                          ? AppColors.success
                                          : AppColors.warning,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;
  final bool alignEnd;

  const _Metric({
    required this.label,
    required this.value,
    this.muted = false,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.72),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: muted
                ? AppColors.textPrimary.withValues(alpha: 0.72)
                : AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CoursePuck extends StatelessWidget {
  final LabCourse course;
  final bool compact;

  const _CoursePuck({required this.course, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final baseSize = course.credits >= 5 ? 94.0 : 82.0;
    final size = compact ? baseSize * 0.55 : baseSize;

    Widget buildPuck() {
      return SizedBox(
        width: size,
        height: size + (compact ? 3 : 6),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Netflix-red emissive lower rim
            Positioned(
              top: compact ? 3 : 6,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF5C070C),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(
                        alpha: compact ? 0.13 : 0.18,
                      ),
                      blurRadius: compact ? 8 : 16,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.62),
                      blurRadius: compact ? 9 : 18,
                      offset: Offset(0, compact ? 5 : 11),
                    ),
                  ],
                ),
              ),
            ),

            // Ceramic top
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.38, -0.42),
                  radius: 1.05,
                  colors: [
                    Color(0xFF3A3A3E),
                    Color(0xFF202023),
                    Color(0xFF111113),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: compact ? 0.22 : 0.34),
                  width: compact ? 1.0 : 1.35,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(compact ? 4 : 9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      course.name,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: compact ? 7 : 11,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: compact ? 1 : 4),
                    Text(
                      '${course.credits} TC',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: compact ? 6 : 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tiny top edge highlight
            Positioned(
              top: 5,
              child: Container(
                width: size * 0.43,
                height: compact ? 1 : 1.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final puck = buildPuck();

    return Draggable<LabCourse>(
      data: course,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.06, child: puck),
      ),
      childWhenDragging: Opacity(opacity: 0.12, child: puck),
      child: puck,
    );
  }
}

class _GradeWell extends StatefulWidget {
  final String label;
  final double grade;
  final List<LabCourse> courses;
  final ValueChanged<LabCourse> onAccept;

  const _GradeWell({
    required this.label,
    required this.grade,
    required this.courses,
    required this.onAccept,
  });

  @override
  State<_GradeWell> createState() => _GradeWellState();
}

class _GradeWellState extends State<_GradeWell> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final gradeBrightness = ((widget.grade - 3.0) / 1.0).clamp(0.0, 1.0);

    return DragTarget<LabCourse>(
      onWillAcceptWithDetails: (_) {
        setState(() => hovering = true);
        return true;
      },
      onLeave: (_) {
        setState(() => hovering = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => hovering = false);
        widget.onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF08080A),
                border: Border.all(
                  color: hovering
                      ? AppColors.brand
                      : Colors.white.withValues(
                          alpha: 0.08 + (gradeBrightness * 0.05),
                        ),
                  width: hovering ? 2 : 1,
                ),
                boxShadow: [
                  // Deep outer rim
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.82),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                  if (hovering)
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.26),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.25),
                    radius: 0.88,
                    colors: [
                      const Color(0xFF050506),
                      Color.lerp(
                        const Color(0xFF111114),
                        AppColors.brand.withValues(alpha: 0.18),
                        gradeBrightness * 0.28,
                      )!,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.035),
                  ),
                ),
                child: Center(
                  child: widget.courses.isEmpty
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              style: TextStyle(
                                color: hovering
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimary.withValues(
                                        alpha: 0.80,
                                      ),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              widget.grade.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        )
                      : Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 1,
                          runSpacing: 1,
                          children: widget.courses
                              .map(
                                (course) =>
                                    _CoursePuck(course: course, compact: true),
                              )
                              .toList(),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.label,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.70),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GraphiteTablePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final tablePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A1D), Color(0xFF111113), Color(0xFF08080A)],
        stops: [0.0, 0.52, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, tablePaint);

    // Directional light from the upper-left, not a central orb.
    final lightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.75, -0.85),
        radius: 0.85,
        colors: [Colors.white.withValues(alpha: 0.045), Colors.transparent],
      ).createShader(rect);

    canvas.drawRect(rect, lightPaint);

    // Very subtle UEHero edge light from the bottom.
    final edgeLightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, AppColors.brand.withValues(alpha: 0.028)],
        stops: const [0.62, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, edgeLightPaint);

    // Matte micro-grid: nearly invisible, only to establish a plane.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.012)
      ..strokeWidth = 1;

    const spacing = 42.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
