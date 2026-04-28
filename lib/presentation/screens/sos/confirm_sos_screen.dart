import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../providers/confirm_sos_provider.dart';
import '../../providers/safe_tour_providers.dart';

class ConfirmSOSScreen extends ConsumerStatefulWidget {
  const ConfirmSOSScreen({super.key});

  @override
  ConsumerState<ConfirmSOSScreen> createState() => _ConfirmSOSScreenState();
}

class _ConfirmSOSScreenState extends ConsumerState<ConfirmSOSScreen>
    with TickerProviderStateMixin {
  static const Duration _holdDuration = Duration(seconds: 3);

  late final AnimationController _holdController;
  late final AnimationController _pulseController;
  late final AnimationController _successController;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(vsync: this, duration: _holdDuration);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _holdController.addListener(() {
      ref.read(sosProvider.notifier).updateProgress(_holdController.value);
    });
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _submitSos();
        _pulseController.stop();
      }
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sosProvider);
    final isHolding = state.phase == SosSubmitPhase.holding;
    final isSubmitting = state.phase == SosSubmitPhase.submitting;
    final isActive = state.phase == SosSubmitPhase.active;
    final isError = state.phase == SosSubmitPhase.error;
    final isCancelled = state.phase == SosSubmitPhase.cancelled;

    ref.listen<SosSubmitState>(sosProvider, (previous, next) {
      if (next.phase == SosSubmitPhase.error &&
          next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse = isHolding
                    ? (0.4 + _pulseController.value * 0.3)
                    : 0.2;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      colors: [
                        AppColors.danger.withValues(alpha: pulse),
                        AppColors.midnight,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: const SizedBox.shrink(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isActive ? 'SOS Active' : 'Hold to Confirm SOS',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.ice,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _HoldButton(
                    progress: state.progress,
                    isHolding: isHolding,
                    isActive: isActive,
                    isSubmitting: isSubmitting,
                    onHoldStart: _onHoldStart,
                    onHoldEnd: _onHoldEnd,
                    successAnimation: _successController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isSubmitting)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  if (isActive)
                    _ActiveSosPanel(
                      sosId: state.sosId,
                      message: state.message,
                      onCancel: _cancelSos,
                    ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 240),
                    opacity: isError || isCancelled ? 1.0 : 0.0,
                    child: Text(
                      isError
                          ? state.errorMessage ??
                                'Failed to send SOS. Try again.'
                          : isCancelled
                          ? 'Hold cancelled.'
                          : '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isError ? AppColors.danger : AppColors.mist,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    label: 'Cancel SOS confirmation',
                    child: TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              debugPrint('Voice: SOS cancelled.');
                              ref.read(sosProvider.notifier).cancelHold();
                              context.pop();
                            },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onHoldStart() {
    final state = ref.read(sosProvider);
    if (state.phase == SosSubmitPhase.submitting ||
        state.phase == SosSubmitPhase.active) {
      return;
    }
    debugPrint('Haptic: heavy impact.');
    debugPrint('Voice: Holding to confirm SOS.');
    ref.read(sosProvider.notifier).startHold();
    _holdController.forward(from: 0);
    _pulseController.repeat(reverse: true);
  }

  void _onHoldEnd() {
    if (_holdController.isAnimating && _holdController.value < 1 && mounted) {
      _holdController.stop();
      _holdController.value = 0;
      _pulseController.stop();
      ref.read(sosProvider.notifier).cancelHold();
      debugPrint('Voice: Hold released. SOS reset.');
    }
  }

  Future<void> _submitSos() async {
    final position = ref
        .read(locationProvider)
        .whenOrNull(data: (value) => value);

    if (position == null) {
      ref.read(sosProvider.notifier).fail('Location unavailable');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location unavailable'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    debugPrint('Voice: SOS confirmed.');
    await ref
        .read(sosProvider.notifier)
        .triggerSos(position.latitude, position.longitude, 'other');

    if (ref.read(sosProvider).phase == SosSubmitPhase.active) {
      _successController.forward(from: 0);
    }
  }

  Future<void> _cancelSos() async {
    await ref.read(sosProvider.notifier).cancelSos();
    if (!mounted) return;
    if (ref.read(sosProvider).phase == SosSubmitPhase.cancelled) {
      context.go('/');
    }
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.progress,
    required this.isHolding,
    required this.isActive,
    required this.isSubmitting,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.successAnimation,
  });

  final double progress;
  final bool isHolding;
  final bool isActive;
  final bool isSubmitting;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;
  final Animation<double> successAnimation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Send Emergency SOS',
      button: true,
      child: AnimatedBuilder(
        animation: successAnimation,
        builder: (context, child) {
          final pulseScale = isActive
              ? 1.0 + (successAnimation.value * 0.08)
              : 1.0;
          return Transform.scale(
            scale: pulseScale,
            child: GestureDetector(
              onTapDown: isSubmitting || isActive ? null : (_) => onHoldStart(),
              onTapUp: isSubmitting || isActive ? null : (_) => onHoldEnd(),
              onTapCancel: isSubmitting || isActive ? null : onHoldEnd,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFF8A8A), AppColors.danger],
                    radius: 0.9,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.6),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      isSubmitting ? '...' : 'SOS',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (isHolding)
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActiveSosPanel extends StatelessWidget {
  const _ActiveSosPanel({
    required this.sosId,
    required this.message,
    required this.onCancel,
  });

  final String? sosId;
  final String? message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified, color: AppColors.neonLime, size: 30),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message ?? 'Help is on the way',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ice,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sosId != null && sosId!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'SOS ID: $sosId',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mist),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel SOS'),
            ),
          ),
        ],
      ),
    );
  }
}
