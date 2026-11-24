// Stores one assignment and converts it to/from saved JSON.
class Assignment {
  Assignment({
    int? id,
    required this.title,
    required this.course,
    required this.dueDate,
    this.isCompleted = false,
    this.description = '',
    this.priority = 'Medium',
  }) : id = id ?? _nextId++ {
    // New assignments must not reuse an ID restored from storage.
    if (this.id >= _nextId) {
      _nextId = this.id + 1;
    }
  }

  // Start within Android's notification ID range.
  // The counter distinguishes assignments created close together.
  static int _nextId = DateTime.now().millisecondsSinceEpoch % 1000000000;

  // The same ID will identify the assignment and its notification.
  final int id;

  final String title;
  final String course;
  final DateTime dueDate;
  final String description;
  final String priority;

  // Changes when the user checks or unchecks the assignment.
  bool isCompleted;

  // Include the ID so it remains the same after restarting the app.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'course': course,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'description': description,
      'priority': priority,
    };
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      // Older saved assignments have no ID yet.
      // Passing null generates one without losing the assignment.
      id: json['id'] as int?,
      title: json['title'] as String,
      course: json['course'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String? ?? 'Medium',
    );
  }
}
