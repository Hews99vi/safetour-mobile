import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final align = Alignment(
          -1 + (2 * t),
          1 - (2 * t),
        );
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: align,
              end: -align,
              colors: const [
                AppColors.midnight,
                AppColors.deepSpace,
                AppColors.steel,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonViolet.withValues(alpha: 0.35),
                        blurRadius: 90,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -160,
                left: -90,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonCyan.withValues(alpha: 0.18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withValues(alpha: 0.2),
                        blurRadius: 120,
                      ),
                    ],
                  ),
                ),
              ),
              child ?? const SizedBox.shrink(),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
