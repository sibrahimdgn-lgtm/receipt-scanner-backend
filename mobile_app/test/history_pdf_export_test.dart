import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:receipt_scanner_app/utils/history_pdf_export.dart';

void main() {
  test('buildHistoryPdfBytes creates a valid PDF document', () async {
    final bytes = await buildHistoryPdfBytes(
      [
        {
          'receipt_date': '2026-05-18',
          'vendor_name': 'ACME Market',
          'total_amount': 149.95,
          'currency_code': 'TRY',
          'currency_symbol': '₺',
          'line_items': [
            {'category_key': 'food'},
          ],
        },
      ],
      labels: const HistoryPdfLabels(
        title: 'Receipt History Report',
        generatedOn: 'Generated on',
        date: 'Date',
        vendorName: 'Vendor Name',
        category: 'Category',
        totalAmount: 'Total',
        currency: 'Currency',
        totalSpend: 'TOTAL SPEND',
        mixedCurrencies: 'Mixed currencies',
      ),
      categoryLabelFor: (value) => switch (value) {
        'food' => 'Food',
        _ => 'Other',
      },
      locale: const Locale('en'),
      fontLoaders: const HistoryPdfFontLoaders(
        regular: _regularFont,
        bold: _boldFont,
      ),
    );

    expect(bytes.length, greaterThan(1000));
    expect(utf8.decode(bytes.take(5).toList()), equals('%PDF-'));
  });
}

Future<pw.Font> _regularFont() async => pw.Font.helvetica();

Future<pw.Font> _boldFont() async => pw.Font.helveticaBold();
