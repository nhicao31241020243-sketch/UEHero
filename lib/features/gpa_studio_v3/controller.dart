import 'package:flutter/foundation.dart';

import 'scenario.dart';

/// One source of truth for every control. Drag preview is reversible.
class StudioController extends ChangeNotifier {
  StudioScenario _committed;
  final List<StudioScenario> _undo = [];
  late String selectedId;
  String? _draftCourseId;
  int? _draftGrade;
  int? _draftTarget;
  String lastAction = 'Balanced demo loaded';
  double? lastImpact;
  String? activePreset = 'Balanced';

  StudioController({StudioScenario? initial})
    : _committed = initial ?? StudioScenario.demo() {
    selectedId = _committed.courses.first.id;
  }

  StudioScenario get committed => _committed;
  bool get hasPreview => _draftCourseId != null || _draftTarget != null;
  bool get canUndo => _undo.isNotEmpty;
  String? get draftCourseId => _draftCourseId;
  StudioScenario get display {
    var result = _committed;
    if (_draftCourseId != null && _draftGrade != null) {
      result = result.setGrade(_draftCourseId!, _draftGrade);
    }
    if (_draftTarget != null) result = result.copy(targetUnits: _draftTarget);
    return result;
  }

  void select(String id) {
    _committed.course(id);
    if (selectedId == id) return;
    _clearDraft();
    selectedId = id;
    notifyListeners();
  }

  void previewGrade(String id, int units) {
    _committed.course(id);
    StudioGrade.fromUnits(units);
    selectedId = id;
    _draftTarget = null;
    _draftCourseId = id;
    _draftGrade = units;
    notifyListeners();
  }

  void previewTarget(int units) {
    if (units < 200 || units > 400) throw ArgumentError('Target outside 2–4');
    _draftCourseId = null;
    _draftGrade = null;
    _draftTarget = units;
    notifyListeners();
  }

  void commitPreview() {
    if (!hasPreview) return;
    final next = display;
    final message = _draftTarget != null
        ? 'Target set to ${next.target.toStringAsFixed(2)}'
        : '${next.course(_draftCourseId!).code} → '
              '${StudioGrade.fromUnits(_draftGrade!).label}';
    _commit(next, message);
  }

  void cancelPreview() {
    if (!hasPreview) return;
    _clearDraft();
    notifyListeners();
  }

  void setGrade(String id, int? units) {
    selectedId = _committed.course(id).id;
    final label = units == null
        ? 'Unplanned'
        : StudioGrade.fromUnits(units).label;
    _commit(
      _committed.setGrade(id, units),
      '${_committed.course(id).code} → $label',
    );
  }

  void setTarget(int units) => _commit(
    _committed.copy(targetUnits: units),
    'Target ${(units / 100).toStringAsFixed(2)}',
  );

  void preset(String name) {
    final Map<String, int> next;
    switch (name) {
      case 'Blank':
        next = <String, int>{};
        break;
      case 'All A':
        next = {for (final c in _committed.courses) c.id: 400};
        break;
      case 'Balanced':
      case 'Stretch':
        final values = name == 'Balanced'
            ? [350, 350, 400, 300, 350, 400]
            : [400, 350, 400, 350, 350, 400];
        next = {
          for (var i = 0; i < _committed.courses.length; i++)
            _committed.courses[i].id: values[i % values.length],
        };
        break;
      default:
        throw ArgumentError.value(name, 'name', 'Unknown preset');
    }
    _commit(_committed.copy(grades: next), '$name demo loaded', preset: name);
  }

  void undo() {
    _clearDraft();
    if (_undo.isEmpty) {
      notifyListeners();
      return;
    }
    final before = _committed.projectedGpa;
    _committed = _undo.removeLast();
    activePreset = null;
    lastAction = 'Last change undone';
    lastImpact = _committed.projectedGpa - before;
    notifyListeners();
  }

  void _clearDraft() {
    _draftCourseId = null;
    _draftGrade = null;
    _draftTarget = null;
  }

  void _commit(StudioScenario next, String message, {String? preset}) {
    final same =
        next.targetUnits == _committed.targetUnits &&
        mapEquals(next.grades, _committed.grades);
    _clearDraft();
    if (same) {
      activePreset = preset ?? activePreset;
      lastAction = 'No change';
      lastImpact = null;
      notifyListeners();
      return;
    }
    _undo.add(_committed);
    if (_undo.length > 30) _undo.removeAt(0);
    lastImpact = next.projectedGpa - _committed.projectedGpa;
    _committed = next;
    activePreset = preset;
    lastAction = message;
    notifyListeners();
  }
}
