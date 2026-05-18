import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/widgets/scan_feedback_widgets.dart';

void main() {
  testWidgets('receipt analysis loading card shows polished copy and skeleton',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ReceiptAnalysisLoadingCard(
              title: 'Receipt details are being analyzed by AI...',
              subtitle:
                  'This usually takes a few seconds. Please keep this screen open.',
              pulseValue: 0.6,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Receipt details are being analyzed by AI...'),
        findsOneWidget);
    expect(
      find.text(
          'This usually takes a few seconds. Please keep this screen open.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('scan-loading-header')), findsOneWidget);
  });

  testWidgets('scan status banner renders success and retry affordance',
      (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanStatusBanner(
            message: 'Scanning failed. Please try again.',
            icon: Icons.error_outline_rounded,
            accentColor: Colors.red,
            actionLabel: 'Retry',
            onAction: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Scanning failed. Please try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });
}
