import 'package:flutter/material.dart';

import '../services/career_board_service.dart';
import '../theme/space_theme.dart';
import 'space_glass_widgets.dart';

/// Demo-only controls for presenting the Career Map. To remove the demo,
/// delete this file and the long-press hook on the Career Map title.
Future<void> showCareerBoardDemoSheet(
  BuildContext context, {
  required String role,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: Colors.transparent,
  builder: (_) => _DemoSheet(role: role),
);

class _DemoSheet extends StatelessWidget {
  const _DemoSheet({required this.role});

  final String role;

  Future<void> _completeNext(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await CareerBoardService.instance.completeNextDemo(role);
    navigator.pop();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          result == null
              ? 'Đã hoàn thành hết nhiệm vụ'
              : '${result.tile.title}: +${result.stardust} Stardust',
        ),
      ),
    );
  }

  Future<void> _reset(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    await CareerBoardService.instance.resetDemo(role);
    navigator.pop();
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'Đã đặt lại tiến độ demo (Stardust đã nhận vẫn giữ nguyên)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science_rounded, color: SpaceTheme.glow, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'CHẾ ĐỘ DEMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Dùng để trình bày. Hai nút này chạy đúng luồng thật: hoàn thành '
              'nhiệm vụ sẽ cộng Stardust và đưa mascot tiến lên. Đặt lại không '
              'trừ Stardust đã nhận.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: SpaceTheme.glow,
                  foregroundColor: const Color(0xFF1A1020),
                ),
                onPressed: () => _completeNext(context),
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Hoàn thành nhiệm vụ kế tiếp'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _reset(context),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Đặt lại tiến độ demo'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
