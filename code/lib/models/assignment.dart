// Stores the details of one assignment.
class Assignment {
  Assignment({
    required this.title,
    required this.course,
    required this.dueDate,
    this.isCompleted = false,
    this.description = '',
    this.priority = 'Medium',
  });

  final String title;
  final String course;
  final DateTime dueDate;
  final String description;
  final String priority;

  // This can change when the user checks or unchecks the assignment.
  bool isCompleted;
}
