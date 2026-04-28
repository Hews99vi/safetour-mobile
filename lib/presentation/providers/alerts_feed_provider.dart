import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/alert.dart';
import 'safe_tour_providers.dart';
import 'safety_providers.dart';

class AlertTypeFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? value) {
    state = value;
  }
}

final alertTypeFilterProvider =
    NotifierProvider<AlertTypeFilterNotifier, String?>(
      AlertTypeFilterNotifier.new,
    );

final alertsProvider = FutureProvider.autoDispose<List<Alert>>((ref) async {
  final timer = Timer(const Duration(seconds: 60), ref.invalidateSelf);
  ref.onDispose(timer.cancel);

  final location = ref.watch(locationProvider).value;
  if (location == null) {
    return const [];
  }

  final filter = ref.watch(alertTypeFilterProvider);
  final api = ref.watch(safetyApiProvider);

  return api.fetchRecentAlerts(
    lat: location.latitude,
    lng: location.longitude,
    type: filter,
  );
});

final filteredAlertsProvider = Provider.autoDispose<AsyncValue<List<Alert>>>((
  ref,
) {
  final filter = ref.watch(alertTypeFilterProvider);

  return ref.watch(alertsProvider).whenData((alerts) {
    if (filter == null) return alerts;
    return alerts.where((alert) => alert.type == filter).toList();
  });
});
