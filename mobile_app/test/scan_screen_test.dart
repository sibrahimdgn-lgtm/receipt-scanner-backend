import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/config/app_languages.dart';
import 'package:receipt_scanner_app/l10n/app_localizations.dart';
import 'package:receipt_scanner_app/screens/scan_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScanScreen(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLanguages.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const ScanScreen(),
      ),
    );
  }

  testWidgets('scan screen shows JPG PNG PDF upload guidance in English',
      (tester) async {
    await pumpScanScreen(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Upload JPG, PNG, or PDF'), findsOneWidget);
    expect(find.text('Take a photo or upload a receipt file'), findsOneWidget);
  });

  testWidgets('scan screen keeps Arabic strings and RTL direction',
      (tester) async {
    await pumpScanScreen(tester, locale: const Locale('ar'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ارفع JPG أو PNG أو PDF'), findsOneWidget);

    final directionality =
        tester.widget<Directionality>(find.byType(Directionality).first);
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('scan screen shows Turkish characters in localized copy',
      (tester) async {
    await pumpScanScreen(tester, locale: const Locale('tr'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Fotoğraf Çek'), findsOneWidget);
    expect(find.text('JPG, PNG veya PDF Yükle'), findsOneWidget);
    expect(
      find.text(
          'Fotoğraf çek veya JPG, PNG ya da PDF yükle; detayları AI çıkarsın'),
      findsOneWidget,
    );
  });
}
