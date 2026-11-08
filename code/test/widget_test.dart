import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code/main.dart';
import 'package:code/utils/app_feedback.dart';

void main() {
  testWidgets('Begin opens the dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusCompanionApp());
    expect(find.text('Begin'), findsOneWidget);
    await tester.ensureVisible(find.text('Begin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Begin'), findsNothing);
  });

  testWidgets('Timer feedback preserves the current Undo action', (WidgetTester tester) async {
    bool restored = false;
    late BuildContext feedbackContext;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) {
      feedbackContext = context;
      return const SizedBox();
    }))));
    showAppFeedback(feedbackContext, 'Assignment deleted', onUndo: () { restored = true; });
    await tester.pumpAndSettle();
    showAppFeedback(feedbackContext, 'Timer complete!');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Timer complete!'), findsNothing);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(restored, isTrue);
    expect(find.text('Timer complete!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

}