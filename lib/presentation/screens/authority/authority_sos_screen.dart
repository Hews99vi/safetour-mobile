import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/glass_card.dart';

class AuthoritySosScreen extends StatelessWidget {
  const AuthoritySosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active SOS')),
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
                  Icons.local_police_outlined,
                  color: AppColors.neonCyan,
                  size: 42,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Authority SOS queue',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ice,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Incoming SOS alerts will open here.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mist),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
