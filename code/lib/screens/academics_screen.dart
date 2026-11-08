// Display shared data. All mutations go through MainScreen callbacks.
import 'package:flutter/material.dart';
import '../models/assignment.dart';

class AcademicsScreen extends StatefulWidget {
  const AcademicsScreen({super.key, required this.courses, required this.assignments,
    required this.onAddCourse, required this.onAddAssignment, required this.onEdit,
    required this.onDelete, required this.onToggle});
  final List<String> courses;
  final List<Assignment> assignments;
  final VoidCallback onAddCourse;
  final VoidCallback onAddAssignment;
  final ValueChanged<Assignment> onEdit;
  final ValueChanged<Assignment> onDelete;
  final ValueChanged<Assignment> onToggle;

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> {
  String? _course;
  bool _showCompleted = true;

  @override
  Widget build(BuildContext context) {
    final List<Assignment> visible = widget.assignments.where((Assignment item) =>
      (_course == null || item.course == _course) && (_showCompleted || !item.isCompleted)
    ).toList()..sort((Assignment a, Assignment b) => a.dueDate.compareTo(b.dueDate));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Courses & assignments', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 8, children: [
        OutlinedButton.icon(onPressed: widget.onAddCourse, icon: const Icon(Icons.add), label: const Text('Add Course')),
        FilledButton.icon(onPressed: widget.onAddAssignment, icon: const Icon(Icons.add_task), label: const Text('Add Assignment')),
      ]),
      const SizedBox(height: 16),
      Text('Courses (${widget.courses.length})', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      // ChoiceChip filtering keeps the same data and simply changes what is shown.
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChoiceChip(label: const Text('All courses'), selected: _course == null,
          onSelected: (_) => setState(() { _course = null; })),
        for (final String course in widget.courses)
          ChoiceChip(label: Text(course), selected: _course == course,
            onSelected: (bool selected) => setState(() { _course = selected ? course : null; })),
      ]),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Show completed assignments'),
        value: _showCompleted, onChanged: (bool value) => setState(() { _showCompleted = value; })),
      Text('Assignments (${visible.length})', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (visible.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No assignments match this view.')),
      for (final Assignment item in visible)
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            CheckboxListTile(contentPadding: EdgeInsets.zero,
              value: item.isCompleted, onChanged: (_) => widget.onToggle(item),
              title: Text(item.title, style: TextStyle(decoration: item.isCompleted ? TextDecoration.lineThrough : null)),
              subtitle: Text(item.course)),
            Text('Due: ${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year} at ${TimeOfDay.fromDateTime(item.dueDate).format(context)}'),
            Text('Priority: ${item.priority}'),
            if (item.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(item.description)),
            Wrap(spacing: 8, children: [
              TextButton.icon(onPressed: () => widget.onEdit(item), icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
              TextButton.icon(onPressed: () => widget.onDelete(item), icon: const Icon(Icons.delete_outline), label: const Text('Delete')),
            ]),
          ]))),
    ]);
  }
}
