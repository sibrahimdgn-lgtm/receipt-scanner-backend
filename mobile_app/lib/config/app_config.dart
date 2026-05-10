/// Centralised app configuration for the receipt scanner.
class AppConfig {
  AppConfig._();

  // ── Tenant ────────────────────────────────────────────────
  // shop_id is now taken from the JWT via AuthService, not hardcoded.

  // ── API ───────────────────────────────────────────────────
  /// All client API traffic targets the live Render backend.
  static const String baseUrl =
      'https://receipt-scanner-backend-7hos.onrender.com';

  static String get scanEndpoint => '$baseUrl/api/receipts/scan';

  static const String defaultCurrencyCode = 'TRY';

  // ── Compression ───────────────────────────────────────────
  static const int compressQuality = 40;
  static const int compressMinWidth = 1200;
  static const int compressMinHeight = 1600;
  static const int maxFileSizeBytes = 1024 * 1024; // 1 MB target
}
