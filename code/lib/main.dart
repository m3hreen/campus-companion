
import 'package:flutter/material.dart';

void main() {
  runApp(const CampusCompanionApp());
}

// --------------------------------------------------
// 1. MAIN APPLICATION
// --------------------------------------------------

class CampusCompanionApp extends StatelessWidget {
  const CampusCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Companion',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF397D78),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8F7),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
class AddAssignmentDialog extends StatefulWidget {
  const AddAssignmentDialog({super.key});

  @override
  State<AddAssignmentDialog> createState() =>
      _AddAssignmentDialogState();
}

class _AddAssignmentDialogState
    extends State<AddAssignmentDialog> {

  final titleController = TextEditingController();

  DateTime selectedDate =
  DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Assignment'),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Assignment title',
              hintText: 'Enter assignment name',
            ),
          ),

          const SizedBox(height: 20),

          const Text('Due date'),

          TextButton.icon(
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(
                  const Duration(days: 365),
                ),
              );

              if (!mounted) return;

              if (pickedDate != null) {
                setState(() {
                  selectedDate = pickedDate;
                });
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            ),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),

        FilledButton(
          onPressed: () {
            final title = titleController.text.trim();

            if (title.isEmpty) return;

            Navigator.pop(
              context,
              Assignment(
                title: title,
                course: 'General',
                dueDate: selectedDate,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
// --------------------------------------------------
// 2. ASSIGNMENT MODEL
// --------------------------------------------------

class Assignment {
  final String title;
  final String course;
  final DateTime dueDate;
  bool isCompleted;

  Assignment({
    required this.title,
    required this.course,
    required this.dueDate,
    this.isCompleted = false,
  });
}

// --------------------------------------------------
// 3. MAIN SCREEN AND NAVIGATION
// --------------------------------------------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int selectedIndex = 0;

  // Temporary sample assignments.
  // Later these will come from local/cloud storage.

  final List<Assignment> assignments = [
    Assignment(
      title: 'Computer Graphics Project',
      course: 'Computer Graphics',
      dueDate: DateTime.now().add(const Duration(days: 2)),
    ),
    Assignment(
      title: 'Mobile Devices Lab',
      course: 'Mobile Devices',
      dueDate: DateTime.now().add(const Duration(days: 4)),
    ),
    Assignment(
      title: 'Research Report',
      course: 'Machine Learning',
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
        return const AddAssignmentDialog();
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
        onToggleAssignment: (assignment) {
          setState(() {
            assignment.isCompleted = !assignment.isCompleted;
          });
        },
      ),

      const PlaceholderPage(
        icon: Icons.menu_book,
        description:
        'Manage your courses, assignments and deadlines.',
      ),

      const PlaceholderPage(
        icon: Icons.timer_outlined,
        description:
        'Track your study sessions and reach your study goals.',
      ),

      const PlaceholderPage(
        icon: Icons.bar_chart,
        description:
        'View your academic progress and study statistics.',
      ),

      const PlaceholderPage(
        icon: Icons.map_outlined,
        description:
        'Find study spaces, buildings and services on campus.',
      ),

      const PlaceholderPage(
        icon: Icons.settings_outlined,
        description:
        'Customize your Campus Companion experience.',
      ),
    ];

    return Scaffold(

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

// --------------------------------------------------
// 4. HOME SCREEN
// --------------------------------------------------

class HomeScreen extends StatelessWidget {

  final List<Assignment> assignments;

  final VoidCallback onAddAssignment;
  final VoidCallback onOpenAcademics;
  final VoidCallback onOpenStudy;

  final Function(Assignment) onToggleAssignment;

  const HomeScreen({
    super.key,
    required this.assignments,
    required this.onAddAssignment,
    required this.onOpenAcademics,
    required this.onOpenStudy,
    required this.onToggleAssignment,
  });

  @override
  Widget build(BuildContext context) {

    final completedCount =
        assignments.where((a) => a.isCompleted).length;

    final totalCount = assignments.length;

    final progress = totalCount == 0
        ? 0.0
        : completedCount / totalCount;

    final upcomingAssignments = assignments
        .where((a) => !a.isCompleted)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        // WELCOME SECTION

        const Text(
          'Welcome back!',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          'Here is your campus overview for today.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 25),

        // DAILY GOAL CARD

        const DailyGoalCard(),

        const SizedBox(height: 20),

        // QUICK ACTIONS

        const SectionTitle(title: 'Quick Actions'),

        const SizedBox(height: 12),

        Row(
          children: [

            Expanded(
              child: QuickActionCard(
                icon: Icons.add_task,
                title: 'Add Assignment',
                onTap: onAddAssignment,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: QuickActionCard(
                icon: Icons.play_circle_outline,
                title: 'Start Studying',
                onTap: onOpenStudy,
              ),
            ),
          ],
        ),

        const SizedBox(height: 25),

        // ASSIGNMENT PROGRESS

        const SectionTitle(title: 'Assignment Progress'),

        const SizedBox(height: 12),

        Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [

                    const Text(
                      'Completed assignments',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    Text(
                      '$completedCount / $totalCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFF397D78),
                ),

                const SizedBox(height: 10),

                Text(
                  '${(progress * 100).round()}% completed',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 25),

        // UPCOMING ASSIGNMENTS

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            const SectionTitle(
              title: 'Upcoming Assignments',
            ),

            TextButton(
              onPressed: onOpenAcademics,
              child: const Text('View all'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (upcomingAssignments.isEmpty)

          const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No upcoming assignments. You are all caught up!',
                textAlign: TextAlign.center,
              ),
            ),
          )

        else

          ...upcomingAssignments.take(4).map(
                (assignment) {

              return AssignmentCard(
                assignment: assignment,
                onToggle: () {
                  onToggleAssignment(assignment);
                },
              );
            },
          ),

        const SizedBox(height: 25),

        // WEATHER PLACEHOLDER

        const SectionTitle(title: 'Campus Weather'),

        const SizedBox(height: 12),

        Card(
          elevation: 0,
          color: const Color(0xFFE7F0EF),

          child: const Padding(
            padding: EdgeInsets.all(20),

            child: Row(
              children: [

                Icon(
                  Icons.cloud_outlined,
                  size: 45,
                  color: Color(0xFF397D78),
                ),

                SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      Text(
                        'Weather information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Live campus weather will appear here.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

// --------------------------------------------------
// 5. DAILY GOAL CARD
// --------------------------------------------------

class DailyGoalCard extends StatelessWidget {

  const DailyGoalCard({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xFF397D78),
        borderRadius: BorderRadius.circular(18),
      ),

      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Icon(
                Icons.flag_outlined,
                color: Colors.white,
              ),

              SizedBox(width: 10),

              Text(
                'Daily Study Goal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),

          SizedBox(height: 18),

          Text(
            '60 / 120 minutes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 12),

          LinearProgressIndicator(
            value: 0.5,
            minHeight: 9,
            backgroundColor: Color(0xFF8FB9B5),
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),

          SizedBox(height: 10),

          Text(
            'You are halfway to your daily goal!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// 6. QUICK ACTION CARD
// --------------------------------------------------

class QuickActionCard extends StatelessWidget {

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 0,
      color: Colors.white,

      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 10,
          ),

          child: Column(
            children: [

              Icon(
                icon,
                size: 30,
                color: const Color(0xFF397D78),
              ),

              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// 7. ASSIGNMENT CARD
// --------------------------------------------------

class AssignmentCard extends StatelessWidget {

  final Assignment assignment;
  final VoidCallback onToggle;

  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.onToggle,
  });

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 0,
      color: Colors.white,

      margin: const EdgeInsets.only(bottom: 10),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Row(
          children: [

            Checkbox(
              value: assignment.isCompleted,
              onChanged: (_) => onToggle(),
              activeColor: const Color(0xFF397D78),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  Text(
                    assignment.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: assignment.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    assignment.course,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [

                      Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: Colors.grey.shade600,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        'Due: ${formatDate(assignment.dueDate)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// 8. REUSABLE SECTION TITLE
// --------------------------------------------------

class SectionTitle extends StatelessWidget {

  final String title;

  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {

    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// --------------------------------------------------
// 9. PLACEHOLDER PAGES
// --------------------------------------------------

class PlaceholderPage extends StatelessWidget {

  final IconData icon;
  final String description;

  const PlaceholderPage({
    super.key,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(
              icon,
              size: 75,
              color: const Color(0xFF397D78),
            ),

            const SizedBox(height: 20),

            const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
