import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dialogs/add_assignment_dialog.dart';
import '../dialogs/add_course_dialog.dart';
import '../models/assignment.dart';
import '../models/study_session.dart';
import '../utils/app_feedback.dart';
import '../widgets/app_drawer.dart';
import 'academics_screen.dart';
import 'campus_directory_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';
import 'study_screen.dart';

// Owns the data shared by Home, Academics, Study and Insights.
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

  // Keep titles, pages and navigation destinations in the same order.
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
  // SHARED APP DATA
  // --------------------------------------------------

  // These examples are saved on the first launch.
  // Later launches replace them with the user's saved data.
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

  // Study storage will be connected in the next step.
  final List<StudySession> _sessions = [];
  int _goalMinutes = 120;

  // Prevent an older Undo from reversing a newer completion change.
  final Map<Assignment, int> _completionRevisions = {};

  // --------------------------------------------------
  // COURSE AND ASSIGNMENT STORAGE
  // --------------------------------------------------

  static const String _academicStorageKey = 'campus_academics_v1';

  bool _loadingAcademics = true;
  String? _storageError;
  int _pendingSaveCount = 0;

  // Write snapshots in order so rapid changes save correctly.
  Future<void> _pendingSave = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _loadAcademics();
  }

  Future<void> _loadAcademics() async {
    setState(() {
      _loadingAcademics = true;
      _storageError = null;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? saved = prefs.getString(_academicStorageKey);

      if (!mounted) return;

      if (saved == null) {
        // No save exists yet. Show and save the sample data.
        setState(() {
          _loadingAcademics = false;
        });

        _saveAcademics();
        return;
      }

      final Map<String, dynamic> data =
          jsonDecode(saved) as Map<String, dynamic>;

      // Decode both lists before changing the current state.
      // If decoding fails, the existing saved data is left untouched.
      final List<String> courses = List<String>.from(data['courses'] as List);

      final List<Assignment> assignments = (data['assignments'] as List).map((
        item,
      ) {
        return Assignment.fromJson(Map<String, dynamic>.from(item as Map));
      }).toList();

      setState(() {
        _courses
          ..clear()
          ..addAll(courses);

        _assignments
          ..clear()
          ..addAll(assignments);

        _completionRevisions.clear();
        _loadingAcademics = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _storageError =
            'Could not load your courses and assignments. Please retry.';
      });
    }
  }

  void _saveAcademics() {
    // Capture the data now, before another user action changes it.
    final String snapshot = jsonEncode({
      'courses': List<String>.of(_courses),
      'assignments': _assignments
          .map((assignment) => assignment.toJson())
          .toList(),
    });

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

        if (!mounted) return;

        setState(() {
          _storageError = null;
        });
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _storageError =
              'Changes could not be saved. Retry before closing the app.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _pendingSaveCount--;
          });
        }
      }
    });
  }

  // All course and assignment changes use this helper, including Undo.
  void _updateAcademics(VoidCallback change) {
    setState(change);
    _saveAcademics();
  }

  // --------------------------------------------------
  // STUDY SESSIONS AND DAILY GOAL
  // --------------------------------------------------

  // Count only saved sessions that finished today.
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
    setState(() {
      _sessions.add(session);
    });

    showAppFeedback(context, 'Study session saved');
  }

  void _changeGoal(int minutes) {
    setState(() {
      _goalMinutes = minutes;
    });

    showAppFeedback(context, 'Daily goal updated');
  }

  // --------------------------------------------------
  // ADD COURSE
  // --------------------------------------------------

  Future<void> _addCourse() async {
    final String? course = await showDialog<String>(
      context: context,
      builder: (_) => AddCourseDialog(courses: _courses),
    );

    // Cancel returns null. Do not update a screen that has closed.
    if (!mounted || course == null) return;

    _updateAcademics(() {
      _courses.add(course);
    });

    showAppFeedback(context, 'Course added');
  }

  // --------------------------------------------------
  // ADD AND EDIT ASSIGNMENTS
  // --------------------------------------------------

  Future<void> _addAssignment() async {
    final Assignment? newAssignment = await showDialog<Assignment>(
      context: context,
      builder: (_) => AddAssignmentDialog(courses: _courses),
    );

    if (!mounted || newAssignment == null) return;

    _updateAcademics(() {
      _assignments.add(newAssignment);
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

    // Keep the assignment in its original position.
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

    final String message = assignment.isCompleted
        ? 'Assignment completed'
        : 'Assignment marked incomplete';

    showAppFeedback(
      context,
      message,
      onUndo: () {
        // Ignore Undo if this assignment was removed, replaced or changed again.
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

      // Invalidate any completion Undo queued before this deletion.
      _completionRevisions[assignment] =
          (_completionRevisions[assignment] ?? 0) + 1;
    });

    showAppFeedback(
      context,
      'Assignment deleted',
      onUndo: () {
        if (!mounted || _assignments.contains(assignment)) return;

        // Restore the original position, or append if the list is now shorter.
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
  // BUILD THE APPLICATION
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Block editing until saved data has loaded.
    // A failed read offers Retry without overwriting the saved file.
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

    // Pass shared data and callbacks to each screen.
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
      ),
      body: Column(
        children: [
          // Wait for this indicator to disappear before testing a restart.
          if (_pendingSaveCount > 0)
            const LinearProgressIndicator(
              semanticsLabel: 'Saving courses and assignments',
            ),

          // Keep save failures visible until a write succeeds.
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

          // Keep all tabs mounted so switching pages preserves the timer.
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
