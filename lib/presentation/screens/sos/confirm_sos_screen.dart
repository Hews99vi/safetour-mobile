import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../providers/confirm_sos_provider.dart';

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
        final failed = Random().nextInt(6) == 0;
        if (failed) {
          debugPrint('Voice: SOS failed. Try again.');
          ref.read(sosProvider.notifier).fail();
        } else {
          debugPrint('Voice: SOS confirmed.');
          ref.read(sosProvider.notifier).confirm();
          _successController.forward(from: 0);
          _navTimer?.cancel();
          _navTimer = Timer(const Duration(milliseconds: 600), () {
            if (!mounted) return;
            context.go('/sos-success');
          });
        }
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
    final isHolding = state.phase == SosConfirmPhase.holding;
    final isConfirmed = state.phase == SosConfirmPhase.confirmed;
    final isFailed = state.phase == SosConfirmPhase.failed;
    final isCancelled = state.phase == SosConfirmPhase.cancelled;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse =
                    isHolding ? (0.4 + _pulseController.value * 0.3) : 0.2;
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
                    'Hold to Confirm SOS',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.ice,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  _HoldButton(
                    progress: state.progress,
                    isHolding: isHolding,
                    isConfirmed: isConfirmed,
                    onHoldStart: _onHoldStart,
                    onHoldEnd: _onHoldEnd,
                    successAnimation: _successController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 240),
                    opacity: isFailed
                        ? 1.0
                        : isCancelled
                            ? 1.0
                            : 0.0,
                    child: Text(
                      isFailed
                          ? 'Failed to send SOS. Try again.'
                          : isCancelled
                              ? 'Hold cancelled.'
                              : '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isFailed ? AppColors.danger : AppColors.mist,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    label: 'Cancel SOS confirmation',
                    child: TextButton(
                      onPressed: () {
                        debugPrint('Voice: SOS cancelled.');
                        ref.read(sosProvider.notifier).cancel();
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
    debugPrint('Haptic: heavy impact (mock).');
    debugPrint('Voice: Holding to confirm SOS.');
    ref.read(sosProvider.notifier).startHold();
    _holdController.forward(from: 0);
    _pulseController.repeat(reverse: true);
  }

  void _onHoldEnd() {
    if (_holdController.isAnimating &&
        _holdController.value < 1 &&
        mounted) {
      _holdController.stop();
      _holdController.value = 0;
      _pulseController.stop();
      ref.read(sosProvider.notifier).cancel();
      debugPrint('Voice: Hold released. SOS reset.');
    }
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.progress,
    required this.isHolding,
    required this.isConfirmed,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.successAnimation,
  });

  final double progress;
  final bool isHolding;
  final bool isConfirmed;
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
          final pulseScale =
              isConfirmed ? 1.0 + (successAnimation.value * 0.08) : 1.0;
          return Transform.scale(
            scale: pulseScale,
            child: GestureDetector(
              onTapDown: (_) => onHoldStart(),
              onTapUp: (_) => onHoldEnd(),
              onTapCancel: onHoldEnd,
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
                      'SOS',
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
