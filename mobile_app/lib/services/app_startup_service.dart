import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_service.dart';

class AppStartupService {
  AppStartupService._();

  static const Duration defaultTimeout = Duration(seconds: 8);

  static Future<bool> bootstrap({
    Duration timeout = defaultTimeout,
    Future<void> Function()? loadSavedSession,
  }) async {
    final loader = loadSavedSession ?? AuthService.instance.loadSavedSession;

    try {
      await loader().timeout(timeout);
      return true;
    } catch (error, stackTrace) {
      debugPrint('[AppStartupService] Bootstrap failed: $error');
      debugPrintStack(
        label: '[AppStartupService] stack trace',
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
