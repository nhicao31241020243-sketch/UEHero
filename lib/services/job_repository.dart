import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/job_demo_data.dart';
import '../models/student_job.dart';
import '../models/xp_entry.dart';
import 'points_manager.dart';

class JobRepository {
  JobRepository._();

  static final instance = JobRepository._();
  static const _statusesKey = 'student_job_statuses';

  Map<String, JobApplicationStatus> _statuses = {};
  bool _initialized = false;

  Set<String> get savedJobIds => {
    for (final entry in _statuses.entries)
      if (entry.value == JobApplicationStatus.saved) entry.key,
  };

  Set<String> get appliedJobIds => {
    for (final entry in _statuses.entries)
      if (entry.value == JobApplicationStatus.applied ||
          entry.value == JobApplicationStatus.interview ||
          entry.value == JobApplicationStatus.result)
        entry.key,
  };

  Future<void> initialize({SharedPreferences? preferences}) async {
    if (_initialized) return;
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_statusesKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Saved job statuses must be a map.');
      }
      _statuses = {
        for (final entry in decoded.entries)
          entry.key: JobApplicationStatus.fromName(entry.value?.toString()),
      };
    }
    // This project calls the unified XP ledger PointsManager, not XpService.
    PointsManager.dailyCaps.putIfAbsent('job_save', () => 15);
    _initialized = true;
  }

  // Gắn nguồn việc làm khác trong tương lai thì chỉ cần thay đổi tại đây.
  Future<List<StudentJob>> getJobs() async {
    await initialize();
    return List.unmodifiable(jobDemoData);
  }

  Future<List<StudentJob>> refresh() async {
    await initialize();
    return List.unmodifiable(jobDemoData);
  }

  Future<JobApplicationStatus?> statusFor(String jobId) async {
    await initialize();
    return _statuses[jobId];
  }

  Future<bool> toggleSaved(String jobId) async {
    await initialize();
    if (_statuses[jobId] == JobApplicationStatus.saved) {
      _statuses.remove(jobId);
      await _persist();
      return false;
    }
    await PointsManager.instance.addXP(
      thanh: XpBar.thucChien,
      skill: null,
      luong: 3,
      nguon: 'job_save',
      sourceRef: jobId,
    );
    _statuses[jobId] = JobApplicationStatus.saved;
    await _persist();
    return true;
  }

  Future<void> setApplied(String jobId) async {
    await initialize();
    _statuses[jobId] = JobApplicationStatus.applied;
    await _persist();
  }

  Future<void> setStatus(String jobId, JobApplicationStatus status) async {
    await initialize();
    _statuses[jobId] = status;
    await _persist();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _statusesKey,
      jsonEncode({
        for (final entry in _statuses.entries) entry.key: entry.value.name,
      }),
    );
  }

  void resetForTesting() {
    _statuses = {};
    _initialized = false;
  }
}
