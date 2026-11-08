// Own the shared assignment list and selected tab. Pass data and callbacks to HomeScreen.

import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../dialogs/add_assignment_dialog.dart';
import 'home_screen.dart';
import 'placeholder_page.dart';
import 'settings_screen.dart';
import 'study_screen.dart';
import 'insights_screen.dart';
import '../models/study_session.dart';
import 'academics_screen.dart';
import '../dialogs/add_course_dialog.dart';
import '../widgets/app_drawer.dart';

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

  int selectedIndex = 0;
  final List<StudySession> _sessions = [];
  int _goalMinutes = 120;

  // Attribute a saved session to its completion date. Unsaved time is excluded.
  int get _todayStudySeconds {
    final DateTime today = DateTime.now();
    return _sessions.where((StudySession session) =>
      session.completedAt.year == today.year && session.completedAt.month == today.month &&
      session.completedAt.day == today.day
    ).fold<int>(0, (int total, StudySession session) => total + session.seconds);
  }

  void _saveStudySession(StudySession session) {
    setState(() { _sessions.add(session); });
    _feedback('Study session saved');
  }

  void _changeGoal(int minutes) {
    setState(() { _goalMinutes = minutes; });
    _feedback('Daily goal updated');
  }


  final List<String> courses = [
    'DEMO101 - Computer Graphics',
    'CSCI3101U - Mobile Devices',
    'DEMO102 - Machine Learning',
  ];

  void _feedback(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addCourse() async {
    final String? course = await showDialog<String>(
      context: context, builder: (_) => AddCourseDialog(courses: courses));
    if (!mounted || course == null) return;
    setState(() { courses.add(course); });
    _feedback('Course added');
  }

  Future<void> _editAssignment(Assignment assignment) async {
    final Assignment? updated = await showDialog<Assignment>(
      context: context,
      builder: (_) => AddAssignmentDialog(courses: courses, assignment: assignment));
    if (!mounted || updated == null) return;
    final int index = assignments.indexOf(assignment);
    if (index < 0) return;
    setState(() { assignments[index] = updated; });
    _feedback('Assignment updated');
  }

  void _toggleAssignment(Assignment assignment) {
    setState(() { assignment.isCompleted = !assignment.isCompleted; });
    _feedback(assignment.isCompleted ? 'Assignment completed' : 'Assignment marked incomplete');
  }

  Future<void> _deleteAssignment(Assignment assignment) async {
    final bool? confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Delete assignment?'), content: Text('Delete "${assignment.title}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
      ]));
    if (!mounted || confirmed != true) return;
    final int index = assignments.indexOf(assignment);
    if (index < 0) return;
    setState(() { assignments.removeAt(index); });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: const Text('Assignment deleted'),
        action: SnackBarAction(label: 'Undo', onPressed: () {
          if (!mounted) return;
          setState(() { assignments.insert(index <= assignments.length ? index : assignments.length, assignment); });
        })));
  }

  // Temporary sample assignments.
  // Later these will come from local/cloud storage.

  final List<Assignment> assignments = [
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

  final List<String> pageTitles = [
    'Home',
    'Academics',
    'Study',
    'Insights',
    'Campus Map',
    'Settings',
  ];

  // --------------------------------------------------
  // ADD ASSIGNMENT DIALOG
  // --------------------------------------------------

  Future<void> addAssignment() async {
    final newAssignment = await showDialog<Assignment>(
      context: context,
      builder: (dialogContext) {
        return AddAssignmentDialog(courses: courses);
      },
    );

    if (!mounted) return;

    if (newAssignment != null) {
      setState(() {
        assignments.add(newAssignment);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment added successfully!'),
        ),
      );
    }
  }



  // --------------------------------------------------
  // BUILD MAIN APPLICATION
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {

    final List<Widget> pages = [

      HomeScreen(
        assignments: assignments,
        studiedSeconds: _todayStudySeconds,
        goalMinutes: _goalMinutes,
        onAddAssignment: addAssignment,
        onOpenAcademics: () {
          setState(() {
            selectedIndex = 1;
          });
        },
        onOpenStudy: () {
          setState(() {
            selectedIndex = 2;
          });
        },
        onToggleAssignment: _toggleAssignment,
      ),

      AcademicsScreen(
        courses: courses, assignments: assignments,
        onAddCourse: _addCourse, onAddAssignment: addAssignment,
        onEdit: _editAssignment, onDelete: _deleteAssignment,
        onToggle: _toggleAssignment,
      ),

      StudyScreen(
        courses: courses, sessions: _sessions, goalMinutes: _goalMinutes,
        studiedSeconds: _todayStudySeconds,
        onSaveSession: _saveStudySession, onGoalChanged: _changeGoal,
      ),

      InsightsScreen(assignments: assignments, sessions: _sessions),

      const PlaceholderPage(
        icon: Icons.map_outlined,
        description:
        'Find study spaces, buildings and services on campus.',
      ),

      SettingsScreen(
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
    ];

    return Scaffold(
      drawer: AppDrawer(
        selectedIndex: selectedIndex,
        onPageSelected: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),

      appBar: AppBar(
        title: Text(
          pageTitles[selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

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
