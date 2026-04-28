import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'safety_providers.dart';

enum SosSubmitPhase { idle, holding, submitting, active, cancelled, error }

class SosSubmitState {
  const SosSubmitState({
    this.phase = SosSubmitPhase.idle,
    this.progress = 0,
    this.sosId,
    this.message,
    this.errorMessage,
  });

  final SosSubmitPhase phase;
  final double progress;
  final String? sosId;
  final String? message;
  final String? errorMessage;

  SosSubmitState copyWith({
    SosSubmitPhase? phase,
    double? progress,
    String? sosId,
    String? message,
    String? errorMessage,
    bool clearSosId = false,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return SosSubmitState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      sosId: clearSosId ? null : sosId ?? this.sosId,
      message: clearMessage ? null : message ?? this.message,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class SosSubmitNotifier extends Notifier<SosSubmitState> {
  @override
  SosSubmitState build() => const SosSubmitState();

  void startHold() {
    state = state.copyWith(
      phase: SosSubmitPhase.holding,
      progress: 0,
      clearError: true,
    );
  }

  void updateProgress(double value) {
    state = state.copyWith(progress: value);
  }

  void cancelHold() {
    state = state.copyWith(phase: SosSubmitPhase.cancelled, progress: 0);
  }

  Future<void> triggerSos(
    double lat,
    double lng, [
    String emergencyType = 'other',
    String? description,
  ]) async {
    state = state.copyWith(
      phase: SosSubmitPhase.submitting,
      progress: 1,
      clearError: true,
    );

    try {
      final response = await ref
          .read(safetyApiProvider)
          .submitSos(
            lat: lat,
            lng: lng,
            emergencyType: emergencyType,
            description: description,
          );
      state = state.copyWith(
        phase: SosSubmitPhase.active,
        sosId: response.sosId,
        message: response.message,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        phase: SosSubmitPhase.error,
        errorMessage: 'Unable to send SOS. Please try again.',
      );
    }
  }

  Future<void> cancelSos() async {
    final sosId = state.sosId;
    if (sosId == null || sosId.isEmpty) {
      state = state.copyWith(phase: SosSubmitPhase.cancelled);
      return;
    }

    state = state.copyWith(phase: SosSubmitPhase.submitting, clearError: true);
    try {
      await ref.read(safetyApiProvider).cancelSos(sosId);
      state = state.copyWith(
        phase: SosSubmitPhase.cancelled,
        progress: 0,
        clearSosId: true,
        clearMessage: true,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        phase: SosSubmitPhase.error,
        errorMessage: 'Unable to cancel SOS. Please try again.',
      );
    }
  }

  void fail(String message) {
    state = state.copyWith(phase: SosSubmitPhase.error, errorMessage: message);
  }

  void reset() {
    state = const SosSubmitState();
  }
}

final sosProvider = NotifierProvider<SosSubmitNotifier, SosSubmitState>(
  SosSubmitNotifier.new,
);
