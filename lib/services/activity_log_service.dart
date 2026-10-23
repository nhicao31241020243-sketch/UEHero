import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notebook_activity.dart';

class ActivityLogService {
  ActivityLogService._();

  static final instance = ActivityLogService._();
  static const storageKey = 'career_notebook_activity_log_v1';
  static const storageVersion = 1;
  static const retention = Duration(days: 180);

  List<NotebookActivity> _activities = const [];
  bool _initialized = false;
  Future<void>? _initializing;

  List<NotebookActivity> get activities => List.unmodifiable(_activities);
  bool get isInitialized => _initialized;

  Future<void> initialize({SharedPreferences? preferences, DateTime? now}) {
    if (_initialized) return Future.value();
    final pending = _initializing;
    if (pending != null) return pending;
    final task = _load(preferences: preferences, now: now);
    _initializing = task;
    return task.whenComplete(() {
      if (!_initialized) _initializing = null;
    });
  }

  Future<void> record({
    required NotebookFeature feature,
    required String type,
    DateTime? timestamp,
    SharedPreferences? preferences,
  }) async {
    await initialize(preferences: preferences);
    final now = timestamp ?? DateTime.now();
    _activities = [
      ..._activities,
      NotebookActivity(feature: feature, type: type, timestamp: now),
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await _persist(preferences: preferences);
  }

  Future<void> recordDemo(
    Iterable<NotebookActivity> activities, {
    SharedPreferences? preferences,
  }) async {
    if (!kDebugMode) {
      throw StateError('Demo activity is only available in debug builds.');
    }
    await initialize(preferences: preferences);
    _activities = [
      ..._activities,
      for (final activity in activities)
        NotebookActivity(
          feature: activity.feature,
          type: activity.type,
          timestamp: activity.timestamp,
          demo: true,
        ),
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await _persist(preferences: preferences);
  }

  Future<void> clearDemo({SharedPreferences? preferences}) async {
    await initialize(preferences: preferences);
    _activities = _activities.where((activity) => !activity.demo).toList();
    await _persist(preferences: preferences);
  }

  Future<void> _load({SharedPreferences? preferences, DateTime? now}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw != null) {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Notebook activity storage must be an object.',
        );
      }
      final version = decoded['version'];
      if (version != storageVersion) {
        throw FormatException(
          'Unsupported notebook activity version: $version',
        );
      }
      final records = decoded['activities'];
      if (records is! List) {
        throw const FormatException('Notebook activities must be a list.');
      }
      _activities = records
          .whereType<Map>()
          .map(
            (record) =>
                NotebookActivity.fromJson(Map<String, dynamic>.from(record)),
          )
          .toList(growable: false);
    }
    await _prune(now: now ?? DateTime.now(), preferences: prefs);
    _initialized = true;
  }

  Future<void> _prune({
    required DateTime now,
    required SharedPreferences preferences,
  }) async {
    final cutoff = now.subtract(retention);
    final retained = _activities
        .where((activity) => !activity.timestamp.isBefore(cutoff))
        .toList(growable: false);
    if (retained.length != _activities.length) {
      _activities = retained;
      await _persist(preferences: preferences);
    }
  }

  Future<void> _persist({SharedPreferences? preferences}) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      storageKey,
      jsonEncode({
        'version': storageVersion,
        'activities': _activities.map((activity) => activity.toJson()).toList(),
      }),
    );
    if (!saved) throw StateError('Could not persist notebook activity log.');
  }

  @visibleForTesting
  void resetForTesting() {
    _activities = const [];
    _initialized = false;
    _initializing = null;
  }
}
