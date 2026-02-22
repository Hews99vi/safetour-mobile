import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SosPhase {
  idle,
  holding,
  cancelled,
  triggered,
}

class SosState {
  const SosState({
    this.phase = SosPhase.idle,
    this.progress = 0,
  });

  final SosPhase phase;
  final double progress;

  SosState copyWith({
    SosPhase? phase,
    double? progress,
  }) {
    return SosState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
    );
  }
}

class SosController extends Notifier<SosState> {
  Timer? _timer;
  static const Duration _holdDuration = Duration(seconds: 3);
  static const Duration _tick = Duration(milliseconds: 50);
  int _elapsedMs = 0;

  @override
  SosState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const SosState();
  }

  void startHold() {
    if (state.phase == SosPhase.holding || state.phase == SosPhase.triggered) {
      return;
    }
    _elapsedMs = 0;
    state = state.copyWith(phase: SosPhase.holding, progress: 0);
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (timer) {
      _elapsedMs += _tick.inMilliseconds;
      final progress =
          (_elapsedMs / _holdDuration.inMilliseconds).clamp(0, 1).toDouble();
      if (progress >= 1) {
        timer.cancel();
        state = state.copyWith(phase: SosPhase.triggered, progress: 1);
      } else {
        state = state.copyWith(progress: progress);
      }
    });
  }

  void cancelHold() {
    if (state.phase != SosPhase.holding) return;
    _timer?.cancel();
    state = state.copyWith(phase: SosPhase.cancelled, progress: 0);
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(phase: SosPhase.idle, progress: 0);
  }
}

final sosStateProvider =
    NotifierProvider<SosController, SosState>(SosController.new);
