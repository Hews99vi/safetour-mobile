import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/sos_controller.dart';
import '../../providers/confirm_sos_provider.dart';

class SosConfirmationScreen extends ConsumerWidget {
  const SosConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdState = ref.watch(sosStateProvider);
    final submitState = ref.watch(sosProvider);
    final isActive = submitState.phase == SosSubmitPhase.active;
    final title = isActive
        ? 'SOS Activated'
        : holdState.phase == SosPhase.triggered
        ? 'SOS Ready'
        : 'SOS Ready';
    final subtitle = isActive
        ? submitState.message ?? 'Help is on the way'
        : 'Hold the SOS button for 3 seconds to trigger.';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  colors: [
                    AppColors.danger.withValues(alpha: 0.45),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Hero(
              tag: 'sos-hero',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.glassStroke),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppColors.ice),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.mist),
                        ),
                        if (isActive &&
                            submitState.sosId != null &&
                            submitState.sosId!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'SOS ID: ${submitState.sosId}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.mist),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (isActive)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                await ref
                                    .read(sosProvider.notifier)
                                    .cancelSos();
                                if (context.mounted) {
                                  Navigator.of(context).maybePop();
                                }
                              },
                              child: const Text('Cancel SOS'),
                            ),
                          ),
                        if (isActive) const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(sosStateProvider.notifier).reset();
                              Navigator.of(context).maybePop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
