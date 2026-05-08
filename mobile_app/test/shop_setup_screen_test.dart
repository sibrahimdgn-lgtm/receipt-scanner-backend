import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/l10n/app_localizations.dart';
import 'package:receipt_scanner_app/screens/shop_setup_screen.dart';

void main() {
  testWidgets('shop setup screen shows create new shop action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ShopSetupScreen(
          initialEmail: 'dogansibrahim@gmail.com',
        ),
      ),
    );

    expect(find.text('Complete your shop setup'), findsOneWidget);
    expect(find.text('Create Shop Profile'), findsOneWidget);
    expect(find.textContaining('dogansibrahim@gmail.com'), findsOneWidget);
  });
}
