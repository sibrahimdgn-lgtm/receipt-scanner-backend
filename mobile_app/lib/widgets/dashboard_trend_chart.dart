import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/currency_format.dart';
import '../utils/dashboard_trend.dart';
import 'hover_lift_card.dart';

class DashboardTrendChart extends StatefulWidget {
  const DashboardTrendChart({
    required this.trend,
    required this.periodTrunc,
    required this.selectedPeriod,
    required this.noDataText,
    required this.activeCurrencyCode,
    this.drilldownPeriod,
    this.activeCurrencySymbol,
    super.key,
  });

  final List<DashboardTrendBucket> trend;
  final String periodTrunc;
  final String selectedPeriod;
  final String? drilldownPeriod;
  final String noDataText;
  final String activeCurrencyCode;
  final String? activeCurrencySymbol;

  @override
  State<DashboardTrendChart> createState() => _DashboardTrendChartState();
}

class _DashboardTrendChartState extends State<DashboardTrendChart> {
  String? _expandedBucketDate;

  @override
  void didUpdateWidget(covariant DashboardTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    final expandedBucketStillExists = widget.trend.any(
      (bucket) => bucket.date == _expandedBucketDate && bucket.canExpand,
    );

    if (oldWidget.selectedPeriod != widget.selectedPeriod ||
        oldWidget.drilldownPeriod != widget.drilldownPeriod ||
        !expandedBucketStillExists) {
      _expandedBucketDate = null;
    }
  }

  bool get _supportsDrilldown => supportsTrendDrilldown(widget.drilldownPeriod);

  bool _isExpanded(DashboardTrendBucket bucket) {
    return bucket.date == _expandedBucketDate && _supportsDrilldown;
  }

  void _toggleBucket(int groupIndex) {
    if (groupIndex < 0 || groupIndex >= widget.trend.length) {
      return;
    }

    final bucket = widget.trend[groupIndex];
    if (!_supportsDrilldown || !bucket.canExpand) {
      return;
    }

    setState(() {
      _expandedBucketDate =
          _expandedBucketDate == bucket.date ? null : bucket.date;
    });
  }

  double _topLevelMaxValue() {
    final maxValue = widget.trend.fold<double>(
      0,
      (currentMax, bucket) =>
          bucket.total > currentMax ? bucket.total : currentMax,
    );
    return maxValue <= 0 ? 1 : maxValue * 1.18;
  }

  double _primaryRodWidth() {
    if (widget.selectedPeriod == 'monthly' ||
        widget.selectedPeriod == 'yearly') {
      return 24;
    }
    return 14;
  }

  double _drilldownRodWidth(int rodCount) {
    if (rodCount <= 1) {
      return _primaryRodWidth();
    }
    final computed = 38 / rodCount;
    return computed.clamp(6, 10).toDouble();
  }

  String _formatAxisLabel(String date, Locale locale) {
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) {
      return '';
    }

    final localeName = locale.toLanguageTag();
    if (widget.periodTrunc == 'day' || widget.periodTrunc == 'week') {
      return DateFormat('dd/MM', localeName).format(parsedDate);
    }
    if (widget.periodTrunc == 'month') {
      return widget.selectedPeriod == 'yearly'
          ? DateFormat.MMM(localeName).format(parsedDate)
          : DateFormat('MMM yy', localeName).format(parsedDate);
    }
    return DateFormat.y(localeName).format(parsedDate);
  }

  String _formatTooltipDate(
    DashboardTrendBucket bucket,
    Locale locale, {
    required bool isDrilldown,
  }) {
    final parsedDate = DateTime.tryParse(
        bucket.labelDate.isNotEmpty ? bucket.labelDate : bucket.date);
    if (parsedDate == null) {
      return bucket.labelDate.isNotEmpty ? bucket.labelDate : bucket.date;
    }

    final localeName = locale.toLanguageTag();
    if (isDrilldown) {
      return DateFormat('dd MMM', localeName).format(parsedDate);
    }

    if (widget.periodTrunc == 'day' || widget.periodTrunc == 'week') {
      return DateFormat('dd MMM', localeName).format(parsedDate);
    }
    if (widget.periodTrunc == 'month') {
      return DateFormat('MMMM yyyy', localeName).format(parsedDate);
    }
    return DateFormat.yMMMM(localeName).format(parsedDate);
  }

  Color _rodColor(ThemeData theme, int rodIndex, int rodCount) {
    if (rodCount <= 1) {
      return theme.colorScheme.primary;
    }

    final blend = rodCount == 1 ? 1.0 : rodIndex / (rodCount - 1);
    return Color.lerp(
          theme.colorScheme.secondary.withValues(alpha: 0.9),
          theme.colorScheme.primary,
          blend,
        ) ??
        theme.colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trend.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          widget.noDataText,
          style: const TextStyle(color: Colors.white30),
        ),
      );
    }

    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final visibleGroups = <List<DashboardTrendBucket>>[];
    final bars = widget.trend.asMap().entries.map((entry) {
      final bucket = entry.value;
      final expanded = _isExpanded(bucket);
      final visibleBuckets = expanded ? bucket.drilldown : [bucket];
      visibleGroups.add(visibleBuckets);
      final rodWidth = expanded
          ? _drilldownRodWidth(visibleBuckets.length)
          : _primaryRodWidth();

      return BarChartGroupData(
        x: entry.key,
        barsSpace: expanded ? 4 : 0,
        barRods: visibleBuckets.asMap().entries.map((rodEntry) {
          final rodBucket = rodEntry.value;
          return BarChartRodData(
            toY: rodBucket.total,
            width: rodWidth,
            color: _rodColor(theme, rodEntry.key, visibleBuckets.length),
            borderRadius: BorderRadius.circular(expanded ? 4 : 6),
            backDrawRodData: expanded
                ? BackgroundBarChartRodData(
                    show: true,
                    toY: bucket.total,
                    color: Colors.white.withValues(alpha: 0.08),
                  )
                : BackgroundBarChartRodData(),
          );
        }).toList(),
      );
    }).toList();

    final dates = widget.trend
        .map((bucket) => _formatAxisLabel(bucket.date, locale))
        .toList();

    return HoverLiftCard(
      glowColor: theme.colorScheme.secondary,
      child: Container(
        height: 190,
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: BarChart(
          BarChartData(
            maxY: _topLevelMaxValue(),
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            barGroups: bars,
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.white12, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        index < dates.length ? dates[index] : '',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              mouseCursorResolver: (event, response) {
                if (response?.spot == null) {
                  return SystemMouseCursors.basic;
                }

                final index = response!.spot!.touchedBarGroupIndex;
                if (index < 0 || index >= widget.trend.length) {
                  return SystemMouseCursors.basic;
                }

                return widget.trend[index].canExpand
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic;
              },
              touchCallback: (event, response) {
                final spot = response?.spot;
                if (spot == null || event is! FlTapUpEvent) {
                  return;
                }
                _toggleBucket(spot.touchedBarGroupIndex);
              },
              touchTooltipData: BarTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipColor: (_) => const Color(0xFF1E1E2C),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (groupIndex < 0 || groupIndex >= visibleGroups.length) {
                    return null;
                  }

                  final groupBuckets = visibleGroups[groupIndex];
                  if (rodIndex < 0 || rodIndex >= groupBuckets.length) {
                    return null;
                  }

                  final bucket = groupBuckets[rodIndex];
                  final isDrilldown = _isExpanded(widget.trend[groupIndex]);

                  return BarTooltipItem(
                    '${_formatTooltipDate(bucket, locale, isDrilldown: isDrilldown)}\n'
                    '${CurrencyFormat.formatAmount(
                      rod.toY,
                      currencyCode: widget.activeCurrencyCode,
                      currencySymbol: widget.activeCurrencySymbol,
                    )}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  );
                },
              ),
            ),
          ),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}
