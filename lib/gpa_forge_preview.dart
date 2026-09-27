import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/gpa_lab/game/gpa_physics_game.dart';
import 'features/gpa_lab/logic/gpa_scenario.dart';
import 'features/gpa_lab/presentation/widgets/gpa_journey_chart.dart';

void main() {
  runApp(const GpaForgePreviewApp());
}

class GpaForgePreviewApp extends StatefulWidget {
  const GpaForgePreviewApp({super.key});

  @override
  State<GpaForgePreviewApp> createState() => _GpaForgePreviewAppState();
}

class _GpaForgePreviewAppState extends State<GpaForgePreviewApp> {
  late GpaScenario scenario;

  late final GpaPhysicsGame game;

  String? lastAction;
  double? lastImpact;

  @override
  void initState() {
    super.initState();

    scenario = const GpaScenario(
      currentGpa: 3.47,
      completedCredits: 77,
      targetGpa: 3.50,
      courses: [
        ScenarioCourse(
          id: 'ai_project',
          name: 'Dự án A.I.',
          shortCode: 'AI',
          credits: 3,
        ),
        ScenarioCourse(
          id: 'internship',
          name: 'Kiến tập - TI',
          shortCode: 'TI',
          credits: 5,
        ),
      ],
    );

    game = GpaPhysicsGame(
      onGradeCommitted: (courseId, credits, gradeLabel, gradePoint) {
        if (!mounted) {
          return;
        }

        final before = scenario.projectedGpa;

        final course = scenario.courseById(courseId);

        setState(() {
          scenario = scenario.assignGrade(
            courseId: courseId,
            gradeLabel: gradeLabel,
            gradePoint: gradePoint,
          );

          final after = scenario.projectedGpa;

          lastAction = '${course?.name ?? courseId} → $gradeLabel';

          lastImpact = after - before;
        });

        final after = scenario.projectedGpa;

        if (before < scenario.targetGpa && after >= scenario.targetGpa) {
          HapticFeedback.heavyImpact();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projected = scenario.projectedGpa;

    final delta = projected - scenario.currentGpa;

    final gap = scenario.gapToTarget;

    final reached = gap >= 0;

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
                // ==========================================
                // HEADER
                // ==========================================

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
                              fontSize: 28,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Plan your semester. Shape your outcome.',
                            style: TextStyle(
                              color: Color(0xFF81736F),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFBF8),
                        shape: BoxShape.circle,
                        boxShadow: [
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
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                // ==========================================
                // GPA HERO / GOAL ENGINE SUMMARY
                // ==========================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDFC),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x16000000),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Metric(
                              label: 'CURRENT',
                              value: scenario.currentGpa.toStringAsFixed(2),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                const Text(
                                  'PROJECTED',
                                  style: TextStyle(
                                    color: Color(0xFFD92332),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 230),
                                  child: Text(
                                    projected.toStringAsFixed(2),
                                    key: ValueKey(projected.toStringAsFixed(3)),
                                    style: TextStyle(
                                      color: reached
                                          ? const Color(0xFF428B68)
                                          : const Color(0xFFD92332),
                                      fontSize: 32,
                                      height: 1,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _Metric(
                              label: 'TARGET',
                              value: scenario.targetGpa.toStringAsFixed(2),
                              alignEnd: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 9),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatusPill(
                            text:
                                '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)} from current',
                            color: const Color(0xFFC84146),
                            background: const Color(0xFFFBE2DE),
                          ),

                          const SizedBox(width: 7),

                          _StatusPill(
                            text: reached
                                ? '+${gap.toStringAsFixed(2)} above target'
                                : '${gap.toStringAsFixed(2)} to target',
                            color: reached
                                ? const Color(0xFF367A5A)
                                : const Color(0xFF8A655D),
                            background: reached
                                ? const Color(0xFFE3F1E9)
                                : const Color(0xFFF4ECE8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 11),

                // ==========================================
                // LINKED 2.5D GPA JOURNEY
                // ==========================================
                GpaJourneyChart(
                  currentGpa: scenario.currentGpa,
                  projectedGpa: projected,
                  targetGpa: scenario.targetGpa,
                  plannedCount: scenario.assignedCount,
                  totalCount: scenario.totalCourseCount,
                ),

                const SizedBox(height: 11),

                // ==========================================
                // PHYSICAL SCENARIO INPUT
                // ==========================================
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
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.58),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1C4A332D),
                          blurRadius: 26,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(child: GameWidget(game: game)),

                        const Positioned(
                          left: 18,
                          right: 18,
                          top: 13,
                          child: IgnorePointer(
                            child: Row(
                              children: [
                                Text(
                                  'YOUR COURSES',
                                  style: TextStyle(
                                    color: Color(0xFF554743),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  'Drag to predict',
                                  style: TextStyle(
                                    color: Color(0xFF968681),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Positioned(
                          left: 18,
                          bottom: 92,
                          child: IgnorePointer(
                            child: Text(
                              'GRADING STATIONS',
                              style: TextStyle(
                                color: Color(0xFF655652),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 9),

                // ==========================================
                // CAUSE -> EFFECT FEEDBACK
                // ==========================================
                Container(
                  width: double.infinity,
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDFC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4E5DB),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.north_east_rounded,
                          size: 17,
                          color: Color(0xFFC96A4B),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Column(
                            key: ValueKey(lastAction ?? 'empty'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lastAction ??
                                    'Stamp a course to test a scenario',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF342C2B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lastImpact == null
                                    ? 'The journey above will respond instantly'
                                    : '${(lastImpact ?? 0) >= 0 ? '+' : ''}${(lastImpact ?? 0).toStringAsFixed(2)} GPA impact',
                                style: TextStyle(
                                  color: lastImpact == null
                                      ? const Color(0xFF8B7F7B)
                                      : (lastImpact ?? 0) >= 0
                                      ? const Color(0xFF428B68)
                                      : const Color(0xFFB8673A),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
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
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2A2424),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _StatusPill({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
