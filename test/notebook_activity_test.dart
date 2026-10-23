import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uehero/models/notebook_activity.dart';
import 'package:uehero/services/activity_log_service.dart';

void main() {
  final service = ActivityLogService.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service.resetForTesting();
  });

  tearDown(service.resetForTesting);

  test('records and reloads activities from versioned storage', () async {
    final preferences = await SharedPreferences.getInstance();
    final timestamp = DateTime(2026, 4, 15, 10);

    await service.record(
      feature: NotebookFeature.cvCheck,
      type: 'score:85',
      timestamp: timestamp,
      preferences: preferences,
    );
    service.resetForTesting();
    await service.initialize(preferences: preferences, now: timestamp);

    expect(service.activities, hasLength(1));
    expect(service.activities.single.feature, NotebookFeature.cvCheck);
    expect(service.activities.single.timestamp, timestamp);
    final stored = jsonDecode(
      preferences.getString(ActivityLogService.storageKey)!,
    ) as Map<String, dynamic>;
    expect(stored['version'], ActivityLogService.storageVersion);
  });

  test('prunes activities older than the 180-day retention window', () async {
    final now = DateTime(2026, 4, 15);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      ActivityLogService.storageKey,
      jsonEncode({
        'version': ActivityLogService.storageVersion,
        'activities': [
          NotebookActivity(
            feature: NotebookFeature.cvCheck,
            type: 'old',
            timestamp: now.subtract(const Duration(days: 181)),
          ).toJson(),
          NotebookActivity(
            feature: NotebookFeature.skillDrills,
            type: 'recent',
            timestamp: now.subtract(const Duration(days: 1)),
          ).toJson(),
        ],
      }),
    );

    await service.initialize(preferences: preferences, now: now);

    expect(service.activities, hasLength(1));
    expect(service.activities.single.type, 'recent');
  });

  test('clears only demo activities', () async {
    final preferences = await SharedPreferences.getInstance();
    await service.record(
      feature: NotebookFeature.cvCheck,
      type: 'real',
      timestamp: DateTime(2026, 4, 14),
      preferences: preferences,
    );
    await service.recordDemo([
      NotebookActivity(
        feature: NotebookFeature.events,
        type: 'sample',
        timestamp: DateTime(2026, 4, 15),
      ),
    ], preferences: preferences);

    await service.clearDemo(preferences: preferences);

    expect(service.activities, hasLength(1));
    expect(service.activities.single.type, 'real');
    expect(service.activities.single.demo, isFalse);
  });

  test('readiness is zero when no sources are available', () {
    final result = calculateCareerReadiness(const CareerReadinessInputs());

    expect(result.score, 0);
    expect(result.metrics, isNotEmpty);
    expect(result.metrics.every((metric) => !metric.available), isTrue);
  });

  test('readiness uses weighted, clamped source progress', () {
    final result = calculateCareerReadiness(
      const CareerReadinessInputs(
        cvScore: .8,
        skillDrillsProgress: .5,
        interviewProgress: 1.2,
        weeklyPlanProgress: -.2,
      ),
    );

    expect(result.score, 50);
    expect(
      result.metrics
          .firstWhere((metric) => metric.feature == NotebookFeature.cvCheck)
          .contribution,
      20,
    );
    expect(
      result.metrics
          .firstWhere((metric) => metric.feature == NotebookFeature.interview)
          .contribution,
      20,
    );
  });

  test('period selection provides the expected boundaries for comparison', () {
    final now = DateTime(2026, 4, 15, 13);

    expect(NotebookPeriod.thisWeek.startAt(now), DateTime(2026, 4, 13));
    expect(NotebookPeriod.thisMonth.startAt(now), DateTime(2026, 4));
    expect(NotebookPeriod.all.startAt(now), isNull);

    final current = calculateCareerReadiness(
      const CareerReadinessInputs(cvScore: .8),
    );
    final previous = calculateCareerReadiness(
      const CareerReadinessInputs(cvScore: .6),
    );
    expect(current.score - previous.score, 5);
  });
}
