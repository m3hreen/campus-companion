import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code/main.dart';
import 'package:code/utils/app_feedback.dart';

void main() {
  testWidgets('Begin opens the dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusCompanionApp());

    final beginButton = find.text('Begin');
    expect(beginButton, findsOneWidget);

    // Scroll to Begin in case it's below the visible part of the screen.
    await tester.ensureVisible(beginButton);
    await tester.pumpAndSettle();

    await tester.tap(beginButton);
    await tester.pumpAndSettle();

    // The dashboard greeting should appear and the Begin button should be gone.
    expect(find.text('Welcome back!'), findsOneWidget);
    expect(beginButton, findsNothing);
  });

  testWidgets(
    'Timer feedback preserves the current Undo action',
        (WidgetTester tester) async {
      bool restored = false;
      late BuildContext feedbackContext;

      // Set up a simple screen where the feedback messages can appear.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                feedbackContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      showAppFeedback(
        feedbackContext,
        'Assignment deleted',
        onUndo: () {
          restored = true;
        },
      );
      await tester.pumpAndSettle();

      // The timer message should wait while Undo is still on screen.
      showAppFeedback(feedbackContext, 'Timer complete!');
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Timer complete!'), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Check that Undo ran and the waiting message is now visible.
      expect(restored, isTrue);
      expect(find.text('Timer complete!'), findsOneWidget);

      // Remove the test screen so the remaining message is cleared.
      await tester.pumpWidget(const SizedBox());
    },
  );
}