import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/models/app_task.dart';
import 'package:uehero/services/companion_context_service.dart';
import 'package:uehero/services/companion_settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CompanionContext', () {
    test('answers local prompts from saved context data', () {
      final context = CompanionContext(
        goalTitle: 'Data Analyst',
        stageName: 'Người khám phá',
        todayTasks: const [
          AppTask(
            id: 'task-1',
            nguon: 'CV',
            noiDung: 'Hoàn thiện CV',
            trangThai: TaskStatus.pending,
          ),
        ],
        overdueTasks: const [],
        dueCards: 4,
        upcomingCompetition: null,
        streak: 2,
      );

      expect(
        context.answerFor('Còn bao nhiêu thẻ chưa học?'),
        'Hiện có 4 thẻ đến hạn ôn hôm nay.',
      );
      expect(context.answerFor('Nên làm gì trước?'), contains('Hoàn thiện CV'));
      expect(context.reminderForRoute('/flashcards'), contains('4 thẻ'));
      expect(context.reminderForRoute('/events'), isNull);
    });

    test('reports actual nearby competition and empty state', () {
      final context = CompanionContext(
        goalTitle: null,
        stageName: 'Khởi đầu',
        todayTasks: const [],
        overdueTasks: const [],
        dueCards: 0,
        upcomingCompetition: null,
        streak: 0,
      );

      expect(
        context.answerFor('Cuộc thi sắp hết hạn?'),
        contains('chưa có cuộc thi nào'),
      );
      expect(context.answerFor('Hôm nay có gì?'), contains('chưa có mục nào'));
    });
  });

  test('limits reminder bubbles by daily cap and minimum interval', () async {
    SharedPreferences.setMockInitialValues({});
    final store = CompanionSettingsStore.instance;
    final start = DateTime(2026, 10, 14, 9);

    expect(await store.tryReserveBubble(at: start), isTrue);
    expect(
      await store.tryReserveBubble(at: start.add(const Duration(minutes: 5))),
      isFalse,
    );
    expect(
      await store.tryReserveBubble(at: start.add(const Duration(minutes: 11))),
      isTrue,
    );
    expect(
      await store.tryReserveBubble(at: start.add(const Duration(minutes: 22))),
      isTrue,
    );
    expect(
      await store.tryReserveBubble(at: start.add(const Duration(minutes: 33))),
      isFalse,
    );
    expect(
      await store.tryReserveBubble(
        at: start.add(const Duration(days: 1, minutes: 1)),
      ),
      isTrue,
    );
  });

  test('auto movement preference defaults on and can be toggled', () async {
    SharedPreferences.setMockInitialValues({});
    final store = CompanionSettingsStore.instance;

    expect(await store.autoMovementEnabled(), isTrue);
    await store.setAutoMovementEnabled(false);
    expect(await store.autoMovementEnabled(), isFalse);
    await store.setAutoMovementEnabled(true);
    expect(await store.autoMovementEnabled(), isTrue);
  });
}
