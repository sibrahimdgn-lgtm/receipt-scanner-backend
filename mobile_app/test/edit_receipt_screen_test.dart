import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/config/app_languages.dart';
import 'package:receipt_scanner_app/l10n/app_localizations.dart';
import 'package:receipt_scanner_app/screens/edit_receipt_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLanguages.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );
  }

  testWidgets('edit receipt screen stacks paired fields on narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        EditReceiptScreen(
          receipt: {
            'receipt_id': 'receipt-1',
            'vendor_name': 'Acme Market',
            'receipt_date': '2026-05-18',
            'currency_code': 'TRY',
            'currency_symbol': '₺',
            'total_amount': 120.5,
            'tax_amount': 10.0,
            'line_items': [
              {
                'item_name': 'Coffee',
                'transaction_date': '2026-05-18',
                'quantity': 1,
                'unit_price': 120.5,
                'total_price': 120.5,
                'category': 'Diğer',
              },
            ],
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    final dateField = tester.getTopLeft(fields.at(1));
    final currencyField = tester.getTopLeft(fields.at(2));
    final quantityField = tester.getTopLeft(fields.at(4));
    final priceField = tester.getTopLeft(fields.at(5));

    expect(currencyField.dy, greaterThan(dateField.dy));
    expect(priceField.dy, greaterThan(quantityField.dy));
    expect(tester.takeException(), isNull);
  });
}
