import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/glass_card.dart';

enum SosSentPhase { sending, assigned, resolved, error }

class SOSSentScreen extends StatefulWidget {
  const SOSSentScreen({super.key, this.sosId});

  final String? sosId;

  @override
  State<SOSSentScreen> createState() => _SOSSentScreenState();
}

class _SOSSentScreenState extends State<SOSSentScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _pulseController;
  Timer? _ticker;
  Timer? _assignTimer;
  Timer? _resolveTimer;

  SosSentPhase _phase = SosSentPhase.sending;
  int _etaSeconds = 6 * 60;
  int _cancelWindow = 10;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _assignTimer = Timer(const Duration(seconds: 2), () {
      final fail = Random().nextInt(8) == 0;
      if (fail) {
        _ticker?.cancel();
        setState(() => _phase = SosSentPhase.error);
        return;
      }
      setState(() => _phase = SosSentPhase.assigned);
      _checkController.forward();
      _startCountdowns();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _pulseController.dispose();
    _ticker?.cancel();
    _assignTimer?.cancel();
    _resolveTimer?.cancel();
    super.dispose();
  }

  void _startCountdowns() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_etaSeconds > 0) {
          _etaSeconds -= 1;
        }
        if (_cancelWindow > 0) {
          _cancelWindow -= 1;
        }
      });
    });
    _resolveTimer = Timer(const Duration(seconds: 18), () {
      _ticker?.cancel();
      setState(() => _phase = SosSentPhase.resolved);
    });
  }

  @override
  Widget build(BuildContext context) {
    final phaseLabel = _phase.name;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse = 0.25 + (_pulseController.value * 0.2);
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      colors: [
                        AppColors.neonCyan.withValues(alpha: pulse),
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
                  Semantics(
                    label: 'SOS status $phaseLabel',
                    child: _StatusHeader(
                      phase: _phase,
                      checkController: _checkController,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _MapSnapshot(),
                  const SizedBox(height: AppSpacing.md),
                  if (widget.sosId != null && widget.sosId!.isNotEmpty) ...[
                    Text(
                      'SOS ID: ${widget.sosId}',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.mist),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _ResponderPanel(phase: _phase, eta: _formatEta(_etaSeconds)),
                  const SizedBox(height: AppSpacing.sm),
                  if (_phase == SosSentPhase.assigned && _cancelWindow > 0)
                    Semantics(
                      label: 'Cancel SOS request',
                      child: TextButton(
                        onPressed: () {
                          setState(() => _phase = SosSentPhase.resolved);
                        },
                        child: Text('Cancel (${_cancelWindow}s)'),
                      ),
                    ),
                  if (_phase == SosSentPhase.error)
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          const Icon(Icons.error, color: AppColors.danger),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Unable to assign a responder.',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.ice),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ElevatedButton(
                            onPressed: () {
                              _checkController.reset();
                              _ticker?.cancel();
                              _resolveTimer?.cancel();
                              setState(() {
                                _phase = SosSentPhase.sending;
                                _etaSeconds = 6 * 60;
                                _cancelWindow = 10;
                              });
                              _assignTimer?.cancel();
                              _assignTimer = Timer(
                                const Duration(seconds: 2),
                                () {
                                  setState(
                                    () => _phase = SosSentPhase.assigned,
                                  );
                                  _checkController.forward();
                                  _startCountdowns();
                                },
                              );
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  if (_phase == SosSentPhase.resolved)
                    Text(
                      'Case resolved. Stay safe.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.neonLime,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEta(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.phase, required this.checkController});

  final SosSentPhase phase;
  final AnimationController checkController;

  @override
  Widget build(BuildContext context) {
    final showCheck =
        phase == SosSentPhase.assigned || phase == SosSentPhase.resolved;
    return Column(
      children: [
        AnimatedBuilder(
          animation: checkController,
          builder: (context, child) {
            final scale = showCheck ? (0.6 + checkController.value * 0.4) : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: showCheck ? AppColors.neonCyan : AppColors.danger,
                  boxShadow: [
                    BoxShadow(
                      color: (showCheck ? AppColors.neonCyan : AppColors.danger)
                          .withValues(alpha: 0.55),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Icon(
                  showCheck ? Icons.check : Icons.timelapse,
                  size: 48,
                  color: AppColors.midnight,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Help is on the way',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.ice,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Stay where you are',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mist),
        ),
      ],
    );
  }
}

class _MapSnapshot extends StatelessWidget {
  const _MapSnapshot();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF0B1220), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomPaint(
          painter: _MapLinesPainter(),
          child: const Center(
            child: Icon(Icons.map, color: AppColors.mist, size: 30),
          ),
        ),
      ),
    );
  }
}

class _MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.glassStroke.withValues(alpha: 0.4)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.4,
        size.width * 0.6,
        size.height * 0.5,
        size.width * 0.85,
        size.height * 0.3,
      );
    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ResponderPanel extends StatelessWidget {
  const _ResponderPanel({required this.phase, required this.eta});

  final SosSentPhase phase;
  final String eta;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonCyan.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.person, color: AppColors.neonCyan),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase == SosSentPhase.assigned
                      ? 'Officer Maya Reed'
                      : 'Assigning responder',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ice,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    'ETA: $eta',
                    key: ValueKey<String>(eta),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.mist),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              phase == SosSentPhase.assigned ? 'En Route' : 'Sending',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.neonCyan,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
