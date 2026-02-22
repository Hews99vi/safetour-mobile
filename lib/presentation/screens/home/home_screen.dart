import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart' as map;
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/config/map_config.dart';
import '../../providers/safe_tour_providers.dart';
import '../../providers/sos_controller.dart';
import '../../widgets/glass_card.dart';
import '../sos/sos_confirmation_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  static const double _bottomNavHeight = 86;

  final map.MapController _mapController = map.MapController();
  ProviderSubscription<LocationStatus>? _locationSub;
  ProviderSubscription<SosState>? _sosSub;
  late final AnimationController _riskGlowController;
  late final AnimationController _sosPulseController;
  late final Animation<Color?> _riskGlowColor;

  final List<_SafeZone> _safeZones = const [
    _SafeZone(
      name: 'Central Police Station',
      distance: '0.8 km',
      position: ll.LatLng(37.7758, -122.4182),
      type: _SafeZoneType.police,
    ),
    _SafeZone(
      name: 'Embassy District',
      distance: '1.4 km',
      position: ll.LatLng(37.7818, -122.4235),
      type: _SafeZoneType.embassy,
    ),
    _SafeZone(
      name: 'City Hospital',
      distance: '1.1 km',
      position: ll.LatLng(37.7702, -122.4138),
      type: _SafeZoneType.hospital,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _riskGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _riskGlowColor = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: AppColors.neonLime, end: const Color(0xFFFBBF24)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: const Color(0xFFFBBF24), end: AppColors.danger),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: AppColors.danger, end: AppColors.neonLime),
        weight: 1,
      ),
    ]).animate(_riskGlowController);

    _sosPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _locationSub = ref.listenManual<LocationStatus>(
      locationProvider,
      (previous, next) {
        if (next.location == null) {
          return;
        }
      _mapController.move(next.location!, 14.8);
      },
    );

    _sosSub = ref.listenManual<SosState>(
      sosStateProvider,
      (previous, next) {
      if (next.phase == SosPhase.triggered &&
          previous?.phase != SosPhase.triggered &&
          mounted) {
        debugPrint('Voice: Emergency SOS sent.');
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => const SosConfirmationScreen(),
        );
      }
      },
    );
  }

  @override
  void dispose() {
    _locationSub?.close();
    _sosSub?.close();
    _riskGlowController.dispose();
    _sosPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final risk = ref.watch(riskProvider);
    final vpn = ref.watch(vpnProvider);
    final connectivity = ref.watch(connectivityProvider);
    final location = ref.watch(locationProvider);
    final sosState = ref.watch(sosStateProvider);

    final markers = <map.Marker>[
      if (location.location != null)
        map.Marker(
          point: location.location!,
          width: 18,
          height: 18,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3B82F6),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ..._safeZones.map(
        (zone) => map.Marker(
          point: zone.position,
          width: 46,
          height: 46,
          child: GestureDetector(
            onTap: () => _showZoneSheet(zone),
            child: _SafeZoneMarker(type: zone.type),
          ),
        ),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: location.mapFailed
                ? _MapFallback(onRetry: () {
                    ref.read(locationProvider.notifier).retry();
                  })
                : map.FlutterMap(
                    mapController: _mapController,
                    options: const map.MapOptions(
                      initialCenter: ll.LatLng(6.9271, 79.8612),
                      initialZoom: 13,
                      interactionOptions: map.InteractionOptions(
                        flags: map.InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      map.TileLayer(
                        urlTemplate:
                            "https://api.maptiler.com/maps/dataviz-dark/{z}/{x}/{y}.png?key=${MapConfig.mapTilerKey}",
                        userAgentPackageName: "com.safetour.app",
                      ),
                      map.MarkerLayer(markers: markers),
                    ],
                  ),
          ),
          if (location.isLoading)
            const _LoadingOverlay(),
          if (!connectivity.isOnline)
            const _OfflineBanner(),
          if (location.hasError)
            _GpsErrorCard(onRetry: () {
              ref.read(locationProvider.notifier).retry();
            }),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.md,
                  child: _MenuButton(
                    onTap: () => context.go('/profile'),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _RiskStatusCard(
                      risk: risk,
                      glowColor: _riskGlowColor,
                      onTap: () => context.go('/alerts'),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.md,
                  child: Column(
                    children: [
                      _VpnChip(
                        isOn: vpn.isOn,
                        onTap: () => context.go('/cyber-protection'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ChatButton(
                        onTap: () => context.go('/chat'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: _bottomNavHeight + 18,
            child: Center(
              child: _SosButton(
                state: sosState,
                animation: _sosPulseController,
                onHoldStart: () {
                  if (ref.read(sosStateProvider).phase == SosPhase.triggered) {
                    return;
                  }
                  debugPrint('Haptic: heavy impact (mock).');
                  debugPrint('Voice: Hold for three seconds to send SOS.');
                  ref.read(sosStateProvider.notifier).startHold();
                },
                onHoldEnd: () {
                  if (ref.read(sosStateProvider).phase == SosPhase.holding) {
                    debugPrint('Voice: SOS cancelled.');
                  }
                  ref.read(sosStateProvider.notifier).cancelHold();
                },
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _BottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/');
                    break;
                  case 1:
                    context.go('/alerts');
                    break;
                  case 2:
                    context.go('/chat');
                    break;
                  case 3:
                    context.go('/profile');
                    break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showZoneSheet(_SafeZone zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.glassStroke),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.ice,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Distance: ${zone.distance}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mist,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openExternalMap(zone);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonCyan,
                          foregroundColor: AppColors.midnight,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Navigate'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openExternalMap(_SafeZone zone) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${zone.position.latitude},${zone.position.longitude}';
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _RiskStatusCard extends StatelessWidget {
  const _RiskStatusCard({
    required this.risk,
    required this.glowColor,
    required this.onTap,
  });

  final RiskStatus risk;
  final Animation<Color?> glowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open alerts',
      child: AnimatedBuilder(
        animation: glowColor,
        builder: (context, child) {
          final color = glowColor.value ?? risk.glowColor;
          return GlassCard(
            shadowColor: color,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Risk: ${risk.level}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    risk.explanation,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.ice,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.deepSpace.withValues(alpha: 0.6),
                      border: Border.all(color: AppColors.glassStroke),
                    ),
                    child: Text(
                      'Updated ${risk.updatedSeconds}s ago',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.mist,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VpnChip extends StatelessWidget {
  const _VpnChip({
    required this.isOn,
    required this.onTap,
  });

  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isOn ? AppColors.neonCyan : AppColors.danger;
    return Semantics(
      button: true,
      label: 'Open cyber protection',
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield, color: color, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isOn ? 'VPN: On' : 'VPN: Off',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.ice,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  const _ChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open chat',
      child: SizedBox(
        width: 48,
        height: 48,
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: const Center(
              child: Icon(Icons.chat_bubble, color: AppColors.ice, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open profile menu',
      child: SizedBox(
        width: 48,
        height: 48,
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: const Center(
              child: Icon(Icons.menu, color: AppColors.ice, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton({
    required this.state,
    required this.animation,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final SosState state;
  final Animation<double> animation;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    final isHolding = state.phase == SosPhase.holding;
    return Semantics(
      button: true,
      label: 'Send Emergency SOS',
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final baseScale = 1 + (animation.value * 0.06);
          final pulseScale = isHolding ? 1.08 + (animation.value * 0.06) : baseScale;
          final glow = isHolding
              ? AppColors.danger.withValues(alpha: 0.7 + animation.value * 0.2)
              : AppColors.danger.withValues(alpha: 0.45 + animation.value * 0.25);
          return Transform.scale(
            scale: pulseScale,
            child: Hero(
              tag: 'sos-hero',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isHolding)
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.danger.withValues(alpha: 0.2),
                      ),
                    ),
                  GestureDetector(
                    onTapDown: (_) => onHoldStart(),
                    onTapUp: (_) => onHoldEnd(),
                    onTapCancel: onHoldEnd,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFA3A3), AppColors.danger],
                          radius: 0.9,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: glow,
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            'SOS',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          if (isHolding)
                            SizedBox(
                              width: 86,
                              height: 86,
                              child: CircularProgressIndicator(
                                value: state.progress,
                                strokeWidth: 6,
                                color: Colors.white,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: _HomeScreenState._bottomNavHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.glassStroke),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                icon: Icons.home,
                label: 'Home',
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.warning_amber_rounded,
                label: 'Alerts',
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.chat_bubble,
                label: 'Chat',
                active: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person,
                label: 'Profile',
                active: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.neonCyan : AppColors.mist;
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 64,
        height: 48,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: AppColors.midnight.withValues(alpha: 0.45),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan),
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: AppColors.danger,
          child: Text(
            'Offline Mode',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _GpsErrorCard extends StatelessWidget {
  const _GpsErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      top: 120,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.gps_off, color: AppColors.danger, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
              'Location unavailable - retry',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.ice,
                    ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B0F1A), Color(0xFF111827)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _FallbackMapPainter()),
          Center(
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map_outlined, color: AppColors.ice, size: 28),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Map unavailable',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.ice,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Retry loading the live map.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mist,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      foregroundColor: AppColors.midnight,
                    ),
                    child: const Text('Retry'),
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

class _FallbackMapPainter extends StatelessWidget {
  const _FallbackMapPainter();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MockMapPainter(),
    );
  }
}

class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.glassStroke.withValues(alpha: 0.5)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadPaint2 = Paint()
      ..color = AppColors.glassStroke.withValues(alpha: 0.3)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final major = Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.55,
        size.width * 0.5,
        size.height * 0.65,
        size.width * 0.85,
        size.height * 0.5,
      );
    canvas.drawPath(major, roadPaint);

    final minor = Path()
      ..moveTo(size.width * 0.2, size.height * 0.25)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.35,
        size.width * 0.6,
        size.height * 0.2,
        size.width * 0.85,
        size.height * 0.3,
      );
    canvas.drawPath(minor, roadPaint2);

    final routePaint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.85)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final route = Path()
      ..moveTo(size.width * 0.2, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.55,
        size.width * 0.68,
        size.height * 0.62,
      );
    canvas.drawPath(route, routePaint);

    final nodePaint = Paint()..color = AppColors.neonLime;
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.68),
      5,
      nodePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.62),
      5,
      nodePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SafeZoneMarker extends StatelessWidget {
  const _SafeZoneMarker({required this.type});

  final _SafeZoneType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      _SafeZoneType.police => const Color(0xFF38BDF8),
      _SafeZoneType.embassy => const Color(0xFFA78BFA),
      _SafeZoneType.hospital => const Color(0xFFF87171),
    };
    final icon = switch (type) {
      _SafeZoneType.police => Icons.local_police,
      _SafeZoneType.embassy => Icons.flag,
      _SafeZoneType.hospital => Icons.local_hospital,
    };

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

enum _SafeZoneType { police, embassy, hospital }

class _SafeZone {
  const _SafeZone({
    required this.name,
    required this.distance,
    required this.position,
    required this.type,
  });

  final String name;
  final String distance;
  final ll.LatLng position;
  final _SafeZoneType type;
}
