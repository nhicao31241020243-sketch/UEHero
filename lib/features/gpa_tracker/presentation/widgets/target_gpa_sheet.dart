import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class TargetGpaSheet extends StatefulWidget {
  final double initialTarget;

  const TargetGpaSheet({super.key, required this.initialTarget});

  @override
  State<TargetGpaSheet> createState() => _TargetGpaSheetState();
}

class _TargetGpaSheetState extends State<TargetGpaSheet> {
  late double target;

  static const presets = [3.20, 3.40, 3.50, 3.60, 3.80];

  @override
  void initState() {
    super.initState();
    target = widget.initialTarget;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
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
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Đặt mục tiêu GPA',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chọn GPA bạn muốn đạt khi hoàn thành chương trình.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              target.toStringAsFixed(2),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.brand,
                inactiveTrackColor: AppColors.surface,
                thumbColor: Colors.white,
                overlayColor: AppColors.brand.withValues(alpha: 0.16),
                trackHeight: 6,
              ),
              child: Slider(
                min: 2.0,
                max: 4.0,
                divisions: 40,
                value: target,
                onChanged: (value) {
                  setState(() {
                    target = double.parse(value.toStringAsFixed(2));
                  });
                },
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '2.00',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '4.00',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: presets.map((value) {
                final selected = (target - value).abs() < 0.001;

                return ChoiceChip(
                  label: Text(value.toStringAsFixed(2)),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: AppColors.brand,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: selected
                        ? AppColors.brand
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() {
                      target = value;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context, target);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'ÁP DỤNG MỤC TIÊU',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
