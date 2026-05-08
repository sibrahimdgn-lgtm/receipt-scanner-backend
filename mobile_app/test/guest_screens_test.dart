import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/config/app_languages.dart';
import 'package:receipt_scanner_app/l10n/app_localizations.dart';
import 'package:receipt_scanner_app/screens/dashboard_screen.dart';
import 'package:receipt_scanner_app/screens/history_screen.dart';
import 'package:receipt_scanner_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AuthService.instance.logout();
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      locale: const Locale('tr'),
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

  testWidgets('dashboard shows sign-in prompt when logged out', (tester) async {
    await tester.pumpWidget(buildTestApp(const DashboardScreen()));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Paneli görmek için giriş yap'), findsOneWidget);
  });

  testWidgets('history shows sign-in prompt when logged out', (tester) async {
    await tester.pumpWidget(buildTestApp(const HistoryScreen()));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Fişlerini görmek için giriş yap'), findsOneWidget);
  });
}
