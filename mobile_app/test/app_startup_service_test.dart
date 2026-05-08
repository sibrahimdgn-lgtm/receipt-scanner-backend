import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/services/app_startup_service.dart';

void main() {
  test('bootstrap returns true when session load succeeds', () async {
    final result = await AppStartupService.bootstrap(
      timeout: const Duration(milliseconds: 50),
      loadSavedSession: () async {},
    );

    expect(result, isTrue);
  });

  test('bootstrap returns false when session load throws', () async {
    final result = await AppStartupService.bootstrap(
      timeout: const Duration(milliseconds: 50),
      loadSavedSession: () async {
        throw Exception('boom');
      },
    );

    expect(result, isFalse);
  });

  test('bootstrap times out instead of hanging forever', () async {
    final completer = Completer<void>();
    final stopwatch = Stopwatch()..start();

    final result = await AppStartupService.bootstrap(
      timeout: const Duration(milliseconds: 50),
      loadSavedSession: () => completer.future,
    );

    expect(result, isFalse);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
  });
}
