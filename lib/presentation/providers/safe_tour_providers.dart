import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/risk_score.dart';
import '../../services/location_service.dart';
import 'safety_providers.dart';

RiskScore? _lastKnownRiskScore;

final riskScoreProvider = FutureProvider.autoDispose<RiskScore?>((ref) async {
  final timer = Timer(const Duration(seconds: 90), ref.invalidateSelf);
  ref.onDispose(timer.cancel);

  final position = ref.watch(locationProvider).value;
  if (position == null) {
    return _lastKnownRiskScore;
  }

  try {
    final score = await ref
        .watch(safetyApiProvider)
        .fetchRiskScore(lat: position.latitude, lng: position.longitude);
    _lastKnownRiskScore = score;
    return score;
  } catch (_) {
    return _lastKnownRiskScore;
  }
});

class VpnStatus {
  const VpnStatus({required this.isOn});

  final bool isOn;
}

class VpnStatusNotifier extends Notifier<VpnStatus> {
  @override
  VpnStatus build() {
    return const VpnStatus(isOn: true);
  }

  void toggle() {
    state = VpnStatus(isOn: !state.isOn);
  }
}

final vpnProvider = NotifierProvider<VpnStatusNotifier, VpnStatus>(
  VpnStatusNotifier.new,
);

class ConnectivityStatus {
  const ConnectivityStatus({required this.isOnline});

  final bool isOnline;
}

class ConnectivityNotifier extends Notifier<ConnectivityStatus> {
  @override
  ConnectivityStatus build() {
    return const ConnectivityStatus(isOnline: true);
  }

  void toggle() {
    state = ConnectivityStatus(isOnline: !state.isOnline);
  }
}

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityStatus>(
      ConnectivityNotifier.new,
    );

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationNotifier extends Notifier<AsyncValue<Position?>> {
  StreamSubscription<Position>? _positionSub;

  @override
  AsyncValue<Position?> build() {
    ref.onDispose(() {
      _positionSub?.cancel();
    });
    Future<void>.microtask(_start);
    return const AsyncValue.loading();
  }

  Future<void> refresh() async {
    await _start();
  }

  Future<void> _start() async {
    await _positionSub?.cancel();
    state = const AsyncValue.loading();
    final service = ref.read(locationServiceProvider);

    try {
      final hasPermission = await service.requestPermission();
      if (!hasPermission) {
        state = const AsyncValue.data(null);
        return;
      }

      final currentPosition = await service.getCurrentPosition();
      state = AsyncValue.data(currentPosition);

      _positionSub = service.watchPosition().listen(
        (position) {
          state = AsyncValue.data(position);
        },
        onError: (Object error, StackTrace stackTrace) {
          state = AsyncValue.error(error, stackTrace);
        },
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final locationProvider =
    NotifierProvider<LocationNotifier, AsyncValue<Position?>>(
      LocationNotifier.new,
    );
