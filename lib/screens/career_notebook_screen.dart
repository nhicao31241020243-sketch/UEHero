import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/notebook_activity.dart';
import '../services/activity_log_service.dart';
import '../services/notebook_repository.dart';
import '../theme/space_theme.dart';
import '../widgets/notebook_components.dart';

class CareerNotebookScreen extends StatefulWidget {
  const CareerNotebookScreen({this.onOpenAction, super.key});

  final ValueChanged<NotebookAction>? onOpenAction;

  @override
  State<CareerNotebookScreen> createState() => _CareerNotebookScreenState();
}

class _CareerNotebookScreenState extends State<CareerNotebookScreen> {
  NotebookPeriod _period = NotebookPeriod.all;
  NotebookDashboardData? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await NotebookRepository.instance.load(period: _period);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadDemo() async {
    final now = DateTime.now();
    final demo = <NotebookActivity>[
      for (var day = 0; day < 14; day++)
        if (day % 3 != 1)
          NotebookActivity(
            feature: NotebookFeature.values[day % 8],
            type: 'demo',
            timestamp: now.subtract(Duration(days: 13 - day)),
            demo: true,
          ),
    ];
    await ActivityLogService.instance.recordDemo(demo);
    await _load();
  }

  Future<void> _clearDemo() async {
    await ActivityLogService.instance.clearDemo();
    await _load();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        if (_loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: SpaceTheme.violet),
            ),
          )
        else if (_error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _NotebookLoadError(message: _error!, onRetry: _load),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
            sliver: SliverList.list(
              children: [
                CareerReadinessCard(
                  result: _data!.readiness,
                  previousScore: _data!.previousReadiness?.score,
                  periodLabel: _period.label,
                  actionLabel: _nextAction.label,
                  onAction: widget.onOpenAction == null
                      ? null
                      : () => widget.onOpenAction!(_nextAction),
                ),
                const SizedBox(height: notebookCardSpacing),
                ActivityLineChart(
                  points: _data!.activityPoints,
                  period: _period,
                ),
                const SizedBox(height: notebookCardSpacing),
                FeatureTimeDonut(items: _data!.distribution),
                if (_data!.sourceWarnings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final warning in _data!.sourceWarnings)
                    _SourceWarning(warning: warning),
                ],
                const SizedBox(height: notebookCardSpacing),
                if (!_data!.hasAnySourceData)
                  _NotebookEmptyBanner(
                    onStart: widget.onOpenAction == null
                        ? null
                        : () => widget.onOpenAction!(NotebookAction.cvCheck),
                  ),
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  _DebugActivityControls(
                    hasDemo: _data!.activities.any((item) => item.demo),
                    onLoad: _loadDemo,
                    onClear: _clearDemo,
                  ),
                ],
              ],
            ),
          ),
      ],
    ),
  );

  NotebookAction get _nextAction {
    final metrics = _data?.readiness.metrics ?? const <ReadinessMetric>[];
    final missing = metrics.where((metric) => !metric.available).toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
    if (missing.isNotEmpty) {
      return switch (missing.first.feature) {
        NotebookFeature.cvCheck => NotebookAction.cvCheck,
        NotebookFeature.skillDrills => NotebookAction.skillDrills,
        NotebookFeature.interview => NotebookAction.interview,
        NotebookFeature.weeklyPlan => NotebookAction.weeklyPlan,
        NotebookFeature.mentor => NotebookAction.mentor,
        NotebookFeature.jobMatch => NotebookAction.jobMatch,
        NotebookFeature.events => NotebookAction.events,
        _ => NotebookAction.cvCheck,
      };
    }
    return NotebookAction.interview;
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 18, 19),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ASTRONAUT ACADEMY',
                style: TextStyle(
                  color: SpaceTheme.textMuted,
                  fontSize: 9,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sổ tay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<NotebookPeriod>(
          initialValue: _period,
          onSelected: (period) {
            setState(() => _period = period);
            _load();
          },
          itemBuilder: (context) => [
            for (final period in NotebookPeriod.values)
              PopupMenuItem(value: period, child: Text(period.label)),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x33212650),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SpaceTheme.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: Color(0xFFD0C9FF),
                ),
                const SizedBox(width: 7),
                Text(
                  _period.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: SpaceTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _NotebookLoadError extends StatelessWidget {
  const _NotebookLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sync_problem_rounded, color: Color(0xFFFFA3A3)),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: SpaceTheme.textSecondary, fontSize: 11),
        ),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}

class _SourceWarning extends StatelessWidget {
  const _SourceWarning({required this.warning});

  final String warning;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      warning,
      style: const TextStyle(color: Color(0xFFFFD08B), fontSize: 9),
    ),
  );
}

class _DebugActivityControls extends StatelessWidget {
  const _DebugActivityControls({
    required this.hasDemo,
    required this.onLoad,
    required this.onClear,
  });

  final bool hasDemo;
  final VoidCallback onLoad;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      TextButton.icon(
        onPressed: onLoad,
        icon: const Icon(Icons.science_outlined, size: 15),
        label: const Text('Nạp dữ liệu demo'),
      ),
      if (hasDemo)
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.delete_outline_rounded, size: 15),
          label: const Text('Xóa demo'),
        ),
    ],
  );
}

class _NotebookEmptyBanner extends StatelessWidget {
  const _NotebookEmptyBanner({required this.onStart});

  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xB91A2044),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: SpaceTheme.glassBorder),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.auto_awesome_rounded,
          color: Color(0xFFBDAAFF),
          size: 19,
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            'Bắt đầu hành trình: thử chấm CV hoặc luyện phỏng vấn đầu tiên.',
            style: TextStyle(
              color: SpaceTheme.textSecondary,
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Bắt đầu',
          onPressed: onStart,
          icon: const Icon(
            Icons.arrow_forward_rounded,
            color: Color(0xFFD6CCFF),
            size: 18,
          ),
        ),
      ],
    ),
  );
}
