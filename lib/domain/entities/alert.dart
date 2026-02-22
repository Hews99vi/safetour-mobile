class Alert {
  const Alert({
    required this.id,
    required this.title,
    required this.severity,
    required this.location,
    required this.timestamp,
  });

  final String id;
  final String title;
  final String severity;
  final String location;
  final DateTime timestamp;
}
