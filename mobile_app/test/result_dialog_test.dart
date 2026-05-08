import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/config/app_languages.dart';
import 'package:receipt_scanner_app/l10n/app_localizations.dart';
import 'package:receipt_scanner_app/models/scan_result.dart';
import 'package:receipt_scanner_app/widgets/result_dialog.dart';

void main() {
  testWidgets('result dialog shows formatted line-item transaction date',
      (tester) async {
    const result = ScanResult(
      receiptId: 'receipt-1',
      vendorName: 'Statement Export',
      receiptDate: '2026-04-30',
      currencyCode: 'TRY',
      currencySymbol: '₺',
      currencySource: 'symbol_override',
      currencyConfidence: 1,
      totalAmount: 245.75,
      taxAmount: 0,
      lineItems: [
        LineItem(
          lineItemId: 'line-1',
          itemName: 'Transfer Fee',
          transactionDate: '2026-04-27',
          quantity: 1,
          unitPrice: 245.75,
          totalPrice: 245.75,
          categoryKey: 'other',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLanguages.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: ResultDialog(result: result),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('27-04-2026'), findsOneWidget);
  });
}
