import 'dart:async';

import 'package:flutter/material.dart';

import '../models/study_session.dart';
import '../utils/app_feedback.dart';
import '../widgets/daily_goal_card.dart';

// Lets the user time a study session, save it, and change their daily goal.
class StudyScreen extends StatefulWidget {
  const StudyScreen({
    super.key,
    required this.courses,
    required this.sessions,
    required this.goalMinutes,
    required this.studiedSeconds,
    required this.onSaveSession,
    required this.onGoalChanged,
  });

  final List<String> courses;
  final List<StudySession> sessions;
  final int goalMinutes;
  final int studiedSeconds;

  // MainScreen uses these functions to update the shared information.
  final ValueChanged<StudySession> onSaveSession;
  final ValueChanged<int> onGoalChanged;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  static const List<int> _sessionLengths = [1, 5, 15, 25, 45, 60];

  // The stopwatch measures time. The timer refreshes the number on screen.
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;

  String? _course;
  int _minutes = 25;
  bool _finished = false;
  bool _stopwatchMode = false;

  int get _elapsed => _watch.elapsed.inSeconds;

  int get _remaining {
    final int targetSeconds = _minutes * 60;
    return (targetSeconds - _elapsed).clamp(0, targetSeconds).toInt();
  }

  // A paused session still counts as started, even before one second passes.
  bool get _hasSession =>
      _watch.isRunning || _watch.elapsedMicroseconds > 0;

  String get _displayTime {
    final int seconds = _stopwatchMode ? _elapsed : _remaining;
    final String minutesText = (seconds ~/ 60).toString().padLeft(2, '0');
    final String secondsText = (seconds % 60).toString().padLeft(2, '0');
    return '$minutesText:$secondsText';
  }

  String get _statusText {
    if (_finished) return 'Complete — save your session';
    if (_watch.isRunning) {
      return _stopwatchMode ? 'Stopwatch running' : 'Studying';
    }
    return _hasSession ? 'Paused' : 'Ready to study';
  }

  void _start() {
    if (_course == null) {
      showAppFeedback(context, 'Choose a course first');
      return;
    }
    if (_finished) return;

    _watch.start();
    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;

      // Only the countdown stops when it reaches zero.
      if (!_stopwatchMode && _remaining == 0) {
        _watch.stop();
        _ticker?.cancel();
        setState(() {
          _finished = true;
        });
        showAppFeedback(context, 'Timer complete! Save your study session.');
        return;
      }

      setState(() {});
    });

    setState(() {});
  }

  void _pause() {
    // Stop counting but keep the time so the user can resume or save it.
    _watch.stop();
    _ticker?.cancel();
    setState(() {});
  }

  void _clear() {
    _ticker?.cancel();
    _watch.stop();
    _watch.reset();

    setState(() {
      _finished = false;
    });
  }

  Future<void> _reset() async {
    if (!_hasSession) return;

    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_stopwatchMode ? 'Reset stopwatch?' : 'Reset timer?'),
        content: const Text('Unsaved study time will be discarded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (!mounted || discard != true) return;

    _clear();
    showAppFeedback(context, 'Timer reset');
  }

  void _save() {
    final String? course = _course;
    final int seconds = _elapsed;
    if (course == null || seconds < 1) return;

    final StudySession session = StudySession(
      course: course,
      seconds: seconds,
      completedAt: DateTime.now(),
    );

    // Clear the timer so the same session can't be saved twice.
    _clear();
    widget.onSaveSession(session);
  }

  Future<void> _editGoal() async {
    final TextEditingController controller = TextEditingController(
      text: '${widget.goalMinutes}',
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final int? goal = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Daily study goal'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutes per day (1–1440)',
            ),
            validator: (value) {
              final int? minutes = int.tryParse((value ?? '').trim());
              if (minutes == null || minutes < 1 || minutes > 1440) {
                return 'Enter a whole number from 1 to 1440';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              final int minutes = int.parse(controller.text.trim());
              Navigator.pop(dialogContext, minutes);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // Give the dialog time to close before releasing its text controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();

    if (!mounted || goal == null) return;
    widget.onGoalChanged(goal);
  }

  @override
  void dispose() {
    // Stop the updates when Flutter removes this screen.
    _ticker?.cancel();
    _watch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DailyGoalCard(
          studiedSeconds: widget.studiedSeconds,
          goalMinutes: widget.goalMinutes,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _editGoal,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit daily goal'),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: _course,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Study course'),
          items: [
            for (final String course in widget.courses)
              DropdownMenuItem<String>(
                value: course,
                child: Text(course, overflow: TextOverflow.ellipsis),
              ),
          ],

          // Keep the chosen course fixed until the session is saved or reset.
          onChanged: _hasSession
              ? null
              : (value) {
            setState(() {
              _course = value;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildModePicker(),
        const SizedBox(height: 16),
        if (!_stopwatchMode) _buildLengthPicker(),
        const SizedBox(height: 24),
        Center(
          child: Text(
            _displayTime,
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
        Center(child: Text(_statusText)),
        const SizedBox(height: 16),
        _buildTimerButtons(),
        const SizedBox(height: 12),
        const Text(
          'Save records elapsed time, including partial sessions. '
              'Switching tabs keeps the timer running. '
              'Sessions and goals reset when the app restarts.',
        ),
        const SizedBox(height: 24),
        Text(
          'Session history',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (widget.sessions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No saved sessions yet.'),
          ),

        // The most recently saved session appears first.
        for (final StudySession session in widget.sessions.reversed)
          _buildSessionCard(session),
      ],
    );
  }

  Widget _buildModePicker() {
    return SegmentedButton<bool>(
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
          : (selection) {
        setState(() {
          _stopwatchMode = selection.first;
          _finished = false;
        });
      },
    );
  }

  Widget _buildLengthPicker() {
    return DropdownButtonFormField<int>(
      initialValue: _minutes,
      decoration: const InputDecoration(labelText: 'Session length'),
      items: [
        for (final int minutes in _sessionLengths)
          DropdownMenuItem<int>(
            value: minutes,
            child: Text('$minutes minutes'),
          ),
      ],
      onChanged: _hasSession
          ? null
          : (value) {
        setState(() {
          _minutes = value ?? 25;
        });
      },
    );
  }

  Widget _buildTimerButtons() {
    final bool isRunning = _watch.isRunning;
    final String startLabel = isRunning ? 'Pause' : (_hasSession ? 'Resume' : 'Start');

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: _finished ? null : (isRunning ? _pause : _start),
          icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
          label: Text(startLabel),
        ),
        OutlinedButton(
          onPressed: _elapsed > 0 ? _save : null,
          child: const Text('Save session'),
        ),
        TextButton(
          onPressed: _hasSession ? _reset : null,
          child: const Text('Reset'),
        ),
      ],
    );
  }

  Widget _buildSessionCard(StudySession session) {
    final DateTime date = session.completedAt;
    final int minutes = session.seconds ~/ 60;
    final int seconds = session.seconds % 60;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(session.course),
        subtitle: Text(
          '${date.day}/${date.month}/${date.year} • $minutes min $seconds sec',
        ),
      ),
    );
  }
}