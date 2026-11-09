import 'package:flutter/material.dart';

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

// Holds the information shared by the app's main screens.
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
  // Start on Home, the first page in the list.
  int _selectedIndex = 0;

  // Keep these titles in the same order as the pages and bottom tabs.
  static const List<String> _pageTitles = [
    'Home',
    'Academics',
    'Study',
    'Insights',
    'Campus Map',
    'Settings',
  ];

  // Give the user some example courses and assignments on their first visit.
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

  // Count checkbox changes so an older Undo can't reverse a newer change.
  final Map<Assignment, int> _completionRevisions = {};

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Add up the time from saved sessions that finished today.
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

  Future<void> _addCourse() async {
    final String? course = await showDialog<String>(
      context: context,
      builder: (_) => AddCourseDialog(courses: _courses),
    );

    // Cancel returns no course. Also check that this screen is still open.
    if (!mounted || course == null) return;

    setState(() {
      _courses.add(course);
    });

    showAppFeedback(context, 'Course added');
  }

  Future<void> _addAssignment() async {
    final Assignment? newAssignment = await showDialog<Assignment>(
      context: context,
      builder: (_) => AddAssignmentDialog(courses: _courses),
    );

    if (!mounted || newAssignment == null) return;

    setState(() {
      _assignments.add(newAssignment);
    });

    showAppFeedback(context, 'Assignment added successfully!');
  }

  Future<void> _editAssignment(Assignment assignment) async {
    final Assignment? updated = await showDialog<Assignment>(
      context: context,
      builder: (_) => AddAssignmentDialog(
        courses: _courses,
        assignment: assignment,
      ),
    );

    if (!mounted || updated == null) return;

    // Replace the original assignment in the same spot in the list.
    final int index = _assignments.indexOf(assignment);
    if (index < 0) return;

    setState(() {
      _assignments[index] = updated;
    });

    showAppFeedback(context, 'Assignment updated');
  }

  void _toggleAssignment(Assignment assignment) {
    final bool wasCompleted = assignment.isCompleted;
    final int revision = (_completionRevisions[assignment] ?? 0) + 1;

    setState(() {
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
        // Undo only if the assignment still exists and this was its last change.
        if (!mounted ||
            !_assignments.contains(assignment) ||
            _completionRevisions[assignment] != revision) {
          return;
        }

        setState(() {
          assignment.isCompleted = wasCompleted;
          _completionRevisions[assignment] = revision + 1;
        });
      },
    );
  }

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

    setState(() {
      _assignments.removeAt(index);
    });

    showAppFeedback(
      context,
      'Assignment deleted',
      onUndo: () {
        if (!mounted || _assignments.contains(assignment)) return;

        // Put it back in its old spot, or at the end if the list got shorter.
        final int restoreIndex =
        index <= _assignments.length ? index : _assignments.length;

        setState(() {
          _assignments.insert(restoreIndex, assignment);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int studiedSeconds = _todayStudySeconds;

    // Give each page the information and actions it needs.
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
      InsightsScreen(
        assignments: _assignments,
        sessions: _sessions,
      ),
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

      // Keep the other pages open so the study timer can keep running.
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
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