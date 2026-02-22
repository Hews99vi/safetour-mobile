import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../providers/sos_controller.dart';

class SosButtonWidget extends ConsumerStatefulWidget {
  const SosButtonWidget({
    super.key,
    this.onSuccess,
    this.onPressed,
  });

  final VoidCallback? onSuccess;
  final VoidCallback? onPressed;

  @override
  ConsumerState<SosButtonWidget> createState() => _SosButtonWidgetState();
}

class _SosButtonWidgetState extends ConsumerState<SosButtonWidget>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SosState>(sosStateProvider, (prev, next) {
      if (next.phase == SosPhase.triggered &&
          next.phase != prev?.phase &&
          widget.onSuccess != null) {
        widget.onSuccess!();
      }
      if (next.phase == SosPhase.holding && next.phase != prev?.phase) {
        _shakeController.repeat(reverse: true);
      }
      if (next.phase != SosPhase.holding) {
        _shakeController.stop();
        _shakeController.reset();
      }
    });

    final state = ref.watch(sosStateProvider);

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _shakeController]),
      builder: (context, child) {
        final pulse = 0.6 + (_pulseController.value * 0.4);
        final shake = math.sin(_shakeController.value * math.pi * 2) * 2.2;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Hero(
            tag: 'sos-hero',
            child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFF9AA2), AppColors.danger],
                radius: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: pulse),
                  blurRadius: 60,
                  spreadRadius: 12,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: state.phase == SosPhase.triggered
                    ? null
                    : () {
                        if (widget.onPressed != null) {
                          widget.onPressed!();
                        }
                      },
                child: Center(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.phase == SosPhase.holding
                              ? '${(3 - (state.progress * 3)).ceil()}'
                              : 'SOS',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.phase == SosPhase.holding
                              ? 'Hold on'
                              : 'Emergency',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ],
                    ),
                ),
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}
