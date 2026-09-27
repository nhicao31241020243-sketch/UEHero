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

  static const courseNames = {
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

  double get delta => projectedGpa - currentGpa;

  @override
  Widget build(BuildContext context) {
    final projected = projectedGpa;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F2EE),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFF7F2EE),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================
                // HEADER
                // ==========================

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GPA Journey',
                            style: TextStyle(
                              color: Color(0xFF211C1D),
                              fontSize: 29,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Plan your semester. Shape your outcome.',
                            style: TextStyle(
                              color: Color(0xFF81736F),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF8),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x16000000),
                            blurRadius: 18,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '•••',
                        style: TextStyle(
                          color: Color(0xFF574B49),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 17),

                // ==========================
                // GPA HERO
                // ==========================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(17, 18, 17, 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDFC),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 28,
                        offset: Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
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
                                    color: Color(0xFFD92332),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 230),
                                  child: Text(
                                    projected.toStringAsFixed(2),
                                    key: ValueKey(projected.toStringAsFixed(3)),
                                    style: const TextStyle(
                                      color: Color(0xFFD92332),
                                      fontSize: 35,
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

                      const SizedBox(height: 11),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE2DE),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)} from current',
                          style: const TextStyle(
                            color: Color(0xFFC84146),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 17),

                // ==========================
                // PHYSICAL INTERACTION STAGE
                // ==========================
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFEFE4DE),
                          Color(0xFFE4D6CF),
                          Color(0xFFD6C4BB),
                        ],
                        stops: [0, 0.47, 1],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.58),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1C4A332D),
                          blurRadius: 30,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GameWidget(game: game),
                  ),
                ),

                const SizedBox(height: 13),

                // ==========================
                // FEEDBACK STRIP
                // ==========================
                Container(
                  width: double.infinity,
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDFC),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4E5DB),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.north_east_rounded,
                          size: 19,
                          color: Color(0xFFC96A4B),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Column(
                            key: ValueKey(lastAction ?? 'empty'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lastAction ?? 'Drag a course into a grade',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF342C2B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                lastImpact == null
                                    ? 'Projected GPA updates instantly'
                                    : '${(lastImpact ?? 0) >= 0 ? '+' : ''}${(lastImpact ?? 0).toStringAsFixed(2)} GPA impact',
                                style: TextStyle(
                                  color: lastImpact == null
                                      ? const Color(0xFF8B7F7B)
                                      : (lastImpact ?? 0) >= 0
                                      ? const Color(0xFF428B68)
                                      : const Color(0xFFB8673A),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF645955),
                      ),
                    ],
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
            color: Color(0xFF9C908C),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.45,
          ),
        ),

        const SizedBox(height: 4),

        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2A2424),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
