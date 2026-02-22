import '../../domain/entities/alert.dart';

class AlertModel extends Alert {
  const AlertModel({
    required super.id,
    required super.title,
    required super.severity,
    required super.location,
    required super.timestamp,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      title: json['title'] as String,
      severity: json['severity'] as String,
      location: json['location'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
