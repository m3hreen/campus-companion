import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../models/study_session.dart';
import '../widgets/weekly_study_chart.dart';

// Calculates progress from the assignments and study sessions passed in.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({
    super.key,
    required this.assignments,
    required this.sessions,
  });

  final List<Assignment> assignments;
  final List<StudySession> sessions;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    // Include today and the six calendar days before it.
    final List<DateTime> dates = List<DateTime>.generate(
      7,
          (index) => DateTime(now.year, now.month, now.day - 6 + index),
    );

    final List<int> dailySeconds = dates.map((date) {
      int seconds = 0;

      for (final StudySession session in sessions) {
        if (DateUtils.isSameDay(session.completedAt, date)) {
          seconds += session.seconds;
        }
      }

      return seconds;
    }).toList();

    final int weekSeconds =
    dailySeconds.fold<int>(0, (sum, seconds) => sum + seconds);
    final int totalSeconds =
    sessions.fold<int>(0, (sum, session) => sum + session.seconds);
    final int completed =
        assignments.where((assignment) => assignment.isCompleted).length;

    // A finished assignment does not count as overdue.
    final int overdue = assignments.where((assignment) {
      return !assignment.isCompleted && assignment.dueDate.isBefore(now);
    }).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Your progress',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Calculated from your current assignments and saved study sessions.',
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(totalSeconds, weekSeconds),
        _buildHeading(context, 'Assignment completion'),
        _buildAssignmentCard(context, completed, overdue),
        _buildHeading(context, 'Study time by course'),
        _buildCourseCard(context, totalSeconds),
        _buildHeading(context, 'Daily study activity'),
        const Text('Saved study minutes over the last 7 days.'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (weekSeconds == 0)
                  const Text('No saved study time in the last 7 days.'),
                WeeklyStudyChart(dates: dates, seconds: dailySeconds),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Only saved sessions count. Each session counts toward the day '
              'it finished. Data currently resets when the app restarts.',
        ),
      ],
    );
  }

  Widget _buildSummaryCard(int totalSeconds, int weekSeconds) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Total study time'),
            subtitle: Text(_formatDuration(totalSeconds)),
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('Last 7 days'),
            subtitle: Text(_formatDuration(weekSeconds)),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Saved sessions'),
            subtitle: Text('${sessions.length}'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(
      BuildContext context,
      int completed,
      int overdue,
      ) {
    final int total = assignments.length;
    final double completion = total == 0 ? 0.0 : completed / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (total == 0)
              const Text('No assignments yet. Add one in Academics.')
            else
              _buildBar(
                context,
                '$completed of $total completed',
                '${(completion * 100).round()}%',
                completion,
              ),
            Text('${total - completed} remaining • $overdue overdue'),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, int totalSeconds) {
    // Each course name points to its total number of study seconds.
    final Map<String, int> secondsByCourse = {};

    for (final StudySession session in sessions) {
      final int previousSeconds = secondsByCourse[session.course] ?? 0;
      secondsByCourse[session.course] = previousSeconds + session.seconds;
    }

    // Show the courses with the most study time first.
    final List<MapEntry<String, int>> courseTotals =
    secondsByCourse.entries.toList();
    courseTotals.sort((first, second) => second.value.compareTo(first.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (courseTotals.isEmpty)
              const Text('Save a study session to see your course breakdown.'),
            for (final MapEntry<String, int> course in courseTotals)
              _buildCourseBar(context, course, totalSeconds),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseBar(
      BuildContext context,
      MapEntry<String, int> course,
      int totalSeconds,
      ) {
    // Each bar shows this course's share of all saved study time.
    final double share = totalSeconds == 0 ? 0.0 : course.value / totalSeconds;
    final int percent = (share * 100).round();

    return _buildBar(
      context,
      course.key,
      '${_formatDuration(course.value)} • $percent%',
      share,
    );
  }

  String _formatDuration(int seconds) {
    // Divide by 60 for whole minutes, then show the leftover seconds.
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '$minutes min $remainingSeconds sec';
  }

  Widget _buildHeading(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildBar(
      BuildContext context,
      String label,
      String amount,
      double fraction,
      ) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(amount),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            // The bar takes a value from 0 (empty) to 1 (full).
            value: fraction.clamp(0.0, 1.0).toDouble(),
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}
