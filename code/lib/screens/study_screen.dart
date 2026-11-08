// Stopwatch measures elapsed time; Timer only refreshes the display.
// This avoids counting timer callbacks, which can be delayed in inactive tabs.
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/study_session.dart';
import '../widgets/daily_goal_card.dart';
import '../utils/app_feedback.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.courses, required this.sessions,
    required this.goalMinutes, required this.studiedSeconds,
    required this.onSaveSession, required this.onGoalChanged});
  final List<String> courses;
  final List<StudySession> sessions;
  final int goalMinutes;
  final int studiedSeconds;
  final ValueChanged<StudySession> onSaveSession;
  final ValueChanged<int> onGoalChanged;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  String? _course;
  int _minutes = 25;
  bool _finished = false;
  bool _stopwatchMode = false;

  // Actual elapsed time, used when saving sessions
  int get _elapsed => _watch.elapsed.inSeconds;

  int get _remaining => (_minutes * 60 - _elapsed).clamp(0, _minutes * 60).toInt();
  bool get _hasSession => _watch.isRunning || _watch.elapsedMicroseconds > 0;

  // displayed time depends on the selected mode
  int get _displaySeconds => _stopwatchMode ? _elapsed : _remaining;

  void _message(String text) {
    showAppFeedback(context, text);
  }

  void _start() {
    if (_course == null) {
      _message('Choose a course first');
      return;
    }

    if (_finished) return;
    _watch.start();
    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      if (!_stopwatchMode && _remaining == 0) {
        _watch.stop();
        _ticker?.cancel();
        _finished = true;
        _message('Timer complete! Save your study session.');
      }
      setState(() {});
    });
    setState(() {});
  }

  void _pause() {
    _watch.stop();
    _ticker?.cancel();
    setState(() {});
  }

  void _clear() {
    _ticker?.cancel();
    _watch.stop();
    _watch.reset();
    setState(() { _finished = false; });
  }

  Future<void> _reset() async {
    if (!_hasSession) return;
    final bool? discard = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(_stopwatchMode ? 'Reset stopwatch?' : 'Reset timer?',),
        content: const Text('Unsaved study time will be discarded.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Reset')),
      ]));
    if (!mounted || discard != true) return;
    _clear();
    _message('Timer reset');
  }

  void _save() {
    final int seconds = _elapsed;
    if (seconds < 1 || _course == null) return;
    final StudySession session = StudySession(course: _course!, seconds: seconds, completedAt: DateTime.now());
    _clear(); // Clear first so the same elapsed time cannot be saved twice.
    widget.onSaveSession(session);
  }

  Future<void> _editGoal() async {
    final TextEditingController controller = TextEditingController(text: '${widget.goalMinutes}');
    final GlobalKey<FormState> key = GlobalKey<FormState>();
    final int? goal = await showDialog<int>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Daily study goal'),
      content: Form(key: key, child: TextFormField(
        controller: controller, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Minutes per day (1–1440)'),
        validator: (String? value) {
          final int? number = int.tryParse((value ?? '').trim());
          return number == null || number < 1 || number > 1440 ? 'Enter a whole number from 1 to 1440' : null;
        })),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          if (!key.currentState!.validate()) return;
          Navigator.pop(dialogContext, int.parse(controller.text.trim()));
        }, child: const Text('Save')),
      ]));
    // Wait for the route to finish its exit animation before disposing its controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (!mounted || goal == null) return;
    widget.onGoalChanged(goal);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _watch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<StudySession> history = widget.sessions.reversed.toList();
    return ListView(padding: const EdgeInsets.all(20), children: [
      DailyGoalCard(studiedSeconds: widget.studiedSeconds, goalMinutes: widget.goalMinutes),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _editGoal,
        icon: const Icon(Icons.edit_outlined), label: const Text('Edit daily goal'))),
      DropdownButtonFormField<String>(initialValue: _course, isExpanded: true,
        decoration: const InputDecoration(labelText: 'Study course'),
        items: widget.courses.map((String course) => DropdownMenuItem(value: course,
          child: Text(course, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: _hasSession ? null : (String? value) => setState(() { _course = value; })),
      const SizedBox(height: 16),
      // Choose between Timer and Stopwatch
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment<bool>(
            value: false,
            label: Text('Timer'),
            icon: Icon(Icons.timer_outlined),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text('Stopwatch'),
            icon: Icon(Icons.timer),
          ),
        ],
        selected: {_stopwatchMode},
        onSelectionChanged: _hasSession
            ? null
            : (Set<bool> selection) {
          setState(() {
            _stopwatchMode = selection.first;
            _finished = false;
          });
        },
      ),
      const SizedBox(height: 16),

      if (!_stopwatchMode) ...[
        DropdownButtonFormField<int>(
          initialValue: _minutes,
          decoration: const InputDecoration(labelText: 'Session length',),
          items: [1, 5, 15, 25, 45, 60].map((int minutes) => DropdownMenuItem(
            value: minutes,
            child: Text('$minutes minutes'),
          )).toList(),
          onChanged: _hasSession ? null : (int? value) {
            setState(() {
              _minutes = value ?? 25;
            });
          },
        ),
        const SizedBox(height: 24),
      ] else
        const SizedBox(height: 24),
      Center(
        child: Text(
          '${(_displaySeconds ~/ 60).toString().padLeft(2, '0')}:${(_displaySeconds % 60).toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
      Center(
        child: Text(
          _finished
              ? 'Complete — save your session'
              : _watch.isRunning
              ? (_stopwatchMode ? 'Stopwatch running' : 'Studying')
              : _hasSession
              ? 'Paused'
              : 'Ready to study',
        ),
      ),
      const SizedBox(height: 16),
      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
        FilledButton.icon(onPressed: _finished ? null : _watch.isRunning ? _pause : _start,
          icon: Icon(_watch.isRunning ? Icons.pause : Icons.play_arrow),
          label: Text(_watch.isRunning ? 'Pause' : _hasSession ? 'Resume' : 'Start')),
        OutlinedButton(onPressed: _elapsed > 0 ? _save : null, child: const Text('Save session')),
        TextButton(onPressed: _hasSession ? _reset : null, child: const Text('Reset')),
      ]),
      const SizedBox(height: 12),
      const Text('Save records elapsed time, including partial sessions. Switching tabs keeps the timer running. Sessions and goals reset when the app restarts.'),
      const SizedBox(height: 24),
      Text('Session history', style: Theme.of(context).textTheme.titleLarge),
      if (history.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('No saved sessions yet.')),
      for (final StudySession session in history)
        Card(child: ListTile(leading: const Icon(Icons.history), title: Text(session.course),
          subtitle: Text('${session.completedAt.day}/${session.completedAt.month}/${session.completedAt.year} • ${session.seconds ~/ 60} min ${session.seconds % 60} sec'))),
    ]);
  }
}
