import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';

class RiskStatus {
  const RiskStatus({
    required this.level,
    required this.explanation,
    required this.glowColor,
    required this.updatedSeconds,
  });

  final String level;
  final String explanation;
  final Color glowColor;
  final int updatedSeconds;
}

class RiskStatusNotifier extends Notifier<RiskStatus> {
  Timer? _timer;
  int _index = 0;

  @override
  RiskStatus build() {
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _tick());
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const RiskStatus(
      level: 'Low',
      explanation: 'Calm movement patterns detected across nearby zones.',
      glowColor: AppColors.neonLime,
      updatedSeconds: 12,
    );
  }

  void _tick() {
    _index = (_index + 1) % 3;
    switch (_index) {
      case 0:
        state = const RiskStatus(
          level: 'Low',
          explanation: 'Calm movement patterns detected across nearby zones.',
          glowColor: AppColors.neonLime,
          updatedSeconds: 12,
        );
        break;
      case 1:
        state = const RiskStatus(
          level: 'Medium',
          explanation: 'Crowd density rising near central transit corridors.',
          glowColor: Color(0xFFFBBF24),
          updatedSeconds: 12,
        );
        break;
      default:
        state = const RiskStatus(
          level: 'High',
          explanation: 'Multiple alerts detected. Consider safer alternatives.',
          glowColor: AppColors.danger,
          updatedSeconds: 12,
        );
    }
  }
}

final riskProvider =
    NotifierProvider<RiskStatusNotifier, RiskStatus>(RiskStatusNotifier.new);

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

final vpnProvider =
    NotifierProvider<VpnStatusNotifier, VpnStatus>(VpnStatusNotifier.new);

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

final connectivityProvider = NotifierProvider<ConnectivityNotifier,
    ConnectivityStatus>(ConnectivityNotifier.new);

class LocationStatus {
  const LocationStatus({
    required this.location,
    required this.isLoading,
    required this.hasError,
    required this.mapFailed,
  });

  final LatLng? location;
  final bool isLoading;
  final bool hasError;
  final bool mapFailed;

  LocationStatus copyWith({
    LatLng? location,
    bool? isLoading,
    bool? hasError,
    bool? mapFailed,
  }) {
    return LocationStatus(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      mapFailed: mapFailed ?? this.mapFailed,
    );
  }

  factory LocationStatus.loading() {
    return const LocationStatus(
      location: null,
      isLoading: true,
      hasError: false,
      mapFailed: false,
    );
  }
}

class LocationStatusNotifier extends Notifier<LocationStatus> {
  Timer? _timer;

  @override
  LocationStatus build() {
    ref.onDispose(() => _timer?.cancel());
    _startMockLoad();
    return LocationStatus.loading();
  }

  void _startMockLoad() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      state = state.copyWith(
        location: const LatLng(37.7749, -122.4194),
        isLoading: false,
        hasError: false,
        mapFailed: false,
      );
    });
  }

  void retry() {
    state = state.copyWith(isLoading: true, hasError: false, mapFailed: false);
    _startMockLoad();
  }

  void simulateGpsError() {
    state = state.copyWith(isLoading: false, hasError: true);
  }

  void simulateMapFailure() {
    state = state.copyWith(isLoading: false, mapFailed: true);
  }
}

final locationProvider = NotifierProvider<LocationStatusNotifier,
    LocationStatus>(LocationStatusNotifier.new);
