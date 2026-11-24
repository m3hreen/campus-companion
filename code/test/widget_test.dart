import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:code/main.dart';
import 'package:code/utils/app_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel notificationChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  setUp(() {
    // Start each test with empty storage, independent of device settings.
    SharedPreferences.setMockInitialValues({});

    // Widget tests have no Android notification service.
    // Simulate normal startup without requesting real permissions.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationChannel, (call) async {
          switch (call.method) {
            case 'initialize':
              return true;
            case 'getNotificationAppLaunchDetails':
              return {'notificationLaunchedApp': false};
            case 'areNotificationsEnabled':
            case 'requestNotificationsPermission':
              return false;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationChannel, null);
  });

  testWidgets('Begin opens the dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusCompanionApp());

    // Wait for saved settings and notification launch checks to finish.
    await tester.pumpAndSettle();

    final Finder beginButton = find.text('Begin');
    expect(beginButton, findsOneWidget);

    // Begin may be below the visible area on a small test screen.
    await tester.ensureVisible(beginButton);
    await tester.pumpAndSettle();

    await tester.tap(beginButton);

    // MainScreen also restores its saved data asynchronously.
    await tester.pumpAndSettle();

    expect(find.text('Welcome back!'), findsOneWidget);
    expect(beginButton, findsNothing);

    // Dispose the app and any loading widgets before ending the test.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('Timer feedback preserves the current Undo action', (
    WidgetTester tester,
  ) async {
    bool restored = false;
    late BuildContext feedbackContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              feedbackContext = context;
              return const SizedBox.shrink();
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

    // Timer feedback must queue behind the visible deletion Undo.
    showAppFeedback(feedbackContext, 'Timer complete!');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Timer complete!'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(restored, isTrue);
    expect(find.text('Timer complete!'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
