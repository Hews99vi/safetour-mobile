import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart' as map;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/config/map_config.dart';
import '../../../data/models/risk_score.dart';
import '../../../data/models/safe_zone.dart';
import '../../providers/safe_tour_providers.dart';
import '../../providers/safe_zones_provider.dart';
import '../../providers/sos_controller.dart';
import '../../widgets/glass_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  static const double _bottomNavHeight = 86;

  final map.MapController _mapController = map.MapController();
  ProviderSubscription<AsyncValue<Position?>>? _locationSub;
  ProviderSubscription<SosState>? _sosSub;
  late final AnimationController _sosPulseController;

  @override
  void initState() {
    super.initState();
    _sosPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _locationSub = ref.listenManual<AsyncValue<Position?>>(locationProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (position) {
          if (position == null) return;
          _mapController.move(_positionToLatLng(position), 14.8);
        },
        error: (error, stackTrace) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Location unavailable')));
        },
      );
    });

    _sosSub = ref.listenManual<SosState>(sosStateProvider, (previous, next) {
      if (next.phase == SosPhase.triggered &&
          previous?.phase != SosPhase.triggered &&
          mounted) {
        debugPrint('Voice: Emergency SOS sent.');
        context.go('/sos-confirm');
        ref.read(sosStateProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.close();
    _sosSub?.close();
    _sosPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riskScore = ref.watch(riskScoreProvider);
    final vpn = ref.watch(vpnProvider);
    final connectivity = ref.watch(connectivityProvider);
    final location = ref.watch(locationProvider);
    final sosState = ref.watch(sosStateProvider);
    final currentPosition = location.whenOrNull(data: (position) => position);
    final locationResolved = location is AsyncData<Position?>;
    final currentLatLng = currentPosition == null
        ? null
        : _positionToLatLng(currentPosition);
    final safeZones = currentLatLng == null
        ? const AsyncValue<List<SafeZone>>.data([])
        : ref.watch(safeZonesProvider(currentLatLng));
    final safeZoneItems = safeZones.when(
      data: (zones) => zones,
      loading: () => const <SafeZone>[],
      error: (error, stackTrace) => const <SafeZone>[],
    );
    final highRisk = (riskScore.value?.score ?? 0) > 70;

    final markers = <map.Marker>[
      if (currentLatLng != null)
        map.Marker(
          point: currentLatLng,
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
      ...safeZoneItems.map(
        (zone) => map.Marker(
          point: ll.LatLng(zone.lat, zone.lng),
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
            child: map.FlutterMap(
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
          if (location.isLoading) const _LoadingOverlay(),
          if (!connectivity.isOnline) const _OfflineBanner(),
          if (safeZones.hasError) const _SafeZonesErrorBanner(),
          if (highRisk) const _HighRiskBanner(),
          if (location.hasError ||
              (locationResolved && currentPosition == null))
            _GpsErrorCard(
              onRetry: () {
                ref.read(locationProvider.notifier).refresh();
              },
            ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.md,
                  child: _MenuButton(onTap: () => context.go('/profile')),
                ),
                Positioned(
                  top: highRisk ? 78 : AppSpacing.sm,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _RiskStatusCard(
                      riskScore: riskScore,
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
                      _ChatButton(onTap: () => context.go('/chat')),
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

  void _showZoneSheet(SafeZone zone) {
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
                    if (zone.address != null)
                      Text(
                        zone.address!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.mist),
                      ),
                    if (zone.phone != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        zone.phone!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.mist),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        if (zone.phone != null) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _callSafeZone(zone);
                              },
                              icon: const Icon(Icons.call),
                              label: const Text('Call'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _openExternalMap(zone);
                            },
                            icon: const Icon(Icons.navigation),
                            label: const Text('Navigate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.neonCyan,
                              foregroundColor: AppColors.midnight,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _callSafeZone(SafeZone zone) async {
    final phone = zone.phone;
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _openExternalMap(SafeZone zone) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${zone.lat},${zone.lng}';
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  ll.LatLng _positionToLatLng(Position position) {
    return ll.LatLng(position.latitude, position.longitude);
  }
}

class _RiskStatusCard extends StatelessWidget {
  const _RiskStatusCard({required this.riskScore, required this.onTap});

  final AsyncValue<RiskScore?> riskScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open alerts',
      child: GlassCard(
        shadowColor: riskScore.value?.levelColor ?? AppColors.neonCyan,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: riskScore.when(
            loading: () => const _RiskScoreLoading(),
            error: (error, stackTrace) => const _RiskScoreUnavailable(),
            data: (score) {
              if (score == null) return const _RiskScoreUnavailable();
              return _RiskScoreContent(score: score);
            },
          ),
        ),
      ),
    );
  }
}

class _RiskScoreContent extends StatelessWidget {
  const _RiskScoreContent({required this.score});

  final RiskScore score;

  @override
  Widget build(BuildContext context) {
    final color = score.levelColor;
    final factors = score.factors.take(3).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.75), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                score.score.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            score.levelLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (factors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: factors
                  .map((factor) => _RiskFactorPill(label: factor))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _RiskFactorPill extends StatelessWidget {
  const _RiskFactorPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.deepSpace.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.ice,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RiskScoreLoading extends StatelessWidget {
  const _RiskScoreLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 184,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glassStroke.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 112,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.glassStroke.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskScoreUnavailable extends StatelessWidget {
  const _RiskScoreUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.deepSpace.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.radar, color: AppColors.mist, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Risk unavailable',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.ice,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VpnChip extends StatelessWidget {
  const _VpnChip({required this.isOn, required this.onTap});

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
          final pulseScale = isHolding
              ? 1.08 + (animation.value * 0.06)
              : baseScale;
          final glow = isHolding
              ? AppColors.danger.withValues(alpha: 0.7 + animation.value * 0.2)
              : AppColors.danger.withValues(
                  alpha: 0.45 + animation.value * 0.25,
                );
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
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
  const _BottomNavBar({required this.currentIndex, required this.onTap});

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
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: color, fontSize: 11),
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

class _HighRiskBanner extends StatelessWidget {
  const _HighRiskBanner();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.sm,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: SafeArea(
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'High risk area - stay alert',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ice,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.ice),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _SafeZonesErrorBanner extends StatelessWidget {
  const _SafeZonesErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      top: 178,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.place_outlined, color: AppColors.danger, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Nearby safe zones unavailable',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.ice),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafeZoneMarker extends StatelessWidget {
  const _SafeZoneMarker({required this.type});

  final SafeZoneType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      SafeZoneType.police => const Color(0xFF38BDF8),
      SafeZoneType.hospital => const Color(0xFFF87171),
      SafeZoneType.embassy => const Color(0xFFA78BFA),
      SafeZoneType.safeArea => const Color(0xFF34D399),
      SafeZoneType.landmark || SafeZoneType.unknown => AppColors.mist,
    };
    final icon = switch (type) {
      SafeZoneType.police => Icons.local_police,
      SafeZoneType.hospital => Icons.local_hospital,
      SafeZoneType.embassy => Icons.flag,
      SafeZoneType.safeArea => Icons.check_circle,
      SafeZoneType.landmark || SafeZoneType.unknown => Icons.place,
    };

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
