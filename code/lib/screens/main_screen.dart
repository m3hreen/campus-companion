import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dialogs/add_assignment_dialog.dart';
import '../dialogs/add_course_dialog.dart';
import '../models/assignment.dart';
import '../models/study_session.dart';
import '../services/notification_service.dart';
import '../utils/app_feedback.dart';
import '../widgets/app_drawer.dart';
import 'academics_screen.dart';
import 'campus_directory_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';
import 'study_screen.dart';

// Owns shared data, storage, navigation and assignment reminder callbacks.
class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // --------------------------------------------------
  // NAVIGATION
  // --------------------------------------------------

  int _selectedIndex = 0;

  static const List<String> _pageTitles = [
    'Home',
    'Academics',
    'Study',
    'Insights',
    'Campus Map',
    'Settings',
  ];

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --------------------------------------------------
  // SHARED DATA
  // --------------------------------------------------

  // Used only when no academic save exists.
  final List<String> _courses = [
    'DEMO101 - Computer Graphics',
    'CSCI3101U - Mobile Devices',
    'DEMO102 - Machine Learning',
  ];

  final List<Assignment> _assignments = [
    Assignment(
      title: 'Computer Graphics Project',
      course: 'DEMO101 - Computer Graphics',
      dueDate: DateTime.now().add(const Duration(days: 2)),
    ),
    Assignment(
      title: 'Mobile Devices Lab',
      course: 'CSCI3101U - Mobile Devices',
      dueDate: DateTime.now().add(const Duration(days: 4)),
    ),
    Assignment(
      title: 'Research Report',
      course: 'DEMO102 - Machine Learning',
      dueDate: DateTime.now().add(const Duration(days: 7)),
    ),
  ];

  final List<StudySession> _sessions = [];
  int _goalMinutes = 120;

  // An older Undo must not reverse a newer completion change.
  final Map<Assignment, int> _completionRevisions = {};

  // --------------------------------------------------
  // STORAGE AND NOTIFICATION STATE
  // --------------------------------------------------

  static const String _academicStorageKey = 'campus_academics_v1';

  final NotificationService _notifications = NotificationService.instance;

  bool _loadingAcademics = true;
  bool _remindersEnabled = false;
  bool _updatingReminders = false;

  String? _storageError;
  String? _notificationError;
  String? _lastReminderSignature;

  int _pendingSaveCount = 0;
  int? _pendingNotificationTap;

  // Serialize saves and scheduling so rapid edits finish in the correct order.
  Future<void> _pendingSave = Future<void>.value();

  @override
  void initState() {
    super.initState();

    _notifications.onAssignmentTapped = _handleNotificationTap;
    _loadAcademics();
  }

  @override
  void dispose() {
    _notifications.onAssignmentTapped = null;
    super.dispose();
  }

  // --------------------------------------------------
  // RESTORE SAVED DATA
  // --------------------------------------------------

  Future<void> _loadAcademics() async {
    setState(() {
      _loadingAcademics = true;
      _storageError = null;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? saved = prefs.getString(_academicStorageKey);

      if (!mounted) return;

      if (saved != null) {
        final Map<String, dynamic> data =
            jsonDecode(saved) as Map<String, dynamic>;

        // Decode everything before replacing the current state.
        final List<String> courses = List<String>.from(data['courses'] as List);

        final List<Assignment> assignments = (data['assignments'] as List).map((
          item,
        ) {
          return Assignment.fromJson(Map<String, dynamic>.from(item as Map));
        }).toList();

        // Support older saves that do not contain these fields.
        final List<StudySession> sessions = (data['sessions'] as List? ?? [])
            .map((item) {
              return StudySession.fromJson(
                Map<String, dynamic>.from(item as Map),
              );
            })
            .toList();

        final int goalMinutes = data['goalMinutes'] as int? ?? 120;
        final bool remindersEnabled =
            data['remindersEnabled'] as bool? ?? false;

        if (goalMinutes < 1 || goalMinutes > 1440) {
          throw const FormatException('Invalid daily study goal');
        }

        _courses
          ..clear()
          ..addAll(courses);

        _assignments
          ..clear()
          ..addAll(assignments);

        _sessions
          ..clear()
          ..addAll(sessions);

        _goalMinutes = goalMinutes;
        _remindersEnabled = remindersEnabled;
      }

      setState(() {
        _completionRevisions.clear();
        _loadingAcademics = false;
      });
    } catch (_) {
      if (!mounted) return;

      // Do not overwrite saved data if reading or decoding fails.
      setState(() {
        _storageError = 'Could not load your saved app data. Please retry.';
      });

      return;
    }

    // Save newly generated IDs for older assignments before scheduling them.
    // On a fresh installation, this also saves the sample data.
    _saveAcademics();
    _prepareNotificationTaps();
  }

  // --------------------------------------------------
  // SAVE DATA, THEN UPDATE REMINDERS
  // --------------------------------------------------

  Future<void> _saveAcademics() {
    final List<Map<String, dynamic>> assignmentData = _assignments
        .map((assignment) => assignment.toJson())
        .toList();

    final bool remindersEnabled = _remindersEnabled;

    // Capture values now, before another action changes the shared data.
    final String snapshot = jsonEncode({
      'courses': List<String>.of(_courses),
      'assignments': assignmentData,
      'sessions': _sessions.map((session) => session.toJson()).toList(),
      'goalMinutes': _goalMinutes,
      'remindersEnabled': remindersEnabled,
    });

    // Separate objects prevent later checkbox changes affecting this save.
    final List<Assignment> reminderAssignments = assignmentData
        .map((data) => Assignment.fromJson(data))
        .toList();

    setState(() {
      _pendingSaveCount++;
    });

    _pendingSave = _pendingSave.then((_) async {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        final bool saved = await prefs.setString(_academicStorageKey, snapshot);

        if (!saved) {
          throw StateError('Save failed');
        }

        if (mounted) {
          setState(() {
            _storageError = null;
          });
        }

        // Notification failures are reported separately from storage failures.
        try {
          await _synchronizeReminders(reminderAssignments, remindersEnabled);

          if (mounted) {
            setState(() {
              _notificationError = null;
            });
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _notificationError =
                  'Data saved, but reminders could not be updated. '
                  'Check Android notification permission and tap Retry.';
            });
          }
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _storageError =
                'Changes could not be saved. Retry before closing the app.';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _pendingSaveCount--;
          });
        }
      }
    });

    return _pendingSave;
  }

  void _updateAcademics(VoidCallback change) {
    setState(change);
    _saveAcademics();
  }

  // --------------------------------------------------
  // ENABLE OR DISABLE REMINDERS
  // --------------------------------------------------

  Future<void> _changeReminders(bool value) async {
    if (_updatingReminders) return;

    if (!_notifications.isSupported) {
      showAppFeedback(
        context,
        'Assignment notifications are available on Android.',
      );
      return;
    }

    setState(() {
      _updatingReminders = true;
    });

    try {
      // Ask only after the user chooses to enable reminders.
      if (value) {
        final bool allowed = await _notifications.requestPermission();

        if (!mounted) return;

        if (!allowed) {
          showAppFeedback(
            context,
            'Notifications are disabled. You can allow them in '
            'Android Settings > Apps > Campus Companion > Notifications.',
          );
          return;
        }
      }

      if (!mounted) return;

      setState(() {
        _remindersEnabled = value;

        // Force a refresh even if the assignment list has not changed.
        _lastReminderSignature = null;
      });

      await _saveAcademics();

      if (!mounted) return;

      if (_storageError == null && _notificationError == null) {
        showAppFeedback(
          context,
          value ? 'Assignment reminders enabled' : 'Assignment reminders off',
        );
      }
    } catch (_) {
      if (!mounted) return;

      showAppFeedback(
        context,
        'Could not update notification permission. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingReminders = false;
        });
      }
    }
  }

  Future<void> _synchronizeReminders(
    List<Assignment> assignments,
    bool enabled,
  ) async {
    if (!_notifications.isSupported) return;

    // Changes to study history or goals do not require rebuilding reminders.
    final String signature = jsonEncode({
      'enabled': enabled,
      'assignments': assignments.map((assignment) {
        return {
          'id': assignment.id,
          'title': assignment.title,
          'course': assignment.course,
          'dueDate': assignment.dueDate.toIso8601String(),
          'isCompleted': assignment.isCompleted,
        };
      }).toList(),
    });

    if (enabled && !await _notifications.notificationsAllowed()) {
      throw StateError('Android notification permission is disabled');
    }

    if (signature == _lastReminderSignature) return;

    // This service currently owns only assignment notifications.
    // Rebuilding removes obsolete reminders after edits, deletion or Undo.
    await _notifications.cancelAll();

    if (enabled) {
      for (final Assignment assignment in assignments) {
        await _notifications.scheduleAssignment(assignment);
      }
    }

    // Mark successful only after all scheduling operations finish.
    _lastReminderSignature = signature;
  }

  // --------------------------------------------------
  // SHOW A REMINDER NOW — LIKE THE CLASS BELL EXAMPLE
  // --------------------------------------------------

  Future<void> _showNextAssignmentReminder() async {
    try {
      if (!await _notifications.notificationsAllowed()) {
        if (!mounted) return;

        showAppFeedback(
          context,
          'Allow notifications in Android settings to show reminders.',
        );
        return;
      }

      if (!mounted) return;

      final List<Assignment> incomplete = _assignments
          .where((assignment) => !assignment.isCompleted)
          .toList();

      incomplete.sort(
        (first, second) => first.dueDate.compareTo(second.dueDate),
      );

      if (incomplete.isEmpty) {
        showAppFeedback(
          context,
          'No incomplete assignments to remind you about',
        );
        return;
      }

      await _notifications.showAssignment(incomplete.first);

      if (!mounted) return;

      showAppFeedback(context, 'Reminder sent. Check your notification shade.');
    } catch (_) {
      if (!mounted) return;

      showAppFeedback(context, 'Could not show the assignment reminder');
    }
  }

  // --------------------------------------------------
  // OPEN THE ASSIGNMENT FROM A NOTIFICATION
  // --------------------------------------------------

  Future<void> _prepareNotificationTaps() async {
    if (!_notifications.isSupported) return;

    try {
      await _notifications.initialize();

      final int? launchId = await _notifications.getLaunchAssignmentId();

      if (!mounted) return;

      final int? assignmentId = _pendingNotificationTap ?? launchId;
      _pendingNotificationTap = null;

      if (assignmentId == null) return;

      // Wait until the loaded MainScreen has been built before navigating.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleNotificationTap(assignmentId);
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _notificationError =
            'Could not initialize assignment notifications. Tap Retry.';
      });
    }
  }

  void _handleNotificationTap(int assignmentId) {
    if (!mounted) return;

    if (_loadingAcademics) {
      _pendingNotificationTap = assignmentId;
      return;
    }

    Assignment? matchingAssignment;

    for (final Assignment assignment in _assignments) {
      if (assignment.id == assignmentId) {
        matchingAssignment = assignment;
        break;
      }
    }

    if (matchingAssignment == null) {
      showAppFeedback(context, 'This assignment is no longer available');
      return;
    }

    final Assignment assignment = matchingAssignment;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _AssignmentDetailsScreen(assignment: assignment),
      ),
    );
  }

  Future<void> _retryNotifications() async {
    setState(() {
      _lastReminderSignature = null;
    });

    await _saveAcademics();
    await _prepareNotificationTaps();
  }

  // --------------------------------------------------
  // STUDY SESSIONS AND GOALS
  // --------------------------------------------------

  int get _todayStudySeconds {
    final DateTime today = DateTime.now();
    int total = 0;

    for (final StudySession session in _sessions) {
      final DateTime finished = session.completedAt;

      if (finished.year == today.year &&
          finished.month == today.month &&
          finished.day == today.day) {
        total += session.seconds;
      }
    }

    return total;
  }

  void _saveStudySession(StudySession session) {
    _updateAcademics(() {
      _sessions.add(session);
    });

    showAppFeedback(context, 'Study session saved');
  }

  void _changeGoal(int minutes) {
    _updateAcademics(() {
      _goalMinutes = minutes;
    });

    showAppFeedback(context, 'Daily goal updated');
  }

  // --------------------------------------------------
  // COURSES AND ASSIGNMENTS
  // --------------------------------------------------

  Future<void> _addCourse() async {
    final String? course = await showDialog<String>(
      context: context,
      builder: (_) => AddCourseDialog(courses: _courses),
    );

    if (!mounted || course == null) return;

    _updateAcademics(() {
      _courses.add(course);
    });

    showAppFeedback(context, 'Course added');
  }

  Future<void> _addAssignment() async {
    final Assignment? assignment = await showDialog<Assignment>(
      context: context,
      builder: (_) => AddAssignmentDialog(courses: _courses),
    );

    if (!mounted || assignment == null) return;

    _updateAcademics(() {
      _assignments.add(assignment);
    });

    showAppFeedback(context, 'Assignment added successfully!');
  }

  Future<void> _editAssignment(Assignment assignment) async {
    final Assignment? updated = await showDialog<Assignment>(
      context: context,
      builder: (_) =>
          AddAssignmentDialog(courses: _courses, assignment: assignment),
    );

    if (!mounted || updated == null) return;

    final int index = _assignments.indexOf(assignment);
    if (index < 0) return;

    _updateAcademics(() {
      _assignments[index] = updated;
      _completionRevisions.remove(assignment);
    });

    showAppFeedback(context, 'Assignment updated');
  }

  // --------------------------------------------------
  // COMPLETE ASSIGNMENT AND UNDO
  // --------------------------------------------------

  void _toggleAssignment(Assignment assignment) {
    final bool wasCompleted = assignment.isCompleted;
    final int revision = (_completionRevisions[assignment] ?? 0) + 1;

    _updateAcademics(() {
      assignment.isCompleted = !wasCompleted;
      _completionRevisions[assignment] = revision;
    });

    showAppFeedback(
      context,
      assignment.isCompleted
          ? 'Assignment completed'
          : 'Assignment marked incomplete',
      onUndo: () {
        if (!mounted ||
            !_assignments.contains(assignment) ||
            _completionRevisions[assignment] != revision) {
          return;
        }

        _updateAcademics(() {
          assignment.isCompleted = wasCompleted;
          _completionRevisions[assignment] = revision + 1;
        });
      },
    );
  }

  // --------------------------------------------------
  // DELETE ASSIGNMENT AND UNDO
  // --------------------------------------------------

  Future<void> _deleteAssignment(Assignment assignment) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete assignment?'),
        content: Text('Delete "${assignment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final int index = _assignments.indexOf(assignment);
    if (index < 0) return;

    _updateAcademics(() {
      _assignments.removeAt(index);

      // Invalidate completion Undo actions queued before deletion.
      _completionRevisions[assignment] =
          (_completionRevisions[assignment] ?? 0) + 1;
    });

    showAppFeedback(
      context,
      'Assignment deleted',
      onUndo: () {
        if (!mounted || _assignments.contains(assignment)) return;

        final int restoreIndex = index <= _assignments.length
            ? index
            : _assignments.length;

        _updateAcademics(() {
          _assignments.insert(restoreIndex, assignment);
        });
      },
    );
  }

  // --------------------------------------------------
  // BUILD MAIN SCREEN
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loadingAcademics) {
      return Scaffold(
        appBar: AppBar(title: const Text('Campus Companion')),
        body: Center(
          child: _storageError == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_storageError!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadAcademics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    final int studiedSeconds = _todayStudySeconds;

    final List<Widget> pages = [
      HomeScreen(
        assignments: _assignments,
        studiedSeconds: studiedSeconds,
        goalMinutes: _goalMinutes,
        onAddAssignment: _addAssignment,
        onOpenAcademics: () => _selectPage(1),
        onOpenStudy: () => _selectPage(2),
        onToggleAssignment: _toggleAssignment,
      ),
      AcademicsScreen(
        courses: _courses,
        assignments: _assignments,
        onAddCourse: _addCourse,
        onAddAssignment: _addAssignment,
        onEdit: _editAssignment,
        onDelete: _deleteAssignment,
        onToggle: _toggleAssignment,
      ),
      StudyScreen(
        courses: _courses,
        sessions: _sessions,
        goalMinutes: _goalMinutes,
        studiedSeconds: studiedSeconds,
        onSaveSession: _saveStudySession,
        onGoalChanged: _changeGoal,
      ),
      InsightsScreen(assignments: _assignments, sessions: _sessions),
      const CampusDirectoryScreen(),
      SettingsScreen(
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        remindersEnabled: _remindersEnabled,
        onRemindersChanged: _changeReminders,
        updatingReminders: _updatingReminders,
      ),
    ];

    return Scaffold(
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onPageSelected: _selectPage,
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
      appBar: AppBar(
        title: Text(
          _pageTitles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Like the class example: show a real assignment reminder now.
          if (_selectedIndex == 1 && _remindersEnabled)
            IconButton(
              tooltip: 'Show next assignment reminder',
              icon: const Icon(Icons.notifications_active_outlined),
              onPressed: _updatingReminders || _pendingSaveCount > 0
                  ? null
                  : _showNextAssignmentReminder,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_pendingSaveCount > 0)
            const LinearProgressIndicator(
              semanticsLabel: 'Saving app data and updating reminders',
            ),

          if (_storageError != null)
            MaterialBanner(
              content: Text(_storageError!),
              actions: [
                TextButton(
                  onPressed: _saveAcademics,
                  child: const Text('Retry'),
                ),
              ],
            ),

          if (_notificationError != null)
            MaterialBanner(
              content: Text(_notificationError!),
              actions: [
                TextButton(
                  onPressed: _retryNotifications,
                  child: const Text('Retry'),
                ),
              ],
            ),

          // Keep tabs mounted so navigation does not reset the study timer.
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Academics',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Study',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// A notification tap opens the matching assignment, like the class example.
// The content scrolls to support small screens and larger system text.
class _AssignmentDetailsScreen extends StatelessWidget {
  const _AssignmentDetailsScreen({required this.assignment});

  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final DateTime due = assignment.dueDate;
    final String date = '${due.day}/${due.month}/${due.year}';
    final String time = TimeOfDay.fromDateTime(due).format(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Assignment details')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(assignment.title, style: textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(assignment.course, style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Text('Due: $date at $time'),
          const SizedBox(height: 8),
          Text('Priority: ${assignment.priority}'),
          const SizedBox(height: 8),
          Text(
            assignment.isCompleted ? 'Status: Completed' : 'Status: Incomplete',
          ),
          if (assignment.description.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Description', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(assignment.description),
          ],
        ],
      ),
    );
  }
}
