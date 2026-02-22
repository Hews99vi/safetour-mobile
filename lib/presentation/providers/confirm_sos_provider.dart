import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SosConfirmPhase {
  idle,
  holding,
  confirmed,
  failed,
  cancelled,
}

class SosConfirmState {
  const SosConfirmState({
    this.phase = SosConfirmPhase.idle,
    this.progress = 0,
  });

  final SosConfirmPhase phase;
  final double progress;

  SosConfirmState copyWith({
    SosConfirmPhase? phase,
    double? progress,
  }) {
    return SosConfirmState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
    );
  }
}

class SosConfirmController extends Notifier<SosConfirmState> {
  @override
  SosConfirmState build() => const SosConfirmState();

  void startHold() {
    state = state.copyWith(phase: SosConfirmPhase.holding, progress: 0);
  }

  void updateProgress(double value) {
    state = state.copyWith(progress: value);
  }

  void confirm() {
    state = state.copyWith(phase: SosConfirmPhase.confirmed, progress: 1);
  }

  void fail() {
    state = state.copyWith(phase: SosConfirmPhase.failed, progress: 1);
  }

  void cancel() {
    state = state.copyWith(phase: SosConfirmPhase.cancelled, progress: 0);
  }

  void reset() {
    state = const SosConfirmState();
  }
}

final sosProvider =
    NotifierProvider<SosConfirmController, SosConfirmState>(
  SosConfirmController.new,
);
