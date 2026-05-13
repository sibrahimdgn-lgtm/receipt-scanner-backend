import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/services/dashboard_service.dart';

void main() {
  test('buildSummaryUri forwards the local timezone offset and currency', () {
    final uri = DashboardService.instance.buildSummaryUri(
      period: 'daily',
      currencyCode: 'try',
      timezoneOffsetOverride: const Duration(hours: 3),
    );

    expect(uri.queryParameters['period'], 'daily');
    expect(uri.queryParameters['currency'], 'TRY');
    expect(uri.queryParameters['timezoneOffset'], '180');
  });
}
