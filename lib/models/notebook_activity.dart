import 'package:flutter/material.dart';

enum NotebookPeriod { thisWeek, thisMonth, all }

extension NotebookPeriodLabel on NotebookPeriod {
  String get label => switch (this) {
    NotebookPeriod.thisWeek => 'Tuần này',
    NotebookPeriod.thisMonth => 'Tháng này',
    NotebookPeriod.all => 'Tất cả',
  };

  DateTime? startAt(DateTime now) => switch (this) {
    NotebookPeriod.thisWeek => DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday)),
    NotebookPeriod.thisMonth => DateTime(now.year, now.month),
    NotebookPeriod.all => null,
  };
}

enum NotebookFeature {
  skillDrills('Skill Drills', Color(0xFF9D8BFF)),
  jobMatch('Job Match', Color(0xFF74C9FF)),
  cvCheck('CV Check', Color(0xFF78DEC4)),
  interview('Phỏng vấn AI', Color(0xFFFF8DBA)),
  mentor('UEH Mentor', Color(0xFFFFCA78)),
  events('Events', Color(0xFF8F9CFF)),
  studyBuddy('Study Buddy', Color(0xFF77D9E8)),
  weeklyPlan('Weekly Plan', Color(0xFFC69AFF)),
  other('Khác', Color(0xFF71778E));

  const NotebookFeature(this.label, this.color);

  final String label;
  final Color color;
}

enum NotebookAction {
  cvCheck,
  skillDrills,
  interview,
  jobMatch,
  mentor,
  events,
  studyBuddy,
  weeklyPlan,
}

extension NotebookActionLabel on NotebookAction {
  String get label => switch (this) {
    NotebookAction.cvCheck => 'Chấm CV của bạn',
    NotebookAction.skillDrills => 'Ôn 10 thẻ hôm nay',
    NotebookAction.interview => 'Luyện phỏng vấn',
    NotebookAction.jobMatch => 'Khám phá việc làm',
    NotebookAction.mentor => 'Kết nối mentor',
    NotebookAction.events => 'Khám phá sự kiện',
    NotebookAction.studyBuddy => 'Hỏi Study Buddy',
    NotebookAction.weeklyPlan => 'Mở Weekly Plan',
  };
}

class NotebookActivity {
  const NotebookActivity({
    required this.feature,
    required this.type,
    required this.timestamp,
    this.demo = false,
  });

  final NotebookFeature feature;
  final String type;
  final DateTime timestamp;
  final bool demo;

  Map<String, Object?> toJson() => {
    'feature': feature.name,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    if (demo) 'demo': true,
  };

  factory NotebookActivity.fromJson(Map<String, dynamic> json) =>
      NotebookActivity(
        feature: NotebookFeature.values.firstWhere(
          (feature) => feature.name == json['feature'],
          orElse: () => NotebookFeature.other,
        ),
        type: json['type'] as String? ?? 'activity',
        timestamp: DateTime.parse(json['timestamp'] as String),
        demo: json['demo'] as bool? ?? false,
      );
}

class NotebookActivityPoint {
  const NotebookActivityPoint(this.date, this.count);

  final DateTime date;
  final int count;
}

class NotebookDistributionItem {
  const NotebookDistributionItem(this.feature, this.count);

  final NotebookFeature feature;
  final int count;

  double percentOf(int total) => total == 0 ? 0 : count * 100 / total;
}

class ReadinessMetric {
  const ReadinessMetric({
    required this.feature,
    required this.weight,
    required this.progress,
    required this.available,
  });

  final NotebookFeature feature;
  final int weight;
  final double progress;
  final bool available;

  double get contribution => available ? weight * progress.clamp(0, 1) : 0;
}

class CareerReadinessInputs {
  const CareerReadinessInputs({
    this.cvScore,
    this.skillDrillsProgress,
    this.interviewProgress,
    this.weeklyPlanProgress,
    this.mentorProgress,
    this.jobMatchProgress,
    this.eventsProgress,
  });

  final double? cvScore;
  final double? skillDrillsProgress;
  final double? interviewProgress;
  final double? weeklyPlanProgress;
  final double? mentorProgress;
  final double? jobMatchProgress;
  final double? eventsProgress;
}

class CareerReadinessResult {
  const CareerReadinessResult({required this.score, required this.metrics});

  final int score;
  final List<ReadinessMetric> metrics;
}

class NotebookDashboardData {
  const NotebookDashboardData({
    required this.activities,
    required this.activityPoints,
    required this.distribution,
    required this.readiness,
    required this.previousReadiness,
    required this.hasAnySourceData,
    this.sourceWarnings = const [],
  });

  final List<NotebookActivity> activities;
  final List<NotebookActivityPoint> activityPoints;
  final List<NotebookDistributionItem> distribution;
  final CareerReadinessResult readiness;
  final CareerReadinessResult? previousReadiness;
  final bool hasAnySourceData;
  final List<String> sourceWarnings;
}

const careerReadinessWeights = <NotebookFeature, int>{
  NotebookFeature.cvCheck: 25,
  NotebookFeature.skillDrills: 20,
  NotebookFeature.interview: 20,
  NotebookFeature.weeklyPlan: 10,
  NotebookFeature.mentor: 10,
  NotebookFeature.jobMatch: 10,
  NotebookFeature.events: 5,
};

CareerReadinessResult calculateCareerReadiness(CareerReadinessInputs input) {
  final progressByFeature = <NotebookFeature, double?>{
    NotebookFeature.cvCheck: input.cvScore,
    NotebookFeature.skillDrills: input.skillDrillsProgress,
    NotebookFeature.interview: input.interviewProgress,
    NotebookFeature.weeklyPlan: input.weeklyPlanProgress,
    NotebookFeature.mentor: input.mentorProgress,
    NotebookFeature.jobMatch: input.jobMatchProgress,
    NotebookFeature.events: input.eventsProgress,
  };
  final metrics = [
    for (final entry in careerReadinessWeights.entries)
      ReadinessMetric(
        feature: entry.key,
        weight: entry.value,
        progress: progressByFeature[entry.key] ?? 0,
        available: progressByFeature[entry.key] != null,
      ),
  ];
  final score = metrics.fold<double>(
    0,
    (total, metric) => total + metric.contribution,
  );
  return CareerReadinessResult(
    score: score.round().clamp(0, 100),
    metrics: List.unmodifiable(metrics),
  );
}

List<NotebookDistributionItem> notebookDistribution(
  Iterable<NotebookActivity> activities,
) {
  final counts = <NotebookFeature, int>{};
  for (final activity in activities) {
    counts.update(activity.feature, (value) => value + 1, ifAbsent: () => 1);
  }
  final total = counts.values.fold<int>(0, (sum, value) => sum + value);
  if (total == 0) return const [];
  final small = <NotebookFeature>[];
  final items = <NotebookDistributionItem>[];
  for (final feature in NotebookFeature.values) {
    if (feature == NotebookFeature.other) continue;
    final count = counts[feature] ?? 0;
    if (count == 0) continue;
    if (count * 100 / total < 5) {
      small.add(feature);
    } else {
      items.add(NotebookDistributionItem(feature, count));
    }
  }
  if (small.isNotEmpty) {
    final otherCount = small.fold<int>(
      0,
      (sum, feature) => sum + counts[feature]!,
    );
    items.add(NotebookDistributionItem(NotebookFeature.other, otherCount));
  }
  return List.unmodifiable(items);
}
