import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/utils/dashboard_trend.dart';
import 'package:receipt_scanner_app/widgets/dashboard_trend_chart.dart';

void main() {
  testWidgets('tapping a monthly aggregate bar reveals weekly drilldown rods',
      (tester) async {
    final trend = [
      DashboardTrendBucket(
        date: '2026-04-01',
        labelDate: '2026-04-01',
        total: 36463.47,
        drilldown: const [
          DashboardTrendBucket(
            date: '2026-03-30',
            labelDate: '2026-04-02',
            total: 1300.98,
          ),
          DashboardTrendBucket(
            date: '2026-04-20',
            labelDate: '2026-04-26',
            total: 35162.49,
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              height: 220,
              child: DashboardTrendChart(
                trend: trend,
                periodTrunc: 'month',
                selectedPeriod: 'monthly',
                drilldownPeriod: 'weekly',
                noDataText: 'empty',
                activeCurrencyCode: 'TRY',
                activeCurrencySymbol: '₺',
              ),
            ),
          ),
        ),
      ),
    );

    var chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups.single.barRods, hasLength(1));

    final chartRect = tester.getRect(find.byType(BarChart));
    await tester.tapAt(
      Offset(chartRect.center.dx, chartRect.top + (chartRect.height * 0.35)),
    );
    await tester.pumpAndSettle();

    chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups.single.barRods, hasLength(2));
    expect(
      chart.data.barGroups.single.barRods
          .every((rod) => rod.backDrawRodData.show),
      isTrue,
    );

    await tester.tapAt(
      Offset(chartRect.center.dx, chartRect.top + (chartRect.height * 0.35)),
    );
    await tester.pumpAndSettle();

    chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups.single.barRods, hasLength(1));
  });
}
