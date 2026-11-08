// Shared assignment data used by the dashboard and assignment dialog.


class Assignment {
  final String title;
  final String course;
  final DateTime dueDate;
  final String description;
  final String priority;
  bool isCompleted;

  Assignment({
    required this.title,
    required this.course,
    required this.dueDate,
    this.isCompleted = false,
    this.description = '',
    this.priority = 'Medium',
  });
}
