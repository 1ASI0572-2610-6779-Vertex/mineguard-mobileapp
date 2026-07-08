import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_iot/shared/widgets/app_feedback.dart';

/// Smoke coverage for the severity-driven feedback system: the animated,
/// glassmorphic critical toast and the severity-styled confirm dialog.
void main() {
  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    return ctx;
  }

  testWidgets('critical toast shows message and an explicit dismiss control', (
    tester,
  ) async {
    final ctx = await pumpHost(tester);

    AppSnack.critical(ctx, 'Collision Detected');
    await tester.pump(); // schedule the snackbar
    await tester.pump(const Duration(milliseconds: 700)); // play entrance

    expect(find.text('Collision Detected'), findsOneWidget);
    // Critical severity persists with an explicit close affordance.
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Dismiss it to cancel the auto-hide timer and settle cleanly.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Collision Detected'), findsNothing);
  });

  testWidgets('warning toast is reviewable (no forced dismiss control)', (
    tester,
  ) async {
    final ctx = await pumpHost(tester);

    AppSnack.warning(ctx, 'Fatigue Detected');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Fatigue Detected'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    // Let the (6s) auto-dismiss fire so no timers/tickers leak past teardown.
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  });

  testWidgets('premium confirm returns true when confirmed', (tester) async {
    final ctx = await pumpHost(tester);

    final future = showPremiumConfirm(
      ctx,
      title: 'End Shift',
      message: 'Are you sure?',
      confirmLabel: 'Confirm End',
      cancelLabel: 'Cancel',
      severity: AppSeverity.critical,
    );
    await tester.pumpAndSettle();

    expect(find.text('Are you sure?'), findsOneWidget);

    await tester.tap(find.text('Confirm End'));
    await tester.pumpAndSettle();

    expect(await future, isTrue);
  });
}
