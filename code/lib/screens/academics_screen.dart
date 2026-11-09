import 'package:flutter/material.dart';

import '../models/assignment.dart';

// Shows the courses and assignments that MainScreen passes in.
class AcademicsScreen extends StatefulWidget {
  const AcademicsScreen({
    super.key,
    required this.courses,
    required this.assignments,
    required this.onAddCourse,
    required this.onAddAssignment,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final List<String> courses;
  final List<Assignment> assignments;

  // These functions let this screen ask MainScreen to change the shared list.
  final VoidCallback onAddCourse;
  final VoidCallback onAddAssignment;
  final ValueChanged<Assignment> onEdit;
  final ValueChanged<Assignment> onDelete;
  final ValueChanged<Assignment> onToggle;

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> {
  // A null course means "All courses" is selected.
  String? _selectedCourse;
  bool _showCompleted = true;

  List<Assignment> _getVisibleAssignments() {
    // Make a separate list so filtering and sorting only affect this screen.
    final List<Assignment> visible = widget.assignments.where((assignment) {
      final bool matchesCourse =
          _selectedCourse == null || assignment.course == _selectedCourse;
      final bool matchesCompletion =
          _showCompleted || !assignment.isCompleted;

      return matchesCourse && matchesCompletion;
    }).toList();

    // Show the assignments with the earliest due dates first.
    visible.sort((first, second) => first.dueDate.compareTo(second.dueDate));
    return visible;
  }

  void _selectCourse(String? course) {
    setState(() {
      _selectedCourse = course;
    });
  }

  Widget _buildAssignmentCard(BuildContext context, Assignment assignment) {
    final DateTime dueDate = assignment.dueDate;
    final String date = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    final String time = TimeOfDay.fromDateTime(dueDate).format(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: assignment.isCompleted,
              onChanged: (_) => widget.onToggle(assignment),
              title: Text(
                assignment.title,
                style: TextStyle(
                  decoration: assignment.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text(assignment.course),
            ),
            Text('Due: $date at $time'),
            Text('Priority: ${assignment.priority}'),
            if (assignment.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(assignment.description),
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => widget.onEdit(assignment),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => widget.onDelete(assignment),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Assignment> visible = _getVisibleAssignments();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Courses & assignments', style: textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: widget.onAddCourse,
              icon: const Icon(Icons.add),
              label: const Text('Add Course'),
            ),
            FilledButton.icon(
              onPressed: widget.onAddAssignment,
              icon: const Icon(Icons.add_task),
              label: const Text('Add Assignment'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Courses (${widget.courses.length})', style: textTheme.titleMedium),
        const SizedBox(height: 8),

        // Tapping a course shows its assignments. Tapping it again shows all.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All courses'),
              selected: _selectedCourse == null,
              onSelected: (_) => _selectCourse(null),
            ),
            for (final String course in widget.courses)
              ChoiceChip(
                label: Text(course),
                selected: _selectedCourse == course,
                onSelected: (bool selected) {
                  _selectCourse(selected ? course : null);
                },
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show completed assignments'),
          value: _showCompleted,
          onChanged: (bool value) {
            setState(() {
              _showCompleted = value;
            });
          },
        ),
        Text('Assignments (${visible.length})', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No assignments match this view.'),
          ),
        for (final Assignment assignment in visible)
          _buildAssignmentCard(context, assignment),
      ],
    );
  }
}
