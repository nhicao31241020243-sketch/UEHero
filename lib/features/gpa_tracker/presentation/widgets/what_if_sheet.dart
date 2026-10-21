import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../logic/gpa_calculator.dart';

class WhatIfSheet extends StatefulWidget {
  final double currentGpa;
  final int completedCredits;
  final double targetGpa;

  const WhatIfSheet({
    super.key,
    required this.currentGpa,
    required this.completedCredits,
    required this.targetGpa,
  });

  @override
  State<WhatIfSheet> createState() => _WhatIfSheetState();
}

class _WhatIfSheetState extends State<WhatIfSheet> {
  final List<_CourseScenario> courses = [
    _CourseScenario(name: 'Kinh tế lượng', credits: 3, gradePoint: 4.0),
    _CourseScenario(name: 'Python', credits: 3, gradePoint: 3.5),
    _CourseScenario(name: 'Marketing', credits: 3, gradePoint: 4.0),
  ];

  static const List<double> gradeOptions = [
    4.0,
    3.7,
    3.5,
    3.0,
    2.5,
    2.0,
    1.0,
    0.0,
  ];

  static const List<int> creditOptions = [2, 3, 4];

  double get projectedGpa {
    return GpaCalculator.projectedGpa(
      currentGpa: widget.currentGpa,
      completedCredits: widget.completedCredits,
      futureCourses: courses
          .map(
            (course) => FutureCourseResult(
              credits: course.credits,
              gradePoint: course.gradePoint,
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projected = projectedGpa;
    final difference = widget.targetGpa - projected;
    final reachesTarget = projected >= widget.targetGpa;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 22),

            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Mô phỏng kỳ tới',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Icon(Icons.auto_graph_rounded, color: AppColors.brand),
              ],
            ),

            const SizedBox(height: 6),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Thử thay đổi điểm và tín chỉ để xem GPA dự kiến.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),

            const SizedBox(height: 22),

            ...List.generate(
              courses.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCourseRow(index),
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  const Text(
                    'GPA dự kiến',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.currentGpa.toStringAsFixed(2),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.brand,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          projected.toStringAsFixed(2),
                          key: ValueKey(projected.toStringAsFixed(3)),
                          style: TextStyle(
                            color: reachesTarget
                                ? AppColors.success
                                : AppColors.textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reachesTarget
                        ? '✓ Kịch bản này đạt mục tiêu ${widget.targetGpa.toStringAsFixed(2)}'
                        : 'Còn thiếu ${difference.toStringAsFixed(2)} để đạt mục tiêu ${widget.targetGpa.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: reachesTarget
                          ? AppColors.success
                          : AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'XONG',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseRow(int index) {
    final course = courses[index];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              course.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: course.credits,
              dropdownColor: AppColors.surfaceRaised,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              items: creditOptions
                  .map(
                    (credits) => DropdownMenuItem<int>(
                      value: credits,
                      child: Text('$credits TC'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  course.credits = value;
                });
              },
            ),
          ),

          const SizedBox(width: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: course.gradePoint,
                dropdownColor: AppColors.surfaceRaised,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                items: gradeOptions
                    .map(
                      (grade) => DropdownMenuItem<double>(
                        value: grade,
                        child: Text(grade.toStringAsFixed(1)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    course.gradePoint = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseScenario {
  final String name;
  int credits;
  double gradePoint;

  _CourseScenario({
    required this.name,
    required this.credits,
    required this.gradePoint,
  });
}
