// A saved session stores actual elapsed seconds, including short sessions.
class StudySession {
  const StudySession({required this.course, required this.seconds, required this.completedAt});
  final String course;
  final int seconds;
  final DateTime completedAt;
}
