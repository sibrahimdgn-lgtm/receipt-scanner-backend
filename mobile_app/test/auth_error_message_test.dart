import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/config/app_languages.dart';
import 'package:receipt_scanner_app/l10n/app_localizations.dart';
import 'package:receipt_scanner_app/services/auth_service.dart';
import 'package:receipt_scanner_app/utils/auth_error_message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('maps localized auth flow exceptions to translated copy',
      (tester) async {
    String? trMessage;
    String? enMessage;

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
        home: Builder(
          builder: (context) {
            trMessage = authErrorMessage(
              context,
              const AuthFlowException('invalid_credentials'),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLanguages.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            enMessage = authErrorMessage(
              context,
              const AuthFlowException('firebase_not_configured'),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(trMessage, 'E-posta veya şifre hatalı.');
    expect(
      enMessage,
      'Firebase is not configured for this build yet.',
    );
  });
}
