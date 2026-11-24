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

  // Changes when the user checks or unchecks the assignment.
  bool isCompleted;

  // Convert the assignment into values that can be saved as JSON.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'course': course,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'description': description,
      'priority': priority,
    };
  }

  // Rebuild an assignment from its saved JSON data.
  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      title: json['title'] as String,
      course: json['course'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String? ?? 'Medium',
    );
  }
}
