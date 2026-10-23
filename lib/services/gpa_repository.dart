import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gpa_models.dart';

class GpaRepository extends ChangeNotifier {
  GpaRepository._();

  static final instance = GpaRepository._();
  static const _storageKey = 'astronaut_gpa_log_v1';
  static const _goalKey = 'astronaut_gpa_goal_v1';
  static const _programCreditsKey = 'astronaut_gpa_program_credits_v1';
  static const _careerCvConsentKey = 'astronaut_gpa_cv_consent_v1';

  List<GpaSemester> _semesters = const [];
  double _goalGpa = 3.2;
  int _programCredits = 120;
  String? _careerGoal;
  bool _cvConsent = false;
  bool _loaded = false;
  Future<void>? _loading;

  List<GpaSemester> get semesters => List.unmodifiable(_semesters);
  double get goalGpa => _goalGpa;
  int get programCredits => _programCredits;
  String? get careerGoal => _careerGoal;
  bool get isLoaded => _loaded;
  GpaSnapshot get snapshot => GpaSnapshot.fromSemesters(_semesters);
  double? get gpaForCv =>
      _cvConsent && snapshot.earnedCredits > 0 ? snapshot.currentGpa : null;
  bool get cvConsent => _cvConsent;

  Future<void> load({SharedPreferences? preferences}) {
    if (_loaded) return Future.value();
    final active = _loading;
    if (active != null) return active;
    final loading = _load(preferences);
    _loading = loading;
    return loading.whenComplete(() {
      if (!_loaded) _loading = null;
    });
  }

  Future<void> _load(SharedPreferences? preferences) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _semesters = decoded
              .whereType<Map<String, dynamic>>()
              .map(GpaSemester.fromJson)
              .toList(growable: false);
        } else {
          throw const FormatException('GPA log must be a list.');
        }
      } on FormatException catch (error) {
        throw FormatException('Could not read saved GPA log: $error');
      } on TypeError catch (error) {
        throw FormatException('Saved GPA log has an invalid record: $error');
      }
    }
    _goalGpa = prefs.getDouble(_goalKey) ?? 3.2;
    _programCredits = prefs.getInt(_programCreditsKey) ?? 120;
    _careerGoal = prefs.getString('career_goal');
    _cvConsent = prefs.getBool(_careerCvConsentKey) ?? false;
    _loaded = true;
    _loading = null;
    notifyListeners();
  }

  Future<void> createSemester(String name, {DateTime? createdAt}) async {
    _ensureLoaded();
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name');
    final semester = GpaSemester(
      id: 'semester-${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
      createdAt: createdAt ?? DateTime.now(),
      courses: const [],
    );
    await _save([..._semesters, semester]);
  }

  Future<void> renameSemester(String semesterId, String name) async {
    _ensureLoaded();
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name');
    final index = _semesters.indexWhere(
      (semester) => semester.id == semesterId,
    );
    if (index < 0) throw ArgumentError.value(semesterId, 'semesterId');
    final next = List<GpaSemester>.of(_semesters);
    next[index] = next[index].copyWith(name: trimmed);
    await _save(next);
  }

  Future<void> deleteSemester(String semesterId) async {
    _ensureLoaded();
    await _save(_semesters.where((s) => s.id != semesterId).toList());
  }

  Future<void> completeSemester(String semesterId) async {
    _ensureLoaded();
    final index = _semesters.indexWhere(
      (semester) => semester.id == semesterId,
    );
    if (index < 0) throw ArgumentError.value(semesterId, 'semesterId');
    final next = List<GpaSemester>.of(_semesters);
    next[index] = next[index].copyWith(isCompleted: true);
    await _save(next);
  }

  Future<void> saveCourse(String semesterId, GpaCourse course) async {
    _ensureLoaded();
    final index = _semesters.indexWhere((s) => s.id == semesterId);
    if (index < 0) throw ArgumentError.value(semesterId, 'semesterId');
    if (course.name.trim().isEmpty ||
        course.credits < 1 ||
        course.credits > 30) {
      throw ArgumentError('Course needs a name and between 1 and 30 credits.');
    }
    final semester = _semesters[index];
    final courses = [...semester.courses];
    final courseIndex = courses.indexWhere((entry) => entry.id == course.id);
    if (courseIndex < 0) {
      courses.add(course);
    } else {
      courses[courseIndex] = course;
    }
    final next = List<GpaSemester>.of(_semesters);
    next[index] = semester.copyWith(courses: courses);
    await _save(next);
  }

  Future<void> deleteCourse(String semesterId, String courseId) async {
    _ensureLoaded();
    final index = _semesters.indexWhere((s) => s.id == semesterId);
    if (index < 0) throw ArgumentError.value(semesterId, 'semesterId');
    final next = List<GpaSemester>.of(_semesters);
    next[index] = next[index].copyWith(
      courses: next[index].courses.where((c) => c.id != courseId).toList(),
    );
    await _save(next);
  }

  Future<void> setGoal(double goal, {int? programCredits}) async {
    _ensureLoaded();
    if (goal < 0 || goal > 4) throw ArgumentError.value(goal, 'goal');
    if (programCredits != null && programCredits < 1) {
      throw ArgumentError.value(programCredits, 'programCredits');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_goalKey, goal);
    if (programCredits != null) {
      await prefs.setInt(_programCreditsKey, programCredits);
      _programCredits = programCredits;
    }
    _goalGpa = goal;
    notifyListeners();
  }

  Future<void> setCvConsent(bool allowed) async {
    _ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_careerCvConsentKey, allowed);
    _cvConsent = allowed;
    notifyListeners();
  }

  Future<void> _save(List<GpaSemester> semesters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(semesters.map((semester) => semester.toJson()).toList()),
    );
    _semesters = List.unmodifiable(semesters);
    _careerGoal = prefs.getString('career_goal');
    notifyListeners();
  }

  void _ensureLoaded() {
    if (!_loaded) throw StateError('GPA repository has not been loaded.');
  }

  @visibleForTesting
  void resetForTesting() {
    _semesters = const [];
    _goalGpa = 3.2;
    _programCredits = 120;
    _careerGoal = null;
    _cvConsent = false;
    _loaded = false;
    _loading = null;
  }
}
