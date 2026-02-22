import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../providers/vpn_controller.dart';

class VpnScreen extends ConsumerStatefulWidget {
  const VpnScreen({super.key});

  @override
  ConsumerState<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends ConsumerState<VpnScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vpnControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          const _CyberBackground(),
          _ParticleField(animation: _particleController),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'SafeTour VPN',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.ice,
                      ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    final glow = state.isActive
                        ? 0.35 + _glowController.value * 0.35
                        : 0.15;
                    return Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: state.isActive
                            ? const RadialGradient(
                                colors: [
                                  AppColors.neonCyan,
                                  AppColors.neonViolet,
                                ],
                              )
                            : const RadialGradient(
                                colors: [Color(0xFF1F2937), Color(0xFF0B0F1A)],
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: (state.isActive
                                    ? AppColors.neonCyan
                                    : Colors.black)
                                .withValues(alpha: glow),
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield,
                        size: 72,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: state.isConnecting
                      ? const _ConnectingLabel()
                      : Text(
                          state.isActive ? 'Protected' : 'Unsecured',
                          key: ValueKey(state.status),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: state.isActive
                                    ? AppColors.neonCyan
                                    : AppColors.mist,
                              ),
                        ),
                ),
                const SizedBox(height: 8),
                if (state.isConnecting)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  child: _SwitchCard(
                    enabled: state.isActive,
                    isConnecting: state.isConnecting,
                    onToggle: () =>
                        ref.read(vpnControllerProvider.notifier).toggle(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberBackground extends StatelessWidget {
  const _CyberBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.accent,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonViolet.withValues(alpha: 0.4),
                    blurRadius: 90,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.enabled,
    required this.isConnecting,
    required this.onToggle,
  });

  final bool enabled;
  final bool isConnecting;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              enabled ? 'Secure tunnel active' : 'Tap to secure connection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ice,
                  ),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: isConnecting ? null : (_) => onToggle(),
            activeThumbColor: AppColors.neonCyan,
            inactiveThumbColor: AppColors.mist,
          ),
        ],
      ),
    );
  }
}

class _ConnectingLabel extends StatelessWidget {
  const _ConnectingLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Connecting...',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.neonViolet,
          ),
    );
  }
}

class _ParticleField extends StatelessWidget {
  const _ParticleField({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(animation),
      size: Size.infinite,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.neonCyan.withValues(alpha: 0.12);
    final t = animation.value;
    for (var i = 0; i < 28; i++) {
      final dx = (size.width * (i / 28)) + (math.sin(t * 2 * math.pi + i) * 12);
      final dy = (size.height * ((i * 1.7) % 28) / 28) +
          (math.cos(t * 2 * math.pi + i) * 10);
      canvas.drawCircle(Offset(dx, dy), 2.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
