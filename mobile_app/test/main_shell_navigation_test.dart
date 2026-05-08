import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receipt_scanner_app/config/app_languages.dart';
import 'package:receipt_scanner_app/l10n/app_localizations.dart';
import 'package:receipt_scanner_app/main.dart';
import 'package:receipt_scanner_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test-token',
      'auth_shop_id': 'test-shop-id',
      'auth_email': 'tester@example.com',
      'auth_shop_name': 'Motion Test Shop',
      'auth_shop_currency': 'TRY',
      'auth_preferred_language': 'tr',
    });
    await AuthService.instance.loadSavedSession();
  });

  tearDown(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.instance.logout();
  });

  Widget buildTestApp() {
    return MaterialApp(
      locale: const Locale('tr'),
      supportedLocales: AppLanguages.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainShell(),
    );
  }

  testWidgets('switching tabs hides previous screen content cleanly',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Fiş Tara'), findsOneWidget);
    expect(find.text('Fişler'), findsNothing);

    await tester.tap(find.text('Geçmiş'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Fişler'), findsOneWidget);
    expect(find.text('Fiş Tara'), findsNothing);
    expect(find.textContaining('Fotoğraf çek veya'), findsNothing);
  });
}
