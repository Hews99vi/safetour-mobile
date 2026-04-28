import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/glass_card.dart';

class SosStatusScreen extends StatelessWidget {
  const SosStatusScreen({super.key, this.sosId});

  final String? sosId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Status')),
      backgroundColor: AppColors.midnight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emergency_share,
                  color: AppColors.danger,
                  size: 42,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'SOS update received',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ice,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sosId != null && sosId!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Reference: $sosId',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.mist),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
