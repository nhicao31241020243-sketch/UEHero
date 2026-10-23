import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/notebook_activity.dart';
import '../theme/space_theme.dart';

const notebookCardSpacing = 16.0;

class CareerReadinessCard extends StatelessWidget {
  const CareerReadinessCard({
    required this.result,
    required this.previousScore,
    required this.periodLabel,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final CareerReadinessResult result;
  final int? previousScore;
  final String periodLabel;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final delta = previousScore == null ? null : result.score - previousScore!;
    return _NotebookCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Điểm sẵn sàng nghề nghiệp',
            subtitle: periodLabel,
            icon: Icons.radar_rounded,
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: result.score / 100),
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CustomPaint(
                    painter: _ReadinessRingPainter(value),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${result.score}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'READINESS',
                            style: TextStyle(
                              color: SpaceTheme.textMuted,
                              fontSize: 8,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          delta == null
                              ? Icons.remove_rounded
                              : delta >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: delta == null
                              ? SpaceTheme.textMuted
                              : delta >= 0
                              ? const Color(0xFF78DEC4)
                              : const Color(0xFFFF8DBA),
                          size: 17,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            delta == null
                                ? 'Chưa có kỳ trước'
                                : '${delta >= 0 ? '+' : ''}$delta% so kỳ trước',
                            maxLines: 2,
                            style: const TextStyle(
                              color: SpaceTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _readinessComment(result.score),
                      style: const TextStyle(
                        color: SpaceTheme.textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.rocket_launch_rounded, size: 14),
                      label: Text(
                        actionLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD8CCFF),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'CÁC NGUỒN ĐÓNG GÓP',
            style: TextStyle(
              color: SpaceTheme.textMuted,
              fontSize: 8,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final metric in result.metrics)
                _ReadinessPill(metric: metric),
            ],
          ),
        ],
      ),
    );
  }
}

class ActivityLineChart extends StatefulWidget {
  const ActivityLineChart({
    required this.points,
    required this.period,
    super.key,
  });

  final List<NotebookActivityPoint> points;
  final NotebookPeriod period;

  @override
  State<ActivityLineChart> createState() => _ActivityLineChartState();
}

class _ActivityLineChartState extends State<ActivityLineChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant ActivityLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) _selectedIndex = null;
  }

  @override
  Widget build(BuildContext context) => _NotebookCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Hoạt động',
          subtitle: widget.period.label,
          icon: Icons.show_chart_rounded,
        ),
        const SizedBox(height: 12),
        if (widget.points.isEmpty)
          const _ChartEmpty(
            icon: Icons.timeline_rounded,
            message: 'Bắt đầu hành trình: thử chấm CV hoặc luyện phỏng vấn đầu tiên.',
          )
        else ...[
          SizedBox(
            height: 190,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: math.max(1, widget.points.length - 1).toDouble(),
                minY: 0,
                maxY: math
                    .max(
                      1,
                      widget.points
                          .map((point) => point.count)
                          .fold<int>(0, math.max),
                    )
                    .toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: math
                      .max(
                        1,
                        widget.points
                                .map((point) => point.count)
                                .fold<int>(0, math.max) /
                            3,
                      )
                      .toDouble(),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: .08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      interval: math
                          .max(1, (widget.points.length - 1) / 4)
                          .toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= widget.points.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 7,
                          child: Text(
                            _xLabel(widget.points[index].date, widget.period),
                            style: const TextStyle(
                              color: SpaceTheme.textMuted,
                              fontSize: 8,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(9),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          '${widget.points[spot.spotIndex].date.day}/'
                          '${widget.points[spot.spotIndex].date.month}'
                          ' · ${spot.y.round()} hoạt động',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions) return;
                    final spots = response?.lineBarSpots;
                    if (spots == null || spots.isEmpty) return;
                    setState(() => _selectedIndex = spots.first.spotIndex);
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var index = 0; index < widget.points.length; index++)
                        FlSpot(
                          widget.points.length == 1 ? .5 : index.toDouble(),
                          widget.points[index].count.toDouble(),
                        ),
                    ],
                    isCurved: true,
                    curveSmoothness: .28,
                    color: const Color(0xFFA993FF),
                    barWidth: 2.7,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: _selectedIndex == index ? 4 : 2.4,
                            color: _selectedIndex == index
                                ? Colors.white
                                : const Color(0xFFBDB1FF),
                            strokeWidth: _selectedIndex == index ? 2 : 0,
                            strokeColor: const Color(0x559D8BFF),
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF9D8BFF).withValues(alpha: .3),
                          const Color(0xFF5F74DA).withValues(alpha: .01),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ],
    ),
  );
}

class FeatureTimeDonut extends StatefulWidget {
  const FeatureTimeDonut({required this.items, super.key});

  final List<NotebookDistributionItem> items;

  @override
  State<FeatureTimeDonut> createState() => _FeatureTimeDonutState();
}

class _FeatureTimeDonutState extends State<FeatureTimeDonut> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final total = items.fold<int>(0, (sum, item) => sum + item.count);
    final selected = _selectedIndex != null && _selectedIndex! < items.length
        ? items[_selectedIndex!]
        : null;
    return _NotebookCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Thời gian theo tính năng',
            subtitle: 'Phân bổ hoạt động',
            icon: Icons.donut_small_rounded,
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const _ChartEmpty(
              icon: Icons.pie_chart_outline_rounded,
              message: 'Hoạt động sẽ được phân bổ tại đây khi bạn bắt đầu.',
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 142,
                  height: 142,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 43,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              if (!event.isInterestedForInteractions) return;
                              final index =
                                  response?.touchedSection?.touchedSectionIndex;
                              if (index != null && index >= 0) {
                                setState(() => _selectedIndex = index);
                              }
                            },
                          ),
                          sections: [
                            for (var index = 0; index < items.length; index++)
                              PieChartSectionData(
                                value: items[index].count.toDouble(),
                                color: items[index].feature.color,
                                radius: _selectedIndex == index ? 20 : 16,
                                showTitle: false,
                              ),
                          ],
                        ),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                      ),
                      IgnorePointer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selected == null
                                  ? '$total'
                                  : '${selected.percentOf(total).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              selected?.feature.label ?? 'HOẠT ĐỘNG',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SpaceTheme.textMuted,
                                fontSize: 7,
                                letterSpacing: .4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: item.feature.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  item.feature.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SpaceTheme.textSecondary,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.percentOf(total).round()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReadinessRingPainter extends CustomPainter {
  const _ReadinessRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = rect.deflate(8);
    canvas.drawArc(
      circle,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );
    final paint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [Color(0xFFAC87FF), Color(0xFF65C7FF), Color(0xFFFF8DBA)],
      ).createShader(circle)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(circle, -math.pi / 2, math.pi * 2 * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ReadinessRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _NotebookCard extends StatelessWidget {
  const _NotebookCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: const Color(0xB91A2044),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: SpaceTheme.glassBorder),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF040719).withValues(alpha: .16),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: SpaceTheme.violet.withValues(alpha: .2),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: const Color(0xFFD2C7FF), size: 19),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: SpaceTheme.textMuted, fontSize: 9),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ReadinessPill extends StatelessWidget {
  const _ReadinessPill({required this.metric});

  final ReadinessMetric metric;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: metric.available
          ? const Color(0x1F8D77FF)
          : Colors.white.withValues(alpha: .035),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          metric.feature == NotebookFeature.cvCheck
              ? Icons.description_outlined
              : Icons.circle,
          color: metric.available ? metric.feature.color : SpaceTheme.textMuted,
          size: 10,
        ),
        const SizedBox(width: 5),
        Text(
          '${metric.feature.label} ${metric.available ? '${(metric.progress * 100).round()}%' : '—'}',
          style: TextStyle(
            color: metric.available
                ? SpaceTheme.textSecondary
                : SpaceTheme.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .025),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF9D8BFF), size: 27),
        const SizedBox(height: 9),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SpaceTheme.textMuted,
            fontSize: 10,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

String _xLabel(DateTime date, NotebookPeriod period) =>
    period == NotebookPeriod.thisWeek
    ? const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][date.weekday - 1]
    : '${date.day}/${date.month}';

String _readinessComment(int score) {
  if (score >= 80) return 'Quỹ đạo sẵn sàng cất cánh — duy trì nhịp tốt nhé.';
  if (score >= 60) return 'Bạn đang tiến gần mục tiêu, hãy tiếp tục tích lũy.';
  if (score >= 35) return 'Một vài hoạt động đều đặn sẽ giúp bạn tiến xa hơn.';
  return 'Bắt đầu từ một bước nhỏ để khởi động hành trình nghề nghiệp.';
}
