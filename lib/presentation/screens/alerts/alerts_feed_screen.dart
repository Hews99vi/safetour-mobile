import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/alert.dart';
import '../../providers/alerts_feed_provider.dart';
import '../../providers/safe_tour_providers.dart';
import '../../widgets/glass_card.dart';

class AlertsFeedScreen extends ConsumerWidget {
  const AlertsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(filteredAlertsProvider);
    final filter = ref.watch(alertTypeFilterProvider);
    final location = ref.watch(locationProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Alerts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  _AlertFilter(
                    selected: filter,
                    onSelected: (value) => ref
                        .read(alertTypeFilterProvider.notifier)
                        .setFilter(value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(alertsProvider);
                        try {
                          await ref.read(alertsProvider.future);
                        } catch (_) {
                          // The visible error state handles failed refreshes.
                        }
                      },
                      child: alerts.when(
                        loading: () => const _AlertShimmerList(),
                        error: (err, stack) => _AlertError(
                          onRetry: () => ref.invalidate(alertsProvider),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return const _AlertEmpty();
                          }

                          return ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              return _AlertCard(
                                alert: items[index],
                                userLat: location?.latitude,
                                userLng: location?.longitude,
                              );
                            },
                          );
                        },
                      ),
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
}

class _AlertFilter extends StatelessWidget {
  const _AlertFilter({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _SegmentButton(
              label: 'All',
              active: selected == null,
              onTap: () => onSelected(null),
            ),
            _SegmentButton(
              label: 'Crime',
              active: selected == 'crime',
              onTap: () => onSelected('crime'),
            ),
            _SegmentButton(
              label: 'Accident',
              active: selected == 'accident',
              onTap: () => onSelected('accident'),
            ),
            _SegmentButton(
              label: 'Weather',
              active: selected == 'weather',
              onTap: () => onSelected('weather'),
            ),
            _SegmentButton(
              label: 'Scam',
              active: selected == 'scam',
              onTap: () => onSelected('scam'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.neonCyan : AppColors.mist;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          constraints: const BoxConstraints(minWidth: 76),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: active
                ? AppColors.neonCyan.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: active ? AppColors.neonCyan : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatefulWidget {
  const _AlertCard({required this.alert, this.userLat, this.userLng});

  final Alert alert;
  final double? userLat;
  final double? userLng;

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final distance = widget.userLat != null && widget.userLng != null
        ? alert.distanceLabelFrom(widget.userLat!, widget.userLng!)
        : null;

    return Semantics(
      button: true,
      label: 'Alert ${alert.title} ${alert.typeLabel} ${alert.severity}',
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final glowStrength = 0.16 + (_glowController.value * 0.12);

          return GlassCard(
            shadowColor: alert.severityColor.withValues(alpha: glowStrength),
            padding: EdgeInsets.zero,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(20),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        color: alert.severityColor,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(20),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: alert.severityColor.withValues(
                                      alpha: 0.14,
                                    ),
                                    border: Border.all(
                                      color: alert.severityColor.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    alert.typeIcon,
                                    color: alert.severityColor,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppColors.ice,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        alert.description.isEmpty
                                            ? alert.typeLabel
                                            : alert.description,
                                        maxLines: _expanded ? null : 2,
                                        overflow: _expanded
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: AppColors.mist),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: [
                                _MetaPill(
                                  icon: Icons.schedule,
                                  label: alert.timeAgo,
                                ),
                                if (distance != null)
                                  _MetaPill(
                                    icon: Icons.near_me_outlined,
                                    label: distance,
                                  ),
                                _MetaPill(
                                  icon: Icons.report_gmailerrorred,
                                  label: alert.severity,
                                ),
                                _MetaPill(
                                  icon: Icons.verified_outlined,
                                  label: alert.source,
                                ),
                              ],
                            ),
                          ],
                        ),
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glassFill.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.mist),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mist,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertEmpty extends StatelessWidget {
  const _AlertEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        Center(
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.neonLime,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No alerts in your area',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ice,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertError extends StatelessWidget {
  const _AlertError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        Center(
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.danger,
                  size: 28,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Unable to load alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ice,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
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
    );
  }
}

class _AlertShimmerList extends StatelessWidget {
  const _AlertShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        return _ShimmerCard(delay: index * 0.15);
      },
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard({required this.delay});

  final double delay;

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = (_controller.value + widget.delay) % 1;
          return ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                ],
                stops: [
                  (value - 0.3).clamp(0, 1).toDouble(),
                  value.clamp(0, 1).toDouble(),
                  (value + 0.3).clamp(0, 1).toDouble(),
                ],
              ).createShader(rect);
            },
            blendMode: BlendMode.srcATop,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.glassStroke.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.glassStroke.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.glassStroke.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0F1A), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
