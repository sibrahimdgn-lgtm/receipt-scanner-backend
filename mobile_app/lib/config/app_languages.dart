import 'package:flutter/widgets.dart';

class AppLanguages {
  AppLanguages._();

  static const String defaultCode = 'tr';
  static const List<String> supportedCodes = ['tr', 'en', 'de', 'ar'];
  static const List<Locale> supportedLocales = [
    Locale('tr'),
    Locale('en'),
    Locale('de'),
    Locale('ar'),
  ];

  static const Map<String, String> nativeNames = {
    'tr': 'Türkçe',
    'en': 'English',
    'de': 'Deutsch',
    'ar': 'العربية',
  };

  static const Map<String, String> flagEmojis = {
    'tr': '🇹🇷',
    'en': '🇬🇧',
    'de': '🇩🇪',
    'ar': '🇸🇦',
  };

  static String normalize(String? value, {String fallback = defaultCode}) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    final token = value
        .trim()
        .split(',')
        .first
        .split(';')
        .first
        .split(RegExp(r'[-_]'))
        .first
        .toLowerCase();

    return supportedCodes.contains(token) ? token : fallback;
  }

  static Locale localeOf(String? value) {
    final code = normalize(value);
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == code,
      orElse: () => const Locale(defaultCode),
    );
  }

  static String nativeNameOf(String? value) {
    final code = normalize(value);
    return nativeNames[code] ?? nativeNames[defaultCode]!;
  }

  static String flagOf(String? value) {
    final code = normalize(value);
    return flagEmojis[code] ?? flagEmojis[defaultCode]!;
  }
}
