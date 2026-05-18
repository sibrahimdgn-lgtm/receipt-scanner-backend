import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/utils/history_csv_export.dart';

void main() {
  test('buildHistoryCsv exports localized columns and escaped values', () {
    final csv = buildHistoryCsv(
      [
        {
          'receipt_date': '2026-05-18',
          'vendor_name': 'ACME, Inc.',
          'total_amount': 149.95,
          'currency_code': 'TRY',
          'currency_symbol': '₺',
          'item_count': 2,
          'receipt_id': 'r-123',
          'line_items': [
            {'category_key': 'food'},
            {'category': 'transport'},
            {'category': 'food'},
          ],
        },
      ],
      headers: const HistoryCsvHeaders(
        date: 'Date',
        vendorName: 'Vendor Name',
        categories: 'Categories',
        totalAmount: 'Total Amount',
        currencyCode: 'Currency Code',
        currencySymbol: 'Currency Symbol',
        itemCount: 'Items',
        receiptId: 'receipt_id',
      ),
      categoryLabelFor: (value) => switch (value) {
        'food' => 'Food',
        'transport' => 'Transport/Travel',
        _ => 'Other',
      },
    );

    final rows = csv.split('\r\n');
    expect(
      rows.first,
      'Date,Vendor Name,Categories,Total Amount,Currency Code,Currency Symbol,Items,receipt_id',
    );
    expect(
      rows.last,
      '2026-05-18,"ACME, Inc.",Food | Transport/Travel,149.95,TRY,₺,2,r-123',
    );
  });
}
