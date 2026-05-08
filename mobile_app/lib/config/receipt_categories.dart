import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';

class ReceiptCategories {
  ReceiptCategories._();

  static const List<String> values = [
    'food',
    'stationery',
    'transport',
    'electronics',
    'health',
    'entertainment',
    'other',
  ];

  static const String defaultCategory = 'other';

  static final Map<String, String> _aliases = {
    'gida': 'food',
    'food': 'food',
    'grocery': 'food',
    'lebensmittel': 'food',
    'طعام': 'food',
    'kirtasiye': 'stationery',
    'stationery': 'stationery',
    'schreibwaren': 'stationery',
    'قرطاسية': 'stationery',
    'ulasim yol': 'transport',
    'ulasim': 'transport',
    'transport': 'transport',
    'travel': 'transport',
    'transport travel': 'transport',
    'transport reise': 'transport',
    'reise': 'transport',
    'مواصلات': 'transport',
    'سفر': 'transport',
    'مواصلات سفر': 'transport',
    'مواصلات/سفر': 'transport',
    'elektronik': 'electronics',
    'electronics': 'electronics',
    'electronic': 'electronics',
    'إلكترونيات': 'electronics',
    'health': 'health',
    'saglik': 'health',
    'gesundheit': 'health',
    'صحة': 'health',
    'eglence': 'entertainment',
    'entertainment': 'entertainment',
    'unterhaltung': 'entertainment',
    'ترفيه': 'entertainment',
    'other': 'other',
    'diger': 'other',
    'sonstiges': 'other',
    'أخرى': 'other',
    'shopping': 'other',
    'apparel': 'other',
  };

  static String normalize(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return defaultCategory;
    }

    if (values.contains(raw)) {
      return raw;
    }

    final normalized = raw
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^\p{L}\p{N}/ ]+', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return _aliases[normalized] ?? defaultCategory;
  }

  static String labelFor(BuildContext context, String? value) {
    final l10n = context.l10n;
    switch (normalize(value)) {
      case 'food':
        return l10n.categoryFood;
      case 'stationery':
        return l10n.categoryStationery;
      case 'transport':
        return l10n.categoryTransport;
      case 'electronics':
        return l10n.categoryElectronics;
      case 'health':
        return l10n.categoryHealth;
      case 'entertainment':
        return l10n.categoryEntertainment;
      default:
        return l10n.categoryOther;
    }
  }
}
