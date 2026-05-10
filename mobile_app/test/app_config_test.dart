import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/config/app_config.dart';

void main() {
  test('AppConfig points API calls to the live Render backend', () {
    expect(
      AppConfig.baseUrl,
      'https://receipt-scanner-backend-7hos.onrender.com',
    );
    expect(
      AppConfig.scanEndpoint,
      'https://receipt-scanner-backend-7hos.onrender.com/api/receipts/scan',
    );
  });
}
