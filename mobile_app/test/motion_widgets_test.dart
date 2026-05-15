import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_scanner_app/main.dart';
import 'package:receipt_scanner_app/widgets/animated_backdrop.dart';
import 'package:receipt_scanner_app/widgets/hover_lift_card.dart';
import 'package:receipt_scanner_app/widgets/motion_reveal.dart';

void main() {
  testWidgets('animated motion widgets render their child content',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedBackdrop(
            child: Column(
              children: [
                MotionReveal(
                  child: Text('Reveal Content'),
                ),
                HoverLiftCard(
                  child: SizedBox(
                    width: 120,
                    height: 60,
                    child: Center(child: Text('Lift Content')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Reveal Content'), findsOneWidget);
    expect(find.text('Lift Content'), findsOneWidget);
  });

  testWidgets('hover lift card reacts only when press is enabled',
      (tester) async {
    const staticKey = ValueKey('static-card');
    const pressKey = ValueKey('press-card');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              HoverLiftCard(
                key: staticKey,
                child: SizedBox(width: 120, height: 60),
              ),
              SizedBox(height: 24),
              HoverLiftCard(
                key: pressKey,
                enablePress: true,
                child: SizedBox(width: 120, height: 60),
              ),
            ],
          ),
        ),
      ),
    );

    Matrix4 transformFor(ValueKey<String> key) {
      return tester
          .widget<Transform>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(Transform),
            ),
          )
          .transform;
    }

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byKey(staticKey)));
    await tester.pump(const Duration(milliseconds: 260));

    expect(transformFor(staticKey).storage[13], 0);

    await mouse.moveTo(tester.getCenter(find.byKey(pressKey)));
    await tester.pump(const Duration(milliseconds: 260));

    expect(transformFor(pressKey).storage[13], 0);

    await mouse.down(tester.getCenter(find.byKey(pressKey)));
    await tester.pump(const Duration(milliseconds: 60));

    expect(transformFor(pressKey).storage[13], lessThan(0));

    await mouse.up();
  });

  testWidgets('action controls keep hover overlay enabled', (tester) async {
    await tester.pumpWidget(const ReceiptScannerApp());
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(Scaffold).first);
    final theme = Theme.of(context);

    final filledHover = theme.filledButtonTheme.style?.overlayColor?.resolve({
      WidgetState.hovered,
    });
    final navHover = theme.navigationBarTheme.overlayColor?.resolve({
      WidgetState.hovered,
    });

    expect(filledHover, isNotNull);
    expect(filledHover!.alpha, greaterThan(0));
    expect(navHover, isNotNull);
    expect(navHover!.alpha, greaterThan(0));
  });
}
