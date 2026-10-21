import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_task.dart';
import '../models/event_item.dart';
import 'event_repository.dart';
import 'flashcard_service.dart';
import 'points_manager.dart';
import 'task_repository.dart';

class CompanionContext {
  const CompanionContext({
    required this.goalTitle,
    required this.stageName,
    required this.todayTasks,
    required this.overdueTasks,
    required this.dueCards,
    required this.upcomingCompetition,
    required this.streak,
  });

  final String? goalTitle;
  final String stageName;
  final List<AppTask> todayTasks;
  final List<AppTask> overdueTasks;
  final int dueCards;
  final EventItem? upcomingCompetition;
  final int streak;

  String get summary {
    final details = <String>[];
    if (goalTitle != null) details.add('Mục tiêu: $goalTitle');
    details.add('Chặng: $stageName');
    details.add('Việc hôm nay: ${todayTasks.length}');
    details.add('Việc quá hạn: ${overdueTasks.length}');
    details.add('Thẻ cần ôn: $dueCards');
    final competition = upcomingCompetition;
    if (competition != null) {
      details.add('Cuộc thi gần hạn: ${competition.title}');
    }
    details.add('Chuỗi hoạt động: $streak ngày');
    return details.join(' · ');
  }

  String answerFor(String question) {
    final normalized = question.toLowerCase();
    if (normalized.contains('thẻ')) {
      return 'Hiện có $dueCards thẻ đến hạn ôn hôm nay.';
    }
    if (normalized.contains('cuộc thi') || normalized.contains('hết hạn')) {
      final event = upcomingCompetition;
      if (event == null) {
        return 'Hiện chưa có cuộc thi nào có hạn đăng ký trong 3 ngày tới.';
      }
      final deadline = event.registrationDeadline;
      if (deadline == null) return 'Cuộc thi gần hạn nhất là ${event.title}.';
      final days = deadline.difference(DateTime.now()).inDays.clamp(0, 3);
      return 'Cuộc thi gần hạn nhất là ${event.title}, còn khoảng $days ngày '
          'đến hạn đăng ký.';
    }
    if (normalized.contains('trước') || normalized.contains('nên làm')) {
      if (overdueTasks.isNotEmpty) {
        return 'Ưu tiên xử lý việc quá hạn: ${overdueTasks.first.noiDung}.';
      }
      if (todayTasks.isNotEmpty) {
        return 'Bạn có thể bắt đầu với: ${todayTasks.first.noiDung}.';
      }
      if (dueCards > 0) {
        return 'Bạn có thể ôn $dueCards thẻ đang đến hạn hôm nay.';
      }
      return 'Chưa có việc ưu tiên nào được ghi nhận hôm nay.';
    }

    final items = <String>[];
    if (todayTasks.isNotEmpty) {
      items.add('${todayTasks.length} việc cần làm hôm nay');
    }
    if (overdueTasks.isNotEmpty) {
      items.add('${overdueTasks.length} việc quá hạn');
    }
    if (dueCards > 0) items.add('$dueCards thẻ cần ôn');
    if (upcomingCompetition != null) {
      items.add('cuộc thi ${upcomingCompetition!.title} sắp hết hạn');
    }
    if (items.isEmpty) {
      return 'Hôm nay chưa có mục nào cần ưu tiên theo dữ liệu hiện có.';
    }
    return 'Hôm nay: ${items.join(', ')}.';
  }

  String? reminderForRoute(String? routeName) {
    final route = (routeName ?? '').toLowerCase();
    if (route.contains('flashcard') && dueCards > 0) {
      return 'Hôm nay có $dueCards thẻ cần ôn.';
    }
    if ((route.contains('event') || route.contains('competition')) &&
        upcomingCompetition != null) {
      return 'Cuộc thi ${upcomingCompetition!.title} sắp đến hạn.';
    }
    if (route.contains('weekly') || route.contains('calendar')) {
      if (overdueTasks.isNotEmpty) {
        return 'Bạn còn ${overdueTasks.length} việc quá hạn cần xử lý.';
      }
      if (todayTasks.isNotEmpty) {
        return 'Hôm nay có ${todayTasks.length} việc đang chờ bạn.';
      }
    }
    if (route.isEmpty || route == '/' || route.contains('home')) {
      if (overdueTasks.isNotEmpty) {
        return 'Ưu tiên hôm nay: ${overdueTasks.first.noiDung}.';
      }
      if (todayTasks.isNotEmpty) {
        return 'Việc ưu tiên hôm nay: ${todayTasks.first.noiDung}.';
      }
    }
    return null;
  }
}

class CompanionContextService {
  CompanionContextService._();

  static final instance = CompanionContextService._();

  Future<CompanionContext> load() async {
    final prefs = await SharedPreferences.getInstance();
    await TaskRepository.instance.initialize(preferences: prefs);
    await FlashcardService.instance.initialize();
    await PointsManager.instance.initialize(preferences: prefs);
    final tasks = await TaskRepository.instance.list(preferences: prefs);
    final now = DateTime.now();
    final today = _dateOnly(now);
    final todayTasks =
        tasks
            .where(
              (task) =>
                  !task.isDemo &&
                  task.trangThai == TaskStatus.pending &&
                  task.han != null &&
                  _dateOnly(task.han!) == today,
            )
            .toList()
          ..sort(_compareTasks);
    final overdueTasks =
        tasks
            .where(
              (task) =>
                  !task.isDemo &&
                  task.trangThai == TaskStatus.pending &&
                  task.han != null &&
                  _dateOnly(task.han!).isBefore(today),
            )
            .toList()
          ..sort(_compareTasks);

    final events = Firebase.apps.isEmpty
        ? const <EventItem>[]
        : await FirestoreEventRepository(FirebaseFirestore.instance)
              .fetchEvents();
    final competition =
        events.where((event) {
          final deadline = event.registrationDeadline;
          if (deadline == null) {
            return false;
          }
          final deadlineEnd = DateTime(
            deadline.year,
            deadline.month,
            deadline.day,
            23,
            59,
            59,
          );
          if (deadlineEnd.isBefore(now) ||
              deadlineEnd.isAfter(now.add(const Duration(days: 3)))) {
            return false;
          }
          final type = event.type.toLowerCase();
          final title = event.title.toLowerCase();
          return type.contains('cuộc thi') ||
              type.contains('competition') ||
              title.contains('cuộc thi') ||
              title.contains('challenge');
        }).toList()..sort((first, second) {
          return first.registrationDeadline!.compareTo(
            second.registrationDeadline!,
          );
        });

    return CompanionContext(
      goalTitle: prefs.getString('career_goal'),
      stageName: PointsManager.instance.currentStage.name,
      todayTasks: List.unmodifiable(todayTasks),
      overdueTasks: List.unmodifiable(overdueTasks),
      dueCards: FlashcardService.instance.dueCards.length,
      upcomingCompetition: competition.isEmpty ? null : competition.first,
      streak: _streak(tasks, today),
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _compareTasks(AppTask first, AppTask second) {
    final firstDue = first.han;
    final secondDue = second.han;
    if (firstDue == null) return secondDue == null ? 0 : 1;
    if (secondDue == null) return -1;
    return firstDue.compareTo(secondDue);
  }

  static int _streak(List<AppTask> tasks, DateTime today) {
    final days = tasks
        .where(
          (task) =>
              !task.isDemo &&
              task.trangThai == TaskStatus.completed &&
              task.nguon != 'Tay' &&
              task.han != null,
        )
        .map((task) => _dateOnly(task.han!))
        .toSet();
    var date = today;
    if (!days.contains(date)) date = date.subtract(const Duration(days: 1));
    var count = 0;
    while (days.contains(date)) {
      count++;
      date = date.subtract(const Duration(days: 1));
    }
    return count;
  }
}
