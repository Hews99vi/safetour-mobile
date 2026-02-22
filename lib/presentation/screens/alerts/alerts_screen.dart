import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/glass_card.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back, color: AppColors.ice),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Alerts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.ice,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Low Risk Advisory',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.neonLime,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Stay aware of your surroundings near Market Street.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.ice,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transit Crowd Watch',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFFFBBF24),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Crowd density elevated near Civic Center.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.ice,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'High Risk Alert',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Multiple reports near Embarcadero. Consider detours.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.ice,
                              ),
                        ),
                      ],
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
