import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class GpaGoalCard extends StatelessWidget {
  final double targetGpa;
  final double requiredGpa;
  final int completedCredits;
  final int totalCredits;

  const GpaGoalCard({
    super.key,
    required this.targetGpa,
    required this.requiredGpa,
    required this.completedCredits,
    required this.totalCredits,
  });

  @override
  Widget build(BuildContext context) {
    final remainingCredits = totalCredits - completedCredits;
    final progress = completedCredits / totalCredits;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: AppColors.brand,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Road to ${targetGpa.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Bạn cần GPA trung bình',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            requiredGpa.toStringAsFixed(2),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'trong $remainingCredits tín chỉ còn lại',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brand),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$completedCredits / $totalCredits tín chỉ hoàn tất',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
