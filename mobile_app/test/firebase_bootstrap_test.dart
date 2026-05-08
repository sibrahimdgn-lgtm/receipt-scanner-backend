import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/services/firebase_bootstrap.dart';

void main() {
  test('firebase bootstrap reports generated configuration availability', () {
    expect(FirebaseBootstrap.isConfigured, isTrue);
  });
}
