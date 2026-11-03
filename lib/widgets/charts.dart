// lib/widgets/charts.dart
//
// fl_chart based graphs used on the Insights screen.
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/category.dart';
import '../providers/settings_provider.dart';

double _niceMax(double value) {
  if (value <= 0) return 10;
  final exponent = math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
  final fraction = value / exponent;
  final double nice = fraction <= 1
      ? 1.0
      : fraction <= 2
          ? 2.0
          : fraction <= 5
              ? 5.0
              : 10.0;
  return nice * exponent;
}

TextStyle _axisStyle(BuildContext context) =>
    TextStyle(fontSize: 10, color: Theme.of(context).hintColor);

/// Donut chart of spending per category, with a tappable legend.
class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({super.key, required this.data, this.size = 220});

  /// categoryId -> amount
  final Map<String, double> data;
  final double size;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final fmt = context.fmt;
    final ar = context.watch<SettingsProvider>().isArabic;
    final total = widget.data.values.fold(0.0, (a, b) => a + b);
    final entries = widget.data.entries.toList();
    final radius = widget.size * 0.24;

    final chart = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: widget.size * 0.22,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response?.touchedSection == null) {
                      _touched = -1;
                    } else {
                      _touched =
                          response!.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    color: ExpenseCategory.byId(entries[i].key).color,
                    value: entries[i].value,
                    radius: i == _touched ? radius + 8 : radius,
                    title: total == 0
                        ? ''
                        : '${(entries[i].value / total * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Center label: total or the touched category
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _touched >= 0 && _touched < entries.length
                    ? ExpenseCategory.byId(entries[_touched].key).emoji
                    : '💖',
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                fmt.moneyShort(_touched >= 0 && _touched < entries.length
                    ? entries[_touched].value
                    : total),
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );

    final legend = Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        for (var i = 0; i < entries.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: ExpenseCategory.byId(entries[i].key).color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                ExpenseCategory.byId(entries[i].key).label(ar),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: i == _touched ? FontWeight.w800 : FontWeight.w400,
                ),
              ),
            ],
          ),
      ],
    );

    // Legend next to the chart when there is room, below it otherwise.
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth > widget.size + 180) {
        return Row(
          children: [
            Directionality(textDirection: TextDirection.ltr, child: chart),
            const SizedBox(width: 20),
            Expanded(child: legend),
          ],
        );
      }
      return Column(
        children: [
          Directionality(textDirection: TextDirection.ltr, child: chart),
          const SizedBox(height: 14),
          legend,
        ],
      );
    });
  }
}

/// Simple bar chart: one bar per value (days of a month, weekdays, ...).
class SpendingBarChart extends StatelessWidget {
  const SpendingBarChart({
    super.key,
    required this.values,
    required this.labelFor,
    this.labelEvery = 1,
    this.height = 200,
    this.highlightIndex,
  });

  final List<double> values;
  final String Function(int index) labelFor;
  final int labelEvery;
  final double height;
  final int? highlightIndex;

  @override
  Widget build(BuildContext context) {
    final fmt = context.fmt;
    final maxY = _niceMax(values.fold(0.0, math.max));
    return LayoutBuilder(builder: (context, c) {
      final barWidth =
          ((c.maxWidth - 50) / math.max(values.length, 1) * 0.6).clamp(3.0, 22.0);
      return SizedBox(
        height: height,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.darkSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                    '${labelFor(group.x)}\n${fmt.money(rod.toY)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(fmt.compact(value),
                          style: _axisStyle(context),
                          textAlign: TextAlign.right),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i % labelEvery != 0 && i != values.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(labelFor(i), style: _axisStyle(context)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < values.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        width: barWidth,
                        color: i == highlightIndex
                            ? AppColors.lilac
                            : AppColors.hotPink,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Line chart of the monthly totals (trend over the last months).
class MonthlyTrendChart extends StatelessWidget {
  const MonthlyTrendChart({
    super.key,
    required this.points,
    this.budget,
    this.height = 200,
  });

  final List<MapEntry<DateTime, double>> points;
  final double? budget;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fmt = context.fmt;
    final top = math.max(points.fold(0.0, (m, p) => math.max(m, p.value)),
        budget ?? 0);
    final maxY = _niceMax(top * 1.1);

    return SizedBox(
      height: height,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            minX: 0,
            maxX: (points.length - 1).toDouble(),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
            ),
            extraLinesData: budget == null || budget! <= 0
                ? const ExtraLinesData()
                : ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: budget!,
                      color: AppColors.lilac.withValues(alpha: 0.7),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                    ),
                  ]),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.darkSurface,
                getTooltipItems: (spots) => spots
                    .map((spot) => LineTooltipItem(
                          '${fmt.monthShort(points[spot.x.toInt()].key)}\n${fmt.money(spot.y)}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        ))
                    .toList(),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  interval: maxY / 4,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(fmt.compact(value),
                        style: _axisStyle(context), textAlign: TextAlign.right),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= points.length || value != i.toDouble()) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(fmt.monthShort(points[i].key),
                          style: _axisStyle(context)),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(i.toDouble(), points[i].value),
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                color: AppColors.hotPink,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.hotPink.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
