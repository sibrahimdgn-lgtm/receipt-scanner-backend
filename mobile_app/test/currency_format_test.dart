import 'package:receipt_scanner_app/config/receipt_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/models/scan_result.dart';
import 'package:receipt_scanner_app/utils/currency_format.dart';

void main() {
  group('CurrencyFormat', () {
    test('formats Turkish lira with the correct symbol', () {
      expect(
        CurrencyFormat.formatAmount(1300.98, currencyCode: 'TRY'),
        '₺1300.98',
      );
    });

    test('falls back to TRY when currency code is missing', () {
      expect(
        CurrencyFormat.formatAmount(42),
        '₺42.00',
      );
    });

    test('prefers the stored currency symbol override when provided', () {
      expect(
        CurrencyFormat.formatAmount(
          19.5,
          currencyCode: 'CAD',
          currencySymbol: 'CA\$',
        ),
        'CA\$19.50',
      );
    });
  });

  test('ReceiptCategories normalizes legacy category labels', () {
    expect(ReceiptCategories.normalize('Electronics'), 'electronics');
    expect(ReceiptCategories.normalize('Apparel'), 'other');
  });

  test('ScanResult reads receipt-level currency metadata from the API payload',
      () {
    final result = ScanResult.fromJson({
      'currency': 'TRY',
      'receipt': {
        'receipt_id': 'receipt-1',
        'vendor_name': 'LC Waikiki',
        'receipt_date': '2026-04-12',
        'currency': 'TRY',
        'currency_code': 'TRY',
        'currency_symbol': '₺',
        'currency_source': 'symbol_override',
        'currency_confidence': 0.93,
        'total_amount': 1300.98,
        'tax_amount': 0,
        'line_items': const [],
      },
    });

    expect(result.currencyCode, 'TRY');
    expect(result.currencySymbol, '₺');
    expect(result.currencySource, 'symbol_override');
    expect(result.currencyConfidence, 0.93);
    expect(result.totalAmount, 1300.98);
  });

  test('LineItem keeps optional transaction dates from the API payload', () {
    final result = ScanResult.fromJson({
      'receipt': {
        'receipt_id': 'receipt-2',
        'vendor_name': 'Bank Statement',
        'receipt_date': '2026-04-30',
        'currency_code': 'TRY',
        'currency_symbol': '₺',
        'currency_source': 'symbol_override',
        'currency_confidence': 1,
        'total_amount': 450,
        'tax_amount': 0,
        'line_items': [
          {
            'line_item_id': 'line-1',
            'item_name': 'Transfer',
            'transaction_date': '2026-04-27',
            'quantity': 1,
            'unit_price': 450,
            'total_price': 450,
            'category_key': 'other',
          },
        ],
      },
    });

    expect(result.lineItems.single.transactionDate, '2026-04-27');
    expect(
      result.lineItems.single.toJson()['transaction_date'],
      '2026-04-27',
    );
  });
}
