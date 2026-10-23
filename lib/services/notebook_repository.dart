import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cv_check.dart';
import '../models/notebook_activity.dart';
import 'activity_log_service.dart';
import 'cv_score_store.dart';
import 'flashcard_service.dart';
import 'interview_service.dart';
import 'job_repository.dart';
import 'mentor_booking_service.dart';
import 'points_manager.dart';
import 'task_repository.dart';

class NotebookRepository {
  NotebookRepository._();

  static final instance = NotebookRepository._();

  static const _studyBuddyHistoryKey = 'study_question_history';

  Future<NotebookDashboardData> load({
    required NotebookPeriod period,
    DateTime? now,
    SharedPreferences? preferences,
  }) async {
    final currentTime = now ?? DateTime.now();
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await ActivityLogService.instance.initialize(
      preferences: prefs,
      now: currentTime,
    );
    await Future.wait([
      PointsManager.instance.initialize(preferences: prefs),
      FlashcardService.instance.initialize(),
      MentorBookingService.instance.initialize(preferences: prefs),
      TaskRepository.instance.initialize(preferences: prefs),
      JobRepository.instance.initialize(preferences: prefs),
    ]);

    final warnings = <String>[];
    final sourceData = await _readTimestampedSources(
      preferences: prefs,
      now: currentTime,
      warnings: warnings,
    );
    final allActivities = <NotebookActivity>[
      ...ActivityLogService.instance.activities,
      ...sourceData.activities,
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final retentionStart = currentTime.subtract(ActivityLogService.retention);
    final start = period.startAt(currentTime) ?? retentionStart;
    final currentActivities = allActivities
        .where(
          (activity) =>
              !activity.timestamp.isBefore(start) &&
              !activity.timestamp.isAfter(currentTime),
        )
        .toList(growable: false);
    final cvCurrent = sourceData.cvEntries
        .where(
          (entry) =>
              !entry.createdAt.isBefore(start) &&
              !entry.createdAt.isAfter(currentTime),
        )
        .toList(growable: false);
    final currentReadiness = _readiness(
      activities: currentActivities,
      cvEntries: cvCurrent,
      totalReviewed: period == NotebookPeriod.all
          ? FlashcardService.instance.totalReviewed
          : null,
      legacyLastStudyDate: sourceData.legacyLastStudyDate,
      taskCount: sourceData.taskCount,
      completedTaskCount: period == NotebookPeriod.all
          ? sourceData.completedTaskCount
          : null,
      savedJobCount: period == NotebookPeriod.all
          ? JobRepository.instance.savedJobIds.length
          : 0,
      eventSourceAvailable: sourceData.eventSourceAvailable,
    );

    final previousStart = switch (period) {
      NotebookPeriod.thisWeek => start.subtract(const Duration(days: 7)),
      NotebookPeriod.thisMonth => DateTime(start.year, start.month - 1),
      NotebookPeriod.all => null,
    };
    final previousReadiness = previousStart == null
        ? null
        : _readiness(
            activities: allActivities
                .where(
                  (activity) =>
                      !activity.timestamp.isBefore(previousStart) &&
                      activity.timestamp.isBefore(start),
                )
                .toList(growable: false),
            cvEntries: sourceData.cvEntries
                .where(
                  (entry) =>
                      !entry.createdAt.isBefore(previousStart) &&
                      entry.createdAt.isBefore(start),
                )
                .toList(growable: false),
            legacyLastStudyDate: sourceData.legacyLastStudyDate,
            taskCount: sourceData.taskCount,
            savedJobCount: 0,
            eventSourceAvailable: sourceData.eventSourceAvailable,
          );

    return NotebookDashboardData(
      activities: List.unmodifiable(currentActivities),
      activityPoints: List.unmodifiable(
        _points(currentActivities, period, currentTime),
      ),
      distribution: notebookDistribution(currentActivities),
      readiness: currentReadiness,
      previousReadiness: previousReadiness,
      hasAnySourceData:
          allActivities.isNotEmpty ||
          sourceData.cvEntries.isNotEmpty ||
          sourceData.completedTaskCount > 0 ||
          FlashcardService.instance.totalReviewed > 0,
      sourceWarnings: List.unmodifiable(warnings),
    );
  }

  CareerReadinessResult _readiness({
    required List<NotebookActivity> activities,
    required List<CvScoreEntry> cvEntries,
    int? totalReviewed,
    DateTime? legacyLastStudyDate,
    required int taskCount,
    int? completedTaskCount,
    required int savedJobCount,
    required bool eventSourceAvailable,
  }) {
    final latestCv = cvEntries.isEmpty
        ? null
        : (cvEntries..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                  .first
                  .score
                  .toDouble() /
              100;
    final skillCount = activities
        .where((activity) => activity.feature == NotebookFeature.skillDrills)
        .length;
    final hasLegacyStudy =
        totalReviewed != null &&
        totalReviewed > 0 &&
        legacyLastStudyDate != null;
    final legacyReviewCount = totalReviewed ?? 0;
    final skillProgress = skillCount > 0
        ? (skillCount / 10).clamp(0.0, 1.0)
        : hasLegacyStudy
        ? (legacyReviewCount / 20).clamp(0.0, 1.0)
        : null;
    final interviewCount = activities
        .where((activity) => activity.feature == NotebookFeature.interview)
        .length;
    final weeklyCount = activities
        .where((activity) => activity.feature == NotebookFeature.weeklyPlan)
        .length;
    final mentorCount = activities
        .where((activity) => activity.feature == NotebookFeature.mentor)
        .length;
    final jobCount =
        activities
            .where((activity) => activity.feature == NotebookFeature.jobMatch)
            .length +
        savedJobCount;
    final eventCount = activities
        .where((activity) => activity.feature == NotebookFeature.events)
        .length;
    return calculateCareerReadiness(
      CareerReadinessInputs(
        cvScore: latestCv,
        skillDrillsProgress: skillProgress,
        interviewProgress: interviewCount == 0
            ? null
            : (interviewCount / 3).clamp(0.0, 1.0),
        weeklyPlanProgress: taskCount == 0
            ? null
            : completedTaskCount != null
            ? (completedTaskCount / taskCount).clamp(0.0, 1.0)
            : (weeklyCount / 5).clamp(0.0, 1.0),
        mentorProgress: mentorCount == 0
            ? null
            : (mentorCount / 3).clamp(0.0, 1.0),
        jobMatchProgress: jobCount == 0 ? null : (jobCount > 0 ? 1.0 : 0.0),
        eventsProgress: eventSourceAvailable
            ? (eventCount / 3).clamp(0.0, 1.0)
            : null,
      ),
    );
  }

  Future<_TimestampedSources> _readTimestampedSources({
    required SharedPreferences preferences,
    required DateTime now,
    required List<String> warnings,
  }) async {
    final activities = <NotebookActivity>[];
    final cvEntries = await CvScoreStore().entries(preferences: preferences);
    for (final entry in cvEntries) {
      activities.add(
        NotebookActivity(
          feature: NotebookFeature.cvCheck,
          type: 'score:${entry.score}',
          timestamp: entry.createdAt,
        ),
      );
    }

    for (final booking in MentorBookingService.instance.bookings) {
      final timestamp = booking.completedAt ?? booking.createdAt;
      activities.add(
        NotebookActivity(
          feature: NotebookFeature.mentor,
          type: booking.completedAt == null ? 'booking' : 'completed',
          timestamp: timestamp,
        ),
      );
    }

    final interviews = await InterviewService.instance.loadHistory();
    for (final session in interviews.where(
      (session) => session.feedback != null,
    )) {
      activities.add(
        NotebookActivity(
          feature: NotebookFeature.interview,
          type: 'completed',
          timestamp: session.startedAt.add(
            Duration(seconds: session.durationSeconds),
          ),
        ),
      );
    }

    activities.addAll(_studyBuddyActivities(preferences));
    activities.addAll(_jobSaveActivities());
    final eventAvailable = await _eventActivities(activities, warnings);

    final rawFlashcards = preferences.getString(FlashcardService.storageKey);
    DateTime? legacyStudyDate;
    if (rawFlashcards != null) {
      final decoded = jsonDecode(rawFlashcards);
      if (decoded is Map<String, dynamic>) {
        legacyStudyDate = DateTime.tryParse(
          decoded['lastStudyDate'] as String? ?? '',
        );
      }
    }
    if (FlashcardService.instance.totalReviewed > 0) {
      if (legacyStudyDate case final studyDate?) {
        if (!ActivityLogService.instance.activities.any(
          (activity) =>
              activity.feature == NotebookFeature.skillDrills &&
              _sameDate(activity.timestamp, studyDate),
        )) {
          activities.add(
            NotebookActivity(
              feature: NotebookFeature.skillDrills,
              type: 'legacy-study-day',
              timestamp: studyDate,
            ),
          );
        }
      }
    }

    final tasks = await TaskRepository.instance.list(preferences: preferences);
    return _TimestampedSources(
      activities: activities,
      cvEntries: cvEntries,
      legacyLastStudyDate: legacyStudyDate,
      taskCount: tasks.length,
      completedTaskCount: tasks
          .where((task) => task.trangThai.name == 'completed')
          .length,
      eventSourceAvailable: eventAvailable,
    );
  }

  List<NotebookActivity> _studyBuddyActivities(SharedPreferences preferences) {
    final raw = preferences.getString(_studyBuddyHistoryKey);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Study Buddy history must be a list.');
    }
    return [
      for (final entry in decoded.whereType<Map>())
        if (DateTime.tryParse(entry['date']?.toString() ?? '') case final at?)
          NotebookActivity(
            feature: NotebookFeature.studyBuddy,
            type: 'question',
            timestamp: at,
          ),
    ];
  }

  List<NotebookActivity> _jobSaveActivities() => [
    for (final entry in PointsManager.instance.entries)
      if (entry.nguon == 'job_save')
        NotebookActivity(
          feature: NotebookFeature.jobMatch,
          type: 'saved',
          timestamp: entry.thoiGian,
        ),
  ];

  Future<bool> _eventActivities(
    List<NotebookActivity> activities,
    List<String> warnings,
  ) async {
    if (Firebase.apps.isEmpty) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final root = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshots = await Future.wait([
        root
            .collection('savedEvents')
            .get(const GetOptions(source: Source.serverAndCache)),
        root
            .collection('plan')
            .get(const GetOptions(source: Source.serverAndCache)),
      ]);
      for (final document in snapshots[0].docs) {
        final timestamp = _date(document.data()['addedAt']);
        if (timestamp != null) {
          activities.add(
            NotebookActivity(
              feature: NotebookFeature.events,
              type: 'saved',
              timestamp: timestamp,
            ),
          );
        }
      }
      for (final document in snapshots[1].docs) {
        final timestamp = _date(document.data()['addedAt']);
        if (timestamp != null) {
          activities.add(
            NotebookActivity(
              feature: NotebookFeature.events,
              type: 'planned',
              timestamp: timestamp,
            ),
          );
        }
      }
      return true;
    } on FirebaseException catch (error) {
      warnings.add(
        'Không đọc được lịch sử Events: ${error.message ?? error.code}',
      );
      return false;
    }
  }

  List<NotebookActivityPoint> _points(
    List<NotebookActivity> activities,
    NotebookPeriod period,
    DateTime now,
  ) {
    if (activities.isEmpty) return const [];
    final end = DateTime(now.year, now.month, now.day);
    final start =
        period.startAt(now) ??
        end.subtract(ActivityLogService.retention - const Duration(days: 1));
    final days = end.difference(start).inDays + 1;
    final counts = <DateTime, int>{};
    for (final activity in activities) {
      final key = DateTime(
        activity.timestamp.year,
        activity.timestamp.month,
        activity.timestamp.day,
      );
      counts.update(
        key,
        (activityCount) => activityCount + 1,
        ifAbsent: () => 1,
      );
    }
    return [
      for (var offset = 0; offset < days; offset++)
        () {
          final date = start.add(Duration(days: offset));
          return NotebookActivityPoint(date, counts[date] ?? 0);
        }(),
    ];
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _TimestampedSources {
  const _TimestampedSources({
    required this.activities,
    required this.cvEntries,
    required this.legacyLastStudyDate,
    required this.taskCount,
    required this.completedTaskCount,
    required this.eventSourceAvailable,
  });

  final List<NotebookActivity> activities;
  final List<CvScoreEntry> cvEntries;
  final DateTime? legacyLastStudyDate;
  final int taskCount;
  final int completedTaskCount;
  final bool eventSourceAvailable;
}
