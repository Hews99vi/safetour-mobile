import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';

enum AlertType { physical, cyber, system }

enum AlertSeverity { low, medium, high }

class AlertItem {
  const AlertItem({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.timestamp,
    required this.type,
    required this.severity,
    this.isNew = false,
  });

  final String id;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final String timestamp;
  final AlertType type;
  final AlertSeverity severity;
  final bool isNew;
}

class AlertsFeedController extends Notifier<AsyncValue<List<AlertItem>>> {
  @override
  AsyncValue<List<AlertItem>> build() {
    _load();
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    state = AsyncValue.data(_mockAlerts());
  }

  Future<void> retry() async {
    state = const AsyncValue.loading();
    await _load();
  }

  List<AlertItem> _mockAlerts() {
    return const [
      AlertItem(
        id: '1',
        title: 'Crowd Surge Detected',
        shortDescription: 'High foot traffic near Market Street.',
        fullDescription:
            'Sensors detected a sharp increase in crowd density near Market Street. '
            'Consider re-routing to reduce exposure and maintain safe distances.',
        timestamp: '2 min ago',
        type: AlertType.physical,
        severity: AlertSeverity.high,
        isNew: true,
      ),
      AlertItem(
        id: '2',
        title: 'Unsecured Wi-Fi Nearby',
        shortDescription: 'Open hotspot detected in your vicinity.',
        fullDescription:
            'A public Wi-Fi hotspot without encryption is nearby. Avoid connecting '
            'or enable VPN protection before browsing.',
        timestamp: '8 min ago',
        type: AlertType.cyber,
        severity: AlertSeverity.medium,
      ),
      AlertItem(
        id: '3',
        title: 'City Service Notice',
        shortDescription: 'Transit delays expected downtown.',
        fullDescription:
            'City services report short delays due to scheduled maintenance. '
            'Plan for an extra 10 minutes of travel time.',
        timestamp: '14 min ago',
        type: AlertType.system,
        severity: AlertSeverity.low,
      ),
    ];
  }
}

final alertsProvider =
    NotifierProvider<AlertsFeedController, AsyncValue<List<AlertItem>>>(
  AlertsFeedController.new,
);

class AlertFilterController extends Notifier<AlertType?> {
  @override
  AlertType? build() => null;

  void setFilter(AlertType? value) {
    state = value;
  }
}

final alertFilterProvider =
    NotifierProvider<AlertFilterController, AlertType?>(
  AlertFilterController.new,
);

Color alertTypeColor(AlertType type) {
  switch (type) {
    case AlertType.physical:
      return AppColors.danger;
    case AlertType.cyber:
      return AppColors.neonCyan;
    case AlertType.system:
      return AppColors.mist;
  }
}

IconData alertTypeIcon(AlertType type) {
  switch (type) {
    case AlertType.physical:
      return Icons.warning_amber_rounded;
    case AlertType.cyber:
      return Icons.lock_outline;
    case AlertType.system:
      return Icons.info_outline;
  }
}

Color alertSeverityGlow(AlertSeverity severity) {
  switch (severity) {
    case AlertSeverity.low:
      return AppColors.neonLime;
    case AlertSeverity.medium:
      return const Color(0xFFFBBF24);
    case AlertSeverity.high:
      return AppColors.danger;
  }
}
