// Stores the details of one saved study session.
class StudySession {
  const StudySession({
    required this.course,
    required this.seconds,
    required this.completedAt,
  });

  final String course;

  // Store time in seconds so short sessions still count.
  final int seconds;

  // Insights uses this date to decide which day the session counts toward.
  final DateTime completedAt;
}