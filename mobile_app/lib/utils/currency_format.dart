import '../config/app_config.dart';

class CurrencyFormat {
  const CurrencyFormat._();

  static String? normalizeSymbol(String? symbol) {
    final normalized = symbol?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static String normalizeCode(String? code) {
    final normalized = code?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return AppConfig.defaultCurrencyCode;
    }
    return normalized;
  }

  static String symbolForCode(String? code, {String? fallbackSymbol}) {
    final normalizedSymbol = normalizeSymbol(fallbackSymbol);
    if (normalizedSymbol != null) {
      return normalizedSymbol;
    }

    switch (normalizeCode(code)) {
      case 'TRY':
        return '₺';
      case 'USD':
        return r'$';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      default:
        return normalizeCode(code);
    }
  }

  static String formatAmount(
    num amount, {
    String? currencyCode,
    String? currencySymbol,
    int decimalDigits = 2,
  }) {
    final normalizedCode = normalizeCode(currencyCode);
    final symbol = symbolForCode(
      normalizedCode,
      fallbackSymbol: currencySymbol,
    );
    final formattedAmount = amount.toStringAsFixed(decimalDigits);

    if (symbol == normalizedCode) {
      return '$normalizedCode $formattedAmount';
    }

    return '$symbol$formattedAmount';
  }

  static String labelWithSymbol(
    String label, {
    String? currencyCode,
    String? currencySymbol,
  }) {
    return '$label (${symbolForCode(currencyCode, fallbackSymbol: currencySymbol)})';
  }

  static String codeWithSymbol({
    String? currencyCode,
    String? currencySymbol,
  }) {
    final normalizedCode = normalizeCode(currencyCode);
    final symbol = symbolForCode(
      normalizedCode,
      fallbackSymbol: currencySymbol,
    );

    if (symbol == normalizedCode) {
      return normalizedCode;
    }

    return '$normalizedCode · $symbol';
  }
}
