import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Alert {
  const Alert({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    required this.severity,
    required this.source,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String severity;
  final String source;
  final bool isActive;
  final DateTime createdAt;

  factory Alert.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final coordinates = location is Map ? location['coordinates'] : null;
    final lng = coordinates is List && coordinates.isNotEmpty
        ? (coordinates[0] as num?)?.toDouble() ?? 0
        : 0.0;
    final lat = coordinates is List && coordinates.length > 1
        ? (coordinates[1] as num?)?.toDouble() ?? 0
        : 0.0;

    return Alert(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? 'unsafe_area').toString(),
      title: (json['title'] ?? 'Safety alert').toString(),
      description: (json['description'] ?? '').toString(),
      lat: lat,
      lng: lng,
      severity: (json['severity'] ?? 'low').toString(),
      source: (json['source'] ?? 'official').toString(),
      isActive: json['isActive'] != false,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
    );
  }

  Color get severityColor {
    switch (severity) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFFBBF24);
      case 'low':
      default:
        return const Color(0xFF84CC16);
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'crime':
        return Icons.shield_outlined;
      case 'accident':
        return Icons.car_crash_outlined;
      case 'weather':
        return Icons.cloud_outlined;
      case 'scam':
        return Icons.warning_amber_rounded;
      case 'unsafe_area':
      default:
        return Icons.location_on_outlined;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'crime':
        return 'Crime';
      case 'accident':
        return 'Accident';
      case 'weather':
        return 'Weather';
      case 'scam':
        return 'Scam';
      case 'unsafe_area':
        return 'Unsafe area';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    return '${difference.inDays} d ago';
  }

  String distanceLabelFrom(double userLat, double userLng) {
    final meters = const Distance().as(
      LengthUnit.Meter,
      LatLng(userLat, userLng),
      LatLng(lat, lng),
    );

    if (meters < 1000) return '${meters.round()} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }
}
