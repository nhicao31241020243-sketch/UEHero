import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/gpa_lab/game/gpa_physics_game.dart';
import 'features/gpa_tracker/logic/gpa_calculator.dart';

void main() {
  runApp(const GpaForgePreviewApp());
}

class GpaForgePreviewApp extends StatefulWidget {
  const GpaForgePreviewApp({super.key});

  @override
  State<GpaForgePreviewApp> createState() => _GpaForgePreviewAppState();
}

class _GpaForgePreviewAppState extends State<GpaForgePreviewApp> {
  static const double currentGpa = 3.47;
  static const int completedCredits = 77;
  static const double targetGpa = 3.50;

  static const Map<String, String> courseNames = {
    'ai_project': 'Dự án A.I.',
    'internship': 'Kiến tập - TI',
  };

  late final GpaPhysicsGame game;

  final Map<String, _CommittedGrade> committedGrades = {};

  String? lastAction;
  double? lastImpact;

  @override
  void initState() {
    super.initState();

    game = GpaPhysicsGame(
      onGradeCommitted: (courseId, credits, gradeLabel, gradePoint) {
        if (!mounted) return;

        final before = projectedGpa;

        setState(() {
          committedGrades[courseId] = _CommittedGrade(
            credits: credits,
            gradeLabel: gradeLabel,
            gradePoint: gradePoint,
          );

          final after = projectedGpa;

          lastAction = '${courseNames[courseId] ?? courseId} → $gradeLabel';

          lastImpact = after - before;
        });

        final after = projectedGpa;

        if (before < targetGpa && after >= targetGpa) {
          HapticFeedback.heavyImpact();
        }
      },
    );
  }

  double get projectedGpa {
    if (committedGrades.isEmpty) {
      return currentGpa;
    }

    return GpaCalculator.projectedGpa(
      currentGpa: currentGpa,
      completedCredits: completedCredits,
      futureCourses: committedGrades.values
          .map(
            (grade) => FutureCourseResult(
              credits: grade.credits,
              gradePoint: grade.gradePoint,
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projected = projectedGpa;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: Scaffold(
        backgroundColor: const Color(0xFFF4EEE9),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------
                // Real feature header
                // ------------------------------------------

                const Text(
                  'GPA Journey',
                  style: TextStyle(
                    color: Color(0xFF211F1E),
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 2),

                const Text(
                  'Plan your semester',
                  style: TextStyle(
                    color: Color(0xFF817A76),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // ------------------------------------------
                // GPA hero card
                // ------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF8),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x17000000),
                        blurRadius: 22,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: _Metric(label: 'CURRENT', value: '3.47'),
                      ),

                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            const Text(
                              'PROJECTED',
                              style: TextStyle(
                                color: Color(0xFFD81E2F),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 1),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              child: Text(
                                projected.toStringAsFixed(2),
                                key: ValueKey(projected.toStringAsFixed(3)),
                                style: const TextStyle(
                                  color: Color(0xFFD81E2F),
                                  fontSize: 34,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Expanded(
                        child: _Metric(
                          label: 'TARGET',
                          value: '3.50',
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 13),

                // ------------------------------------------
                // Dark physical module inside warm app
                // ------------------------------------------
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF171719),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 28,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(child: GameWidget(game: game)),

                        // Quiet interaction hint.
                        const Positioned(
                          left: 18,
                          bottom: 14,
                          child: IgnorePointer(
                            child: Text(
                              'Drag a course into a grade',
                              style: TextStyle(
                                color: Color(0x668F8F96),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 11),

                // ------------------------------------------
                // Latest impact only
                // ------------------------------------------
                Container(
                  height: 42,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF8),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: lastAction == null
                        ? const Row(
                            key: ValueKey('empty'),
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 16,
                                color: Color(0xFFACA39E),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Try a grade scenario',
                                style: TextStyle(
                                  color: Color(0xFF817A76),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: ValueKey(lastAction),
                            children: [
                              Expanded(
                                child: Text(
                                  lastAction!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF403C39),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if ((lastImpact ?? 0).abs() >= 0.0005)
                                Text(
                                  '${(lastImpact ?? 0) >= 0 ? '+' : ''}'
                                  '${(lastImpact ?? 0).toStringAsFixed(2)} GPA',
                                  style: TextStyle(
                                    color: (lastImpact ?? 0) >= 0
                                        ? const Color(0xFF198754)
                                        : const Color(0xFFB55D00),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
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
      ),
    );
  }
}

class _CommittedGrade {
  final int credits;
  final String gradeLabel;
  final double gradePoint;

  const _CommittedGrade({
    required this.credits,
    required this.gradeLabel,
    required this.gradePoint,
  });
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _Metric({
    required this.label,
    required this.value,
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
          style: const TextStyle(
            color: Color(0xFFAAA29D),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF272321),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
