import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/utils/dashboard_trend.dart';

void main() {
  test('DashboardTrendBucket parses nested weekly drilldown rows', () {
    final trend = DashboardTrendBucket.fromList([
      {
        'date': '2026-04-01',
        'total': '36463.47',
        'drilldown': [
          {
            'date': '2026-03-30',
            'label_date': '2026-04-02',
            'total': '1300.98',
          },
          {
            'date': '2026-04-20',
            'label_date': '2026-04-26',
            'total': '35162.49',
          },
        ],
      },
    ]);

    expect(trend, hasLength(1));
    expect(trend.single.canExpand, isTrue);
    expect(trend.single.drilldown[0].labelDate, '2026-04-02');
    expect(trend.single.drilldown[1].total, 35162.49);
  });

  test('supportsTrendDrilldown only enables non-empty drilldown periods', () {
    expect(supportsTrendDrilldown('weekly'), isTrue);
    expect(supportsTrendDrilldown(null), isFalse);
    expect(supportsTrendDrilldown(''), isFalse);
  });
}
