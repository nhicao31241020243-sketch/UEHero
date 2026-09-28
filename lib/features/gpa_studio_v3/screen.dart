import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'scenario.dart';
import 'theme.dart';
import 'visuals.dart';

class GpaStudioV3App extends StatelessWidget {
  const GpaStudioV3App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'UEHero · Semester Studio',
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: StudioTheme.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: StudioTheme.wine,
        brightness: Brightness.light,
        surface: StudioTheme.surface,
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        activeTrackColor: StudioTheme.wine,
        inactiveTrackColor: StudioTheme.line,
        thumbColor: StudioTheme.wine,
        overlayColor: Color(0x159A4358),
      ),
    ),
    home: const StudioScreen(),
  );
}

class StudioScreen extends StatefulWidget {
  final StudioController? controller;
  const StudioScreen({super.key, this.controller});
  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen>
    with WidgetsBindingObserver {
  late final StudioController controller;
  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? StudioController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) controller.cancelPreview();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  Future<void> _showChart() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: StudioTheme.surface,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .80,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, child) {
              final s = controller.display;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Course grades',
                            style: StudioTheme.text(
                              22,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close chart',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    Text(
                      'Drag vertically · fixed 0–4 scale · release to keep',
                      style: StudioTheme.text(12, color: StudioTheme.muted),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StudioGradeChart(
                        controller: controller,
                        expanded: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${s.course(controller.selectedId).name}  ·  '
                      '${s.grades[controller.selectedId] == null ? 'Unplanned' : StudioGrade.fromUnits(s.grades[controller.selectedId]!).label}',
                      style: StudioTheme.text(16, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${controller.hasPreview ? 'Preview' : 'Projected'} '
                      '${s.projectedGpa.toStringAsFixed(3)}  ·  '
                      '${s.plannedCount}/${s.courses.length} courses planned',
                      style: StudioTheme.text(13, color: StudioTheme.wine),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: controller.canUndo
                              ? controller.undo
                              : null,
                          child: const Text('Undo'),
                        ),
                        TextButton(
                          onPressed: () =>
                              controller.setGrade(controller.selectedId, null),
                          child: const Text('Clear selected'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    if (mounted) controller.cancelPreview();
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(
        ClipboardData(
          text: const JsonEncoder.withIndent('  ')
              .convert(controller.committed.toJson()),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Committed scenario copied as JSON')),
      );
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard is unavailable on this device'),
        ),
      );
    }
  }

  void _demoInfo() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Synthetic demo data'),
      content: SingleChildScrollView(
        child: Text(
          'This is a demonstration, not your transcript.\n\n'
          'Base: 77 completed credits, 267.19 quality points, current GPA 3.47. '
          'Six future courses total 20 credits. Target is cumulative GPA at the end '
          'of these 20 credits, not graduation.\n\n'
          'Demo grade scale: F 0.0, D 1.0, D+ 1.5, C 2.0, C+ 2.5, '
          'B 3.0, B+ 3.5, A- 3.7, A 4.0. This is not asserted to be the official UEH scale.\n\n'
          'Unplanned courses are excluded from the partial GPA. A grade F is included '
          'with zero quality points and its full credits.\n\n'
          'Changes are held in this session. Copy scenario exports the committed '
          'values as JSON. The old Blender/Forge2D preview is preserved separately.',
          style: StudioTheme.text(14),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final s = controller.display;
          return SingleChildScrollView(
            key: const ValueKey('studio-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UEHERO / SEMESTER STUDIO',
                                style: StudioTheme.text(
                                  10,
                                  color: StudioTheme.muted,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'GPA Journey',
                                style: StudioTheme.text(
                                  28,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _demoInfo,
                          style: TextButton.styleFrom(
                            backgroundColor: StudioTheme.line,
                            foregroundColor: StudioTheme.wine,
                            minimumSize: const Size(68, 44),
                          ),
                          child: const Text('DEMO'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(width: 7),
                          Expanded(
                            child: _PresetButton(
                              name: const [
                                'Blank',
                                'Balanced',
                                'Stretch',
                                'All A',
                              ][i],
                              selected:
                                  controller.activePreset ==
                                  const [
                                    'Blank',
                                    'Balanced',
                                    'Stretch',
                                    'All A',
                                  ][i],
                              onTap: () => controller.preset(
                                const [
                                  'Blank',
                                  'Balanced',
                                  'Stretch',
                                  'All A',
                                ][i],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _forecast(s),
                    const SizedBox(height: 16),
                    _target(s),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Text(
                          'YOUR COURSES',
                          style: StudioTheme.text(
                            11,
                            color: StudioTheme.muted,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${s.totalFutureCredits} credits · fixed order',
                          style: StudioTheme.text(11, color: StudioTheme.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < s.courses.length; i++) ...[
                            if (i > 0) const SizedBox(width: 7),
                            StudioCourseButton(
                              course: s.courses[i],
                              units: s.grades[s.courses[i].id],
                              selected:
                                  controller.selectedId == s.courses[i].id,
                              onTap: () => controller.select(s.courses[i].id),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _editor(s),
                    const SizedBox(height: 16),
                    _goalCards(s),
                    const SizedBox(height: 16),
                    _explanation(s),
                    const SizedBox(height: 12),
                    Text(
                      'SYNTHETIC DEMO · 77 completed credits at 3.47.\n'
                      'No transcript or official institutional grade scale is implied.',
                      style: StudioTheme.text(10, color: StudioTheme.muted),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _forecast(StudioScenario s) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    decoration: StudioTheme.card(radius: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);

            final compact = constraints.maxWidth < 300 || textScale > 1.20;

            final title = Text(
              controller.hasPreview
                  ? 'LIVE PREVIEW'
                  : s.isComplete
                  ? 'SEMESTER FORECAST'
                  : 'PARTIAL FORECAST',
              style: StudioTheme.text(
                10,
                color: StudioTheme.muted,
                weight: FontWeight.w700,
              ),
            );

            final planned = Text(
              '${s.plannedCount} / ${s.courses.length} planned',
              style: StudioTheme.text(11, color: StudioTheme.muted),
            );

            final expand = IconButton(
              key: const ValueKey('expand-chart'),
              tooltip: 'Expand interactive chart',
              visualDensity: VisualDensity.compact,
              onPressed: _showChart,
              icon: const Icon(Icons.open_in_full_rounded, size: 17),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: title),
                      expand,
                    ],
                  ),
                  const SizedBox(height: 2),
                  planned,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: title),
                planned,
                expand,
              ],
            );
          },
        ),

        LayoutBuilder(
          builder: (context, constraints) {
            final chart = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COURSE GRADES',
                  style: StudioTheme.text(
                    10,
                    weight: FontWeight.w700,
                    color: StudioTheme.muted,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 176,
                  child: StudioGradeChart(controller: controller),
                ),
              ],
            );

            final dial = StudioDial(
              scenario: s,
              preview: controller.hasPreview,
            );

            if (constraints.maxWidth < 316) {
              return Column(
                children: [dial, const SizedBox(height: 12), chart],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 148, child: dial),
                const SizedBox(width: 10),
                Expanded(child: chart),
              ],
            );
          },
        ),

        const SizedBox(height: 10),

        Text(
          'Drag a column up or down to try another grade.',
          style: StudioTheme.text(11, color: StudioTheme.muted),
        ),

        const SizedBox(height: 5),

        Text(
          '${_signed(s.projectedGpa - s.currentGpa)} vs current · '
          '${s.plannedCredits} / ${s.totalFutureCredits} credits planned',
          style: StudioTheme.text(11, color: StudioTheme.mint),
        ),

        const SizedBox(height: 7),

        Text(
          controller.hasPreview
              ? 'Preview only — release to keep; cancel to restore.'
              : !s.isComplete
              ? 'Partial estimate — not the GPA of the whole future term.'
              : s.fullScenarioMeetsTarget
              ? 'Target reached in this scenario.'
              : !s.targetPossibleFromBase
              ? 'Target is beyond the all-A ceiling for this term.'
              : 'Below target. Try a higher grade or another scenario.',
          key: const ValueKey('forecast-status'),
          style: StudioTheme.text(
            11,
            weight: FontWeight.w700,
            color: s.fullScenarioMeetsTarget
                ? StudioTheme.mint
                : StudioTheme.wine,
          ),
        ),
      ],
    ),
  );

  Widget _target(StudioScenario s) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    decoration: StudioTheme.card(radius: 22),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your target',
                    style: StudioTheme.text(15, weight: FontWeight.w700),
                  ),
                  Text(
                    'Cumulative GPA after this demo term',
                    style: StudioTheme.text(11, color: StudioTheme.muted),
                  ),
                ],
              ),
            ),
            Text(
              s.target.toStringAsFixed(2),
              style: StudioTheme.text(
                24,
                weight: FontWeight.w800,
                color: StudioTheme.wine,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text('2.0', style: StudioTheme.text(10, color: StudioTheme.muted)),
            Expanded(
              child: Slider(
                key: const ValueKey('target-slider'),
                min: 2,
                max: 4,
                divisions: 200,
                value: s.target,
                label: s.target.toStringAsFixed(2),
                semanticFormatterCallback: (value) =>
                    'Target GPA ${value.toStringAsFixed(2)}',
                onChanged: (value) =>
                    controller.previewTarget((value * 100).round()),
                onChangeEnd: (value) => controller.commitPreview(),
              ),
            ),
            Text('4.0', style: StudioTheme.text(10, color: StudioTheme.muted)),
          ],
        ),
      ],
    ),
  );

  Widget _editor(StudioScenario s) {
    final c = s.course(controller.selectedId);
    final units = s.grades[c.id];
    final gradeLabel = units == null
        ? 'Unplanned'
        : '${StudioGrade.fromUnits(units).label} · ${(units / 100).toStringAsFixed(2)}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      key: const ValueKey('selected-course-name'),
                      style: StudioTheme.text(17, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.credits} credits · selected course',
                      style: StudioTheme.text(11, color: StudioTheme.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 116),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: StudioTheme.wine,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    gradeLabel,
                    style: StudioTheme.text(
                      12,
                      color: StudioTheme.surface,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap a grade, or drag its column above.',
            style: StudioTheme.text(12, color: StudioTheme.muted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final grade in StudioGrade.values)
                Semantics(
                  selected: units == grade.units,
                  button: true,
                  label: '${grade.label}, ${grade.point} grade points',
                  child: _GradeChoice(
                    grade: grade,
                    selected: units == grade.units,
                    onTap: () => controller.setGrade(c.id, grade.units),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                key: const ValueKey('clear-grade'),
                onPressed: units == null
                    ? null
                    : () => controller.setGrade(c.id, null),
                child: const Text('Clear grade'),
              ),
              TextButton(
                key: const ValueKey('undo'),
                onPressed: controller.canUndo ? controller.undo : null,
                child: const Text('Undo'),
              ),
              TextButton(onPressed: _copy, child: const Text('Copy scenario')),
            ],
          ),
          const Divider(color: StudioTheme.line),
          Text(
            controller.hasPreview
                ? 'Preview · no grade committed yet'
                : controller.lastAction +
                      (controller.lastImpact == null
                          ? ''
                          : ' · ${_signed(controller.lastImpact!)} GPA'),
            style: StudioTheme.text(11, color: StudioTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _goalCards(StudioScenario s) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _GoalCard(
            title: 'MEAN NEEDED',
            value: math.max(0.0, s.requiredWholeTermMean).toStringAsFixed(2),
            detail: 'Across all ${s.totalFutureCredits} future credits',
            note: s.targetPossibleFromBase
                ? 'Target ${s.target.toStringAsFixed(2)} cumulative'
                : 'Above the 4.00 limit',
            color: StudioTheme.apricot,
            textColor: StudioTheme.ink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GoalCard(
            title: 'TERM CEILING',
            value: s.allACeiling.toStringAsFixed(2),
            detail: 'All ${s.courses.length} courses at A',
            note: '${s.allACeiling.toStringAsFixed(4)} before rounding',
            color: StudioTheme.plum,
            textColor: StudioTheme.surface,
          ),
        ),
      ],
    ),
  );

  Widget _explanation(StudioScenario s) {
    final plan = s.minimumACreditPlan;
    final required = s.requiredUnplannedMean;
    final remainingMessage = required == null
        ? ''
        : required <= 0
        ? 'The target is secure under these assumptions.'
        : 'The remaining ${s.unplannedCredits} credits need a '
              '${required.toStringAsFixed(2)} average.';
    final route = plan == null
        ? 'This target cannot be reached within these future credits.'
        : plan.credits == 0
        ? 'An all-B+ term would meet this target.'
        : 'One route: ${plan.credits} credits at A + '
              '${s.totalFutureCredits - plan.credits} credits at B+.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          route,
          style: StudioTheme.text(
            12,
            color: StudioTheme.wine,
            weight: FontWeight.w700,
          ),
        ),
        if (plan != null && plan.credits > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Example: ${plan.courseIds.map((id) => s.course(id).code).join(', ')} at A. '
            'This is an alternative full-term plan, not your current assignments.',
            style: StudioTheme.text(11, color: StudioTheme.muted),
          ),
        ],
        if (!s.isComplete) ...[
          const SizedBox(height: 10),
          Text(
            'Completion range: ${s.termFloor.toStringAsFixed(3)}–'
            '${s.termCeilingWithPlan.toStringAsFixed(3)}',
            style: StudioTheme.text(12, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Keeps assigned grades fixed; remaining courses range from F to A. '
            '$remainingMessage',
            style: StudioTheme.text(11, color: StudioTheme.muted),
          ),
          if (!s.targetPossibleWithPlan)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Some already-assigned grades or the target must change.',
                style: StudioTheme.text(
                  11,
                  color: StudioTheme.wine,
                  weight: FontWeight.w700,
                ),
              ),
            ),
        ],
        const SizedBox(height: 8),
        Text(
          'Feasibility uses unrounded values. This is a term scenario, '
          'not a graduation forecast.',
          style: StudioTheme.text(10, color: StudioTheme.muted),
        ),
      ],
    );
  }
}

String _signed(double value) {
  if (value.abs() < 0.0000001) return '0.00';
  final sign = value > 0 ? '+' : '−';
  if (value.abs() < .005) return '$sign<0.01';
  return '$sign${value.abs().toStringAsFixed(2)}';
}

class _PresetButton extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const _PresetButton({
    required this.name,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: TextButton(
      key: ValueKey('preset-$name'),
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        backgroundColor: selected ? StudioTheme.ink : StudioTheme.surface,
        foregroundColor: selected ? StudioTheme.surface : StudioTheme.muted,
      ),
      child: Text(
        name,
        maxLines: 1,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _GradeChoice extends StatelessWidget {
  final StudioGrade grade;
  final bool selected;
  final VoidCallback onTap;
  const _GradeChoice({
    required this.grade,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 50,
    height: 44,
    child: TextButton(
      key: ValueKey('grade-${grade.label}'),
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: selected ? StudioTheme.wine : StudioTheme.canvas,
        foregroundColor: selected ? StudioTheme.surface : StudioTheme.ink,
      ),
      child: Text(
        grade.label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _GoalCard extends StatelessWidget {
  final String title;
  final String value;
  final String detail;
  final String note;
  final Color color;
  final Color textColor;
  const _GoalCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.note,
    required this.color,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: StudioTheme.text(
            10,
            color: textColor,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: StudioTheme.text(
              34,
              color: textColor,
              weight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(detail, style: StudioTheme.text(11, color: textColor)),
        const SizedBox(height: 5),
        Text(note, style: StudioTheme.text(10, color: textColor)),
      ],
    ),
  );
}
