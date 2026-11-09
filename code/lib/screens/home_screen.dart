import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../widgets/assignment_card.dart';
import '../widgets/daily_goal_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/section_title.dart';

// Shows the study goal and assignments that MainScreen passes in.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.assignments,
    required this.studiedSeconds,
    required this.goalMinutes,
    required this.onAddAssignment,
    required this.onOpenAcademics,
    required this.onOpenStudy,
    required this.onToggleAssignment,
  });

  final List<Assignment> assignments;
  final int studiedSeconds;
  final int goalMinutes;

  // MainScreen handles these actions when the user taps something on Home.
  final VoidCallback onAddAssignment;
  final VoidCallback onOpenAcademics;
  final VoidCallback onOpenStudy;
  final ValueChanged<Assignment> onToggleAssignment;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int completedCount =
        assignments.where((assignment) => assignment.isCompleted).length;
    final int totalCount = assignments.length;

    // Use a new list so sorting here doesn't change the shared list.
    final List<Assignment> upcomingAssignments = assignments
        .where((assignment) => !assignment.isCompleted)
        .toList();
    upcomingAssignments.sort(
          (first, second) => first.dueDate.compareTo(second.dueDate),
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
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
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 25),
        DailyGoalCard(
          studiedSeconds: studiedSeconds,
          goalMinutes: goalMinutes,
        ),
        const SizedBox(height: 20),
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
        const SectionTitle(title: 'Assignment Progress'),
        const SizedBox(height: 12),
        _buildProgressCard(colors, completedCount, totalCount),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle(title: 'Upcoming Assignments'),
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
          ),

        // Keep the dashboard short by showing only the first four.
        for (final Assignment assignment in upcomingAssignments.take(4))
          AssignmentCard(
            assignment: assignment,
            onToggle: () => onToggleAssignment(assignment),
          ),

        const SizedBox(height: 25),
        const SectionTitle(title: 'Campus Weather'),
        const SizedBox(height: 12),
        _buildWeatherCard(colors),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProgressCard(
      ColorScheme colors,
      int completedCount,
      int totalCount,
      ) {
    // Show 0% when the list is empty so we don't divide by zero.
    final double progress =
    totalCount == 0 ? 0.0 : completedCount / totalCount;
    final int percentCompleted = (progress * 100).round();

    return Card(
      elevation: 0,
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Completed assignments',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$completedCount / $totalCount',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: colors.surfaceContainerHighest,
              color: const Color(0xFF397D78),
            ),
            const SizedBox(height: 10),
            Text(
              '$percentCompleted% completed',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // This card holds the spot where live weather will go.
  Widget _buildWeatherCard(ColorScheme colors) {
    return Card(
      elevation: 0,
      color: colors.secondaryContainer,
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}