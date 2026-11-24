import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/assignment.dart';

// Owns notification setup, permission requests and assignment reminders.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initialization;

  // MainScreen will provide the action for opening an assignment.
  void Function(int assignmentId)? onAssignmentTapped;

  // This implementation targets Android.
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // --------------------------------------------------
  // INITIALIZE WITHOUT ASKING FOR PERMISSION
  // --------------------------------------------------

  Future<void> initialize() async {
    if (!isSupported) return;

    final Future<void> initialization = _initialization ??= _initializePlugin();

    try {
      await initialization;
    } catch (_) {
      // Allow a later retry if initialization fails.
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initializePlugin() async {
    tz_data.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onTap,
    );
  }

  // --------------------------------------------------
  // CHECK AND REQUEST PERMISSION
  // --------------------------------------------------

  Future<bool> notificationsAllowed() async {
    if (!isSupported) return false;

    await initialize();

    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await android?.areNotificationsEnabled() ?? false;
  }

  // Call after the user chooses to enable reminders.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;

    await initialize();

    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await android?.requestNotificationsPermission() ?? false;
  }

  // --------------------------------------------------
  // NOTIFICATION APPEARANCE
  // --------------------------------------------------

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'assignment_reminders',
      'Assignment reminders',
      channelDescription: 'Reminders for your assignment deadlines',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  // --------------------------------------------------
  // SHOW AN ASSIGNMENT REMINDER NOW
  // --------------------------------------------------

  // Like the bell button in the class example.
  // Permission is handled by the calling screen.
  Future<void> showAssignment(Assignment assignment) async {
    if (!isSupported || assignment.isCompleted) return;
    if (!await notificationsAllowed()) return;

    await _plugin.show(
      id: assignment.id,
      title: assignment.title,
      body: '${assignment.course}. Tap to view the assignment.',
      notificationDetails: _details,
      payload: '${assignment.id}',
    );
  }

  // --------------------------------------------------
  // SCHEDULE A DEADLINE REMINDER
  // --------------------------------------------------

  Future<void> scheduleAssignment(Assignment assignment) async {
    if (!isSupported) return;

    await initialize();

    // Remove the old reminder before replacing it.
    await _plugin.cancel(id: assignment.id);

    if (assignment.isCompleted || !assignment.dueDate.isAfter(DateTime.now())) {
      return;
    }

    if (!await notificationsAllowed()) return;

    await _plugin.zonedSchedule(
      id: assignment.id,
      title: 'Assignment due: ${assignment.title}',
      body: '${assignment.course}. Tap to view the assignment.',

      // Preserve the exact instant chosen in the date and time pickers.
      scheduledDate: tz.TZDateTime.from(assignment.dueDate, tz.UTC),
      notificationDetails: _details,
      payload: '${assignment.id}',

      // Avoid requesting special exact-alarm access.
      // Android may delay delivery to manage battery usage.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // --------------------------------------------------
  // CANCEL REMINDERS
  // --------------------------------------------------

  // Used when an assignment is completed or deleted.
  Future<void> cancelAssignment(int assignmentId) async {
    if (!isSupported) return;

    await initialize();
    await _plugin.cancel(id: assignmentId);
  }

  // Used when the user turns assignment reminders off.
  Future<void> cancelAll() async {
    if (!isSupported) return;

    await initialize();
    await _plugin.cancelAll();
  }

  // --------------------------------------------------
  // HANDLE NOTIFICATION TAPS
  // --------------------------------------------------

  void _onTap(NotificationResponse response) {
    final int? assignmentId = int.tryParse(response.payload ?? '');

    if (assignmentId == null) return;

    onAssignmentTapped?.call(assignmentId);
  }

  // A notification that launches a closed app is checked separately.
  Future<int?> getLaunchAssignmentId() async {
    if (!isSupported) return null;

    await initialize();

    final NotificationAppLaunchDetails? details = await _plugin
        .getNotificationAppLaunchDetails();

    if (details?.didNotificationLaunchApp != true) return null;

    return int.tryParse(details?.notificationResponse?.payload ?? '');
  }
}
