import 'package:flutter/material.dart';

import '../models/assignment.dart';

// Use the same form to add a new assignment or edit an existing one.
class AddAssignmentDialog extends StatefulWidget {
  const AddAssignmentDialog({
    super.key,
    required this.courses,
    this.assignment,
  });

  final List<String> courses;
  final Assignment? assignment;

  @override
  State<AddAssignmentDialog> createState() => _AddAssignmentDialogState();
}

class _AddAssignmentDialogState extends State<AddAssignmentDialog> {
  static const List<String> _priorities = ['Low', 'Medium', 'High'];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _deadline;
  String? _course;
  late String _priority;

  @override
  void initState() {
    super.initState();

    // Fill in the old values when editing. Use defaults for a new assignment.
    final Assignment? existing = widget.assignment;
    _title = TextEditingController(text: existing?.title ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _deadline =
        existing?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _course = existing?.course;
    _priority = existing?.priority ?? 'Medium';
  }

  @override
  void dispose() {
    // Release the text controllers when the dialog closes.
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime defaultLastDate = now.add(const Duration(days: 1825));

    // Keep the current deadline available, even if it's outside the usual range.
    final DateTime earliest = _deadline.isBefore(now) ? _deadline : now;
    final DateTime latest =
    _deadline.isAfter(defaultLastDate) ? _deadline : defaultLastDate;

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(earliest.year, earliest.month, earliest.day),
      lastDate: latest,
    );

    if (!mounted || date == null) return;

    // Change the day and keep the time the user already chose.
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        _deadline.hour,
        _deadline.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );

    if (!mounted || time == null) return;

    // Change the time and keep the selected day.
    setState(() {
      _deadline = DateTime(
        _deadline.year,
        _deadline.month,
        _deadline.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save() {
    // The form needs both a title and a course before it can be saved.
    if (!_formKey.currentState!.validate()) return;

    final Assignment assignment = Assignment(
      title: _title.text.trim(),
      course: _course!,
      dueDate: _deadline,
      description: _description.text.trim(),
      priority: _priority,
      isCompleted: widget.assignment?.isCompleted ?? false,
    );

    // Send the finished assignment back so MainScreen can update the list.
    Navigator.pop(context, assignment);
  }

  @override
  Widget build(BuildContext context) {
    final String dateLabel =
        '${_deadline.day}/${_deadline.month}/${_deadline.year}';
    final String timeLabel = TimeOfDay.fromDateTime(_deadline).format(context);

    return AlertDialog(
      title: Text(
        widget.assignment == null ? 'Add Assignment' : 'Edit Assignment',
      ),
      content: SizedBox(
        width: 400,
        // Let the user scroll through the form on a small screen.
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Assignment title',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Enter an assignment title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _course,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Course'),
                  items: [
                    for (final String course in widget.courses)
                      DropdownMenuItem<String>(
                        value: course,
                        child: Text(course, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _course = value;
                    });
                  },
                  validator: (value) => value == null ? 'Choose a course' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: [
                    for (final String priority in _priorities)
                      DropdownMenuItem<String>(
                        value: priority,
                        child: Text(priority),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _priority = value ?? 'Medium';
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text('Due: $dateLabel'),
                ),
                TextButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(timeLabel),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Close the form without sending back an assignment.
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}