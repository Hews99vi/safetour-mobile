import 'package:flutter/material.dart';

enum RiskLevel {
  low,
  medium,
  high,
  critical,
  unknown;

  static RiskLevel fromJson(String? value) {
    switch (value) {
      case 'low':
        return RiskLevel.low;
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      case 'critical':
        return RiskLevel.critical;
      default:
        return RiskLevel.unknown;
    }
  }
}

class RiskScore {
  const RiskScore({
    required this.score,
    required this.level,
    required this.factors,
    required this.timestamp,
  });

  final int score;
  final RiskLevel level;
  final List<String> factors;
  final DateTime timestamp;

  factory RiskScore.fromJson(Map<String, dynamic> json) {
    return RiskScore(
      score: ((json['score'] as num?)?.round() ?? 0).clamp(0, 100),
      level: RiskLevel.fromJson(json['level'] as String?),
      factors:
          (json['factors'] as List?)
              ?.map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList() ??
          const [],
      timestamp:
          DateTime.tryParse((json['timestamp'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
    );
  }

  Color get levelColor {
    switch (level) {
      case RiskLevel.low:
        return const Color(0xFF84CC16);
      case RiskLevel.medium:
        return const Color(0xFFFBBF24);
      case RiskLevel.high:
        return const Color(0xFFF97316);
      case RiskLevel.critical:
        return const Color(0xFFEF4444);
      case RiskLevel.unknown:
        return const Color(0xFF94A3B8);
    }
  }

  String get levelLabel {
    switch (level) {
      case RiskLevel.low:
        return 'Safe';
      case RiskLevel.medium:
        return 'Caution';
      case RiskLevel.high:
        return 'Danger';
      case RiskLevel.critical:
        return 'Critical';
      case RiskLevel.unknown:
        return 'Unknown';
    }
  }
}
