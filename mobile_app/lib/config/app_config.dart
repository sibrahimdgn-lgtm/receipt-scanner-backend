import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Centralised app configuration for the receipt scanner.
class AppConfig {
  AppConfig._();

  // ── Tenant ────────────────────────────────────────────────
  // shop_id is now taken from the JWT via AuthService, not hardcoded.

  // ── API ───────────────────────────────────────────────────
  /// Web + iOS → localhost.  Android emulator → 10.0.2.2.
  /// Uses kIsWeb + defaultTargetPlatform (no dart:io needed).
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static String get scanEndpoint => '$baseUrl/api/receipts/scan';

  static const String defaultCurrencyCode = 'TRY';

  // ── Compression ───────────────────────────────────────────
  static const int compressQuality = 40;
  static const int compressMinWidth = 1200;
  static const int compressMinHeight = 1600;
  static const int maxFileSizeBytes = 1024 * 1024; // 1 MB target
}
