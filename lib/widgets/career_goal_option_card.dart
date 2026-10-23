import 'package:flutter/material.dart';

import '../models/career_goal.dart';

class CareerGoalOptionCard extends StatelessWidget {
  const CareerGoalOptionCard({
    required this.goal,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final CareerGoal goal;
  final bool selected;
  final VoidCallback onTap;

  static const _accent = Color(0xFFBFA8FF);
  static const _cyan = Color(0xFF70D8F2);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF30284A) : const Color(0xFF211D2B),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? _cyan.withValues(alpha: 0.85)
                  : _accent.withValues(alpha: 0.2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(goal.icon, color: selected ? _cyan : _accent, size: 22),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? _cyan : const Color(0xFF777181),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
