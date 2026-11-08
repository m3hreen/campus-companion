// One validated form handles creation and editing. Cancel never changes data.
import 'package:flutter/material.dart';
import '../models/assignment.dart';

class AddAssignmentDialog extends StatefulWidget {
  const AddAssignmentDialog({super.key, required this.courses, this.assignment});
  final List<String> courses;
  final Assignment? assignment;

  @override
  State<AddAssignmentDialog> createState() => _AddAssignmentDialogState();
}

class _AddAssignmentDialogState extends State<AddAssignmentDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _deadline;
  String? _course;
  late String _priority;

  @override
  void initState() {
    super.initState();
    final Assignment? existing = widget.assignment;
    _title = TextEditingController(text: existing?.title ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _deadline = existing?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _course = existing?.course;
    _priority = existing?.priority ?? 'Medium';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    // Include old deadlines so editing an overdue assignment is supported.
    final DateTime now = DateTime.now();
    final DateTime earliest = _deadline.isBefore(now) ? _deadline : now;
    final DateTime latest = _deadline.isAfter(now.add(const Duration(days: 1825)))
        ? _deadline : now.add(const Duration(days: 1825));
    final DateTime? date = await showDatePicker(
      context: context, initialDate: _deadline,
      firstDate: DateTime(earliest.year, earliest.month, earliest.day),
      lastDate: latest,
    );
    if (!mounted || date == null) return;
    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, _deadline.hour, _deadline.minute);
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (!mounted || time == null) return;
    setState(() {
      _deadline = DateTime(_deadline.year, _deadline.month, _deadline.day, time.hour, time.minute);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, Assignment(
      title: _title.text.trim(), course: _course!, dueDate: _deadline,
      description: _description.text.trim(), priority: _priority,
      isCompleted: widget.assignment?.isCompleted ?? false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.assignment == null ? 'Add Assignment' : 'Edit Assignment'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _title, maxLength: 100,
                decoration: const InputDecoration(labelText: 'Assignment title'),
                validator: (String? value) => (value ?? '').trim().isEmpty ? 'Enter an assignment title' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _course, isExpanded: true,
                decoration: const InputDecoration(labelText: 'Course'),
                items: widget.courses.map((String course) => DropdownMenuItem(
                  value: course, child: Text(course, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (String? value) => setState(() { _course = value; }),
                validator: (String? value) => value == null ? 'Choose a course' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['Low', 'Medium', 'High'].map((String value) => DropdownMenuItem(
                  value: value, child: Text(value),
                )).toList(),
                onChanged: (String? value) => setState(() { _priority = value ?? 'Medium'; }),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _description, maxLines: 3, maxLength: 500,
                decoration: const InputDecoration(labelText: 'Description (optional)')),
              TextButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_today),
                label: Text('Due: ${_deadline.day}/${_deadline.month}/${_deadline.year}')),
              TextButton.icon(onPressed: _pickTime, icon: const Icon(Icons.access_time),
                label: Text(TimeOfDay.fromDateTime(_deadline).format(context))),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
