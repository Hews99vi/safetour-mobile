import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../providers/alerts_feed_provider.dart';
import '../../widgets/glass_card.dart';

class AlertsFeedScreen extends ConsumerWidget {
  const AlertsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final filter = ref.watch(alertFilterProvider);

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
                        .read(alertFilterProvider.notifier)
                        .setFilter(value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: alerts.when(
                      loading: () => const _AlertShimmerList(),
                      error: (err, stack) => _AlertError(
                        onRetry: () =>
                            ref.read(alertsProvider.notifier).retry(),
                      ),
                      data: (items) {
                        final filtered = _filterItems(items, filter);
                        if (filtered.isEmpty) {
                          return const _AlertEmpty();
                        }
                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final alert = filtered[index];
                            return _AlertCard(
                              alert: alert,
                              index: index,
                            );
                          },
                        );
                      },
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

  List<AlertItem> _filterItems(List<AlertItem> items, AlertType? filter) {
    if (filter == null) return items;
    return items.where((item) => item.type == filter).toList();
  }
}

class _AlertFilter extends StatelessWidget {
  const _AlertFilter({
    required this.selected,
    required this.onSelected,
  });

  final AlertType? selected;
  final ValueChanged<AlertType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _SegmentButton(
            label: 'All',
            active: selected == null,
            onTap: () => onSelected(null),
          ),
          _SegmentButton(
            label: 'Physical',
            active: selected == AlertType.physical,
            onTap: () => onSelected(AlertType.physical),
          ),
          _SegmentButton(
            label: 'Cyber',
            active: selected == AlertType.cyber,
            onTap: () => onSelected(AlertType.cyber),
          ),
          _SegmentButton(
            label: 'System',
            active: selected == AlertType.system,
            onTap: () => onSelected(AlertType.system),
          ),
        ],
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
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
  const _AlertCard({
    required this.alert,
    required this.index,
  });

  final AlertItem alert;
  final int index;

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _glowController;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _slideAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final iconColor = alertTypeColor(alert.type);
    final glowColor = alertSeverityGlow(alert.severity);
    final hasNewGlow = alert.isNew;

    return Semantics(
      button: true,
      label: 'Alert ${alert.title} ${alert.type.name} ${alert.severity.name}',
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final slideOffset =
              hasNewGlow ? 0.12 * (1 - _slideAnimation.value) : 0.0;
          final glowStrength = hasNewGlow
              ? 0.3 + (_glowController.value * 0.3)
              : 0.18;
          return Transform.translate(
            offset: Offset(0, 24 * slideOffset),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: hasNewGlow ? _slideAnimation.value : 1.0,
              child: GlassCard(
                shadowColor: glowColor.withValues(alpha: glowStrength),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: iconColor.withValues(alpha: 0.16),
                              border: Border.all(
                                color: iconColor.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Icon(
                              alertTypeIcon(alert.type),
                              color: iconColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  alert.shortDescription,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.mist,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            alert.timestamp,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppColors.mist,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                        alignment: Alignment.topLeft,
                        child: _expanded
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert.fullDescription,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.ice),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.xs,
                                      children: [
                                        _ActionButton(
                                          label: 'Navigate',
                                          icon: Icons.navigation,
                                          onTap: () {},
                                        ),
                                        _ActionButton(
                                          label: 'Enable VPN',
                                          icon: Icons.lock,
                                          onTap: () {},
                                        ),
                                        _ActionButton(
                                          label: 'Contact Help',
                                          icon: Icons.support_agent,
                                          onTap: () {},
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: AppColors.ice),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.ice,
            ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: AppColors.glassFill.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.glassStroke),
        ),
      ),
    );
  }
}

class _AlertEmpty extends StatelessWidget {
  const _AlertEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user, color: AppColors.neonLime, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No alerts - you\'re safe',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ice,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertError extends StatelessWidget {
  const _AlertError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 28),
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
    );
  }
}

class _AlertShimmerList extends StatelessWidget {
  const _AlertShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
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
