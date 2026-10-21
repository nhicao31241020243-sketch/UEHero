import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../logic/gpa_calculator.dart';
import '../widgets/gpa_goal_card.dart';
import '../widgets/gpa_hero_ring.dart';
import '../widgets/target_gpa_sheet.dart';
import '../widgets/what_if_sheet.dart';

class GpaDashboardScreen extends StatefulWidget {
  const GpaDashboardScreen({super.key});

  @override
  State<GpaDashboardScreen> createState() => _GpaDashboardScreenState();
}

class _GpaDashboardScreenState extends State<GpaDashboardScreen> {
  static const double currentGpa = 3.42;
  static const int completedCredits = 88;
  static const int totalCredits = 120;

  double targetGpa = 3.50;

  Future<void> _changeTarget() async {
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return TargetGpaSheet(initialTarget: targetGpa);
      },
    );

    if (result == null) return;

    setState(() {
      targetGpa = result;
    });
  }

  void _openSimulator() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return WhatIfSheet(
          currentGpa: currentGpa,
          completedCredits: completedCredits,
          targetGpa: targetGpa,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final requiredGpa = GpaCalculator.requiredRemainingGpa(
      currentGpa: currentGpa,
      completedCredits: completedCredits,
      totalCredits: totalCredits,
      targetGpa: targetGpa,
    );

    final maxPossibleGpa = GpaCalculator.maxPossibleGpa(
      currentGpa: currentGpa,
      completedCredits: completedCredits,
      totalCredits: totalCredits,
    );

    final targetPossible = GpaCalculator.isTargetPossible(
      currentGpa: currentGpa,
      completedCredits: completedCredits,
      totalCredits: totalCredits,
      targetGpa: targetGpa,
    );

    final requiredAcredits = GpaCalculator.requiredTopGradeCredits(
      currentGpa: currentGpa,
      completedCredits: completedCredits,
      totalCredits: totalCredits,
      targetGpa: targetGpa,
      baselineRemainingGpa: 3.5,
    );

    final roundedAcredits = (requiredAcredits / 3).ceil() * 3;
    final approximateCourses = (roundedAcredits / 3).ceil();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GPA Journey',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Theo dõi mục tiêu học tập của bạn',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                height: 370,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.08),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      targetPossible
                          ? 'MỤC TIÊU KHẢ THI'
                          : 'MỤC TIÊU VƯỢT KHẢ NĂNG',
                      style: TextStyle(
                        color: targetPossible
                            ? AppColors.success
                            : AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GpaHeroRing(currentGpa: currentGpa, targetGpa: targetGpa),
                    TextButton.icon(
                      onPressed: _changeTarget,
                      icon: const Icon(Icons.edit_rounded, size: 15),
                      label: Text(
                        'Đổi mục tiêu ${targetGpa.toStringAsFixed(2)}',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (targetPossible)
                GpaGoalCard(
                  targetGpa: targetGpa,
                  requiredGpa: requiredGpa,
                  completedCredits: completedCredits,
                  totalCredits: totalCredits,
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mục tiêu hiện tại vượt mức khả thi',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Nếu toàn bộ tín chỉ còn lại đều đạt 4.0, GPA tối đa dự kiến là',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        maxPossibleGpa.toStringAsFixed(2),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _changeTarget,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: BorderSide(
                            color: AppColors.warning.withValues(alpha: 0.45),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('THỬ MỤC TIÊU KHÁC'),
                      ),
                    ],
                  ),
                ),

              if (targetPossible) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_graph_rounded,
                            color: AppColors.brand,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Một kịch bản khả thi',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '≈ $roundedAcredits tín chỉ đạt 4.0',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Khoảng $approximateCourses môn nếu mỗi môn có 3 tín chỉ.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '* Giả định các tín chỉ còn lại ngoài nhóm 4.0 đạt trung bình 3.5.',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: _openSimulator,
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  label: const Text(
                    'MÔ PHỎNG KỲ TỚI',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: AppColors.brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
