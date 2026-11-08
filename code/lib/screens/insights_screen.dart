// Derive insights from shared data instead of storing a second set of totals.
import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../models/study_session.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.assignments, required this.sessions});
  final List<Assignment> assignments;
  final List<StudySession> sessions;

  String _duration(int seconds) => '${seconds ~/ 60} min ${seconds % 60} sec';

  Widget _heading(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );

  // A labelled horizontal bar stays readable on narrow screens and in both themes.
  Widget _bar(BuildContext context, String label, String amount, double fraction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(amount),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: fraction.clamp(0.0, 1.0).toDouble(), minHeight: 10,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime weekStart = DateTime(today.year, today.month, today.day - 6);
    final DateTime tomorrow = DateTime(today.year, today.month, today.day + 1);
    final List<StudySession> recent = sessions.where((StudySession session) =>
      !session.completedAt.isBefore(weekStart) && session.completedAt.isBefore(tomorrow)
    ).toList();
    final int totalSeconds = sessions.fold<int>(0, (int sum, StudySession session) => sum + session.seconds);
    final int weekSeconds = recent.fold<int>(0, (int sum, StudySession session) => sum + session.seconds);
    final int completed = assignments.where((Assignment item) => item.isCompleted).length;
    final int overdue = assignments.where((Assignment item) => !item.isCompleted && item.dueDate.isBefore(now)).length;
    final double completion = assignments.isEmpty ? 0 : completed / assignments.length;

    // Group the saved sessions by course using the Map pattern from the Dart labs.
    final Map<String, int> byCourse = {};
    for (final StudySession session in sessions) {
      byCourse[session.course] = (byCourse[session.course] ?? 0) + session.seconds;
    }
    final List<MapEntry<String, int>> courseTotals = byCourse.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));
    const List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<DateTime> dates = List<DateTime>.generate(7,
      (int index) => DateTime(today.year, today.month, today.day - 6 + index));
    final List<int> dailySeconds = dates.map((DateTime date) => recent.where((StudySession session) =>
      session.completedAt.year == date.year && session.completedAt.month == date.month && session.completedAt.day == date.day
    ).fold<int>(0, (int sum, StudySession session) => sum + session.seconds)).toList();
    final int largestDay = dailySeconds.fold<int>(0, (int largest, int seconds) => seconds > largest ? seconds : largest);

    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Your progress', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text('Calculated from your current assignments and saved study sessions.'),
      const SizedBox(height: 16),
      Card(child: Column(children: [
        ListTile(leading: const Icon(Icons.timer_outlined), title: const Text('Total study time'), subtitle: Text(_duration(totalSeconds))),
        ListTile(leading: const Icon(Icons.date_range), title: const Text('Last 7 days'), subtitle: Text(_duration(weekSeconds))),
        ListTile(leading: const Icon(Icons.history), title: const Text('Saved sessions'), subtitle: Text('${sessions.length}')),
      ])),
      _heading(context, 'Assignment completion'),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (assignments.isEmpty) const Text('No assignments yet. Add one in Academics.')
          else _bar(context, '$completed of ${assignments.length} completed', '${(completion * 100).round()}%', completion),
          Text('${assignments.length - completed} remaining • $overdue overdue'),
        ]))),
      _heading(context, 'Study time by course'),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (courseTotals.isEmpty) const Text('Save a study session to see your course breakdown.'),
          for (final MapEntry<String, int> entry in courseTotals)
            _bar(context, entry.key, '${_duration(entry.value)} • ${(totalSeconds == 0 ? 0 : entry.value / totalSeconds * 100).round()}%',
              totalSeconds == 0 ? 0 : entry.value / totalSeconds),
        ]))),
      _heading(context, 'Daily study activity'),
      const Text('Last 7 days. Bar lengths are relative to your busiest day.'),
      const SizedBox(height: 8),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (weekSeconds == 0) const Text('No saved study time in the last 7 days.'),
          for (int index = 0; index < dates.length; index++)
            _bar(context, '${weekdays[dates[index].weekday - 1]} ${dates[index].day}/${dates[index].month}',
              _duration(dailySeconds[index]), largestDay == 0 ? 0 : dailySeconds[index] / largestDay),
        ]))),
      const SizedBox(height: 16),
      const Text('Only saved sessions count. Study time is assigned to the session’s completion date. Data currently resets when the app restarts.'),
    ]);
  }
}
