// Stores the details of one saved study session.
class StudySession {
  const StudySession({
    required this.course,
    required this.seconds,
    required this.completedAt,
  });

  final String course;

  // Store seconds so short sessions still count.
  final int seconds;

  // The completion date determines where the session appears in Insights.
  final DateTime completedAt;

  // Convert the session into values that can be saved as JSON.
  Map<String, dynamic> toJson() {
    return {
      'course': course,
      'seconds': seconds,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  // Restore the session, keeping its original duration and completion date.
  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      course: json['course'] as String,
      seconds: json['seconds'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}
