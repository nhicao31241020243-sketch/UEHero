import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
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

  late final GpaPhysicsGame game;

  final Map<String, _CommittedGrade> committedGrades = {};

  @override
  void initState() {
    super.initState();

    game = GpaPhysicsGame(
      onGradeCommitted: (courseId, credits, gradeLabel, gradePoint) {
        if (!mounted) return;

        setState(() {
          committedGrades[courseId] = _CommittedGrade(
            credits: credits,
            gradeLabel: gradeLabel,
            gradePoint: gradePoint,
          );
        });
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
    final reachedTarget = projected >= targetGpa;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Forge2D — Checkpoint 4',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),

                // Flutter remains the academic truth layer.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(18),
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
                                color: AppColors.brandSoft,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Text(
                                projected.toStringAsFixed(2),
                                key: ValueKey(projected.toStringAsFixed(3)),
                                style: TextStyle(
                                  color: reachedTarget
                                      ? AppColors.success
                                      : AppColors.brandSoft,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
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

                const SizedBox(height: 8),

                ValueListenableBuilder<String>(
                  valueListenable: game.status,
                  builder: (context, status, _) {
                    return Text(
                      status,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            color: const Color(0xFF111113),
                            child: GameWidget(game: game),
                          ),
                        ),

                        // Debug labels aligned with the
                        // four evenly spaced physics pockets.
                        const Positioned(
                          left: 15,
                          right: 15,
                          bottom: 19,
                          child: IgnorePointer(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _PocketLabel(label: 'B', value: '3.0'),
                                _PocketLabel(label: 'B+', value: '3.5'),
                                _PocketLabel(label: 'A-', value: '3.7'),
                                _PocketLabel(label: 'A', value: '4.0'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (committedGrades.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    committedGrades.entries
                        .map(
                          (entry) => '${entry.key}: ${entry.value.gradeLabel}',
                        )
                        .join('  ·  '),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
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
            color: AppColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PocketLabel extends StatelessWidget {
  final String label;
  final String value;

  const _PocketLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 8),
          ),
        ],
      ),
    );
  }
}
