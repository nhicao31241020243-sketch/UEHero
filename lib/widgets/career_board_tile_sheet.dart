import 'package:flutter/material.dart';

import '../config/career_board_config.dart';
import '../home_event_screen.dart';
import '../screens/cv_check_screen.dart';
import '../screens/flashcard_home_screen.dart';
import '../screens/interview/interview_home_screen.dart';
import '../screens/job_screen.dart';
import '../screens/mentor_screen.dart';
import '../screens/second_hand_market_screen.dart';
import '../screens/uehero_camera_screen.dart';
import '../services/career_board_service.dart';
import '../theme/space_theme.dart';
import 'space_glass_widgets.dart';

IconData boardTaskIcon(BoardTaskKind kind) => switch (kind) {
  BoardTaskKind.flashcards => Icons.style_rounded,
  BoardTaskKind.library => Icons.menu_book_rounded,
  BoardTaskKind.cvScore => Icons.description_rounded,
  BoardTaskKind.interview => Icons.record_voice_over_rounded,
  BoardTaskKind.mentor => Icons.support_agent_rounded,
  BoardTaskKind.event => Icons.event_rounded,
  BoardTaskKind.jobReadiness => Icons.work_rounded,
  BoardTaskKind.studyBuddy => Icons.photo_camera_rounded,
};

/// Feature screen opened from a board tile.
Widget boardDestinationFor(BoardTile tile) => switch (tile.kind) {
  BoardTaskKind.flashcards => FlashcardHomeScreen(),
  BoardTaskKind.library => SecondHandMarketScreen(),
  BoardTaskKind.cvScore => CvCheckScreen(),
  BoardTaskKind.interview => InterviewHomeScreen(),
  BoardTaskKind.mentor => MentorScreen(),
  BoardTaskKind.event => HomeEventScreen(),
  BoardTaskKind.jobReadiness => JobScreen(),
  BoardTaskKind.studyBuddy => UEHeroCameraScreen(careerMapMilestoneId: tile.id),
};

enum _TileAction { open }

/// Shows the tile details. When the user taps "Mở tính năng" the feature
/// screen opens, and the board re-syncs when the user comes back.
Future<void> showCareerBoardTileSheet(
  BuildContext context, {
  required String role,
  required BoardTile tile,
}) async {
  final action = await showModalBottomSheet<_TileAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TileSheet(role: role, tile: tile),
  );
  if (action != _TileAction.open || !context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => boardDestinationFor(tile)),
  );
  await CareerBoardService.instance.sync();
}

class _TileSheet extends StatefulWidget {
  const _TileSheet({required this.role, required this.tile});

  final String role;
  final BoardTile tile;

  @override
  State<_TileSheet> createState() => _TileSheetState();
}

class _TileSheetState extends State<_TileSheet> {
  late bool _linked = CareerBoardService.instance.isWeeklyLinked(
    widget.role,
    widget.tile,
  );
  bool _busy = false;

  Future<void> _addToWeekly() async {
    if (_busy) return;
    setState(() => _busy = true);
    final added = await CareerBoardService.instance.addToWeekly(
      widget.role,
      widget.tile,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _linked = true;
    });
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          added
              ? 'Đã thêm vào kế hoạch tuần'
              : 'Nhiệm vụ này đã có trong kế hoạch tuần',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    final done = CareerBoardService.instance
        .doneTileIds(widget.role)
        .contains(tile.id);
    final status = done
        ? 'Đã hoàn thành'
        : (tile.required ? 'Chưa hoàn thành' : 'Nhiệm vụ phụ');
    return SafeArea(
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
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SpaceTheme.glow.withValues(alpha: 0.2),
                      border: Border.all(
                        color: SpaceTheme.glow.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(
                      boardTaskIcon(tile.kind),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tile.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tile.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.auto_awesome_rounded,
                    label: '+${tile.stardust} Stardust',
                  ),
                  _InfoChip(
                    icon: done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    label: status,
                  ),
                  if (_linked && !done)
                    const _InfoChip(
                      icon: Icons.event_note_rounded,
                      label: 'Trong kế hoạch tuần',
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (!done && !_linked) ...[
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    onPressed: _addToWeekly,
                    child: const Text('Thêm vào kế hoạch tuần'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: SpaceTheme.glow,
                    foregroundColor: const Color(0xFF1A1020),
                  ),
                  onPressed: () => Navigator.of(context).pop(_TileAction.open),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Mở tính năng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: SpaceTheme.glow),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );
}
