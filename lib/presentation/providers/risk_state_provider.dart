import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';

class RiskState {
  const RiskState({
    required this.label,
    required this.status,
    required this.color,
    required this.score,
    required this.explanation,
  });

  final String label;
  final String status;
  final Color color;
  final int score;
  final String explanation;
}

class RiskStateNotifier extends Notifier<RiskState> {
  int _index = 0;
  Timer? _timer;

  @override
  RiskState build() {
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _tick());
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const RiskState(
      label: 'Low',
      status: 'Clear',
      color: AppColors.neonLime,
      score: 18,
      explanation: 'Low anomaly signals detected near your route.',
    );
  }

  void _tick() {
    _index = (_index + 1) % 3;
    switch (_index) {
      case 0:
        state = const RiskState(
          label: 'Low',
          status: 'Clear',
          color: AppColors.neonLime,
          score: 22,
          explanation: 'Area shows stable traffic and verified safety.',
        );
        break;
      case 1:
        state = const RiskState(
          label: 'Medium',
          status: 'Watch',
          color: Color(0xFFFBBF24),
          score: 54,
          explanation: 'Crowd density rising. Stay alert in transit zones.',
        );
        break;
      default:
        state = const RiskState(
          label: 'High',
          status: 'Alert',
          color: AppColors.danger,
          score: 86,
          explanation: 'Multiple alerts nearby. Consider a safer corridor.',
        );
    }
  }

  Future<void> refreshFromApi() async {
    // Placeholder for AI risk API call.
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

}

final riskStateProvider =
    NotifierProvider<RiskStateNotifier, RiskState>(RiskStateNotifier.new);
