import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);

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
                        'Profile',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.ice,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: state.when(
                      loading: () => const _ProfileLoading(),
                      error: (error, stack) => _ProfileError(
                        onRetry: () => ref.read(profileProvider.notifier).retry(),
                      ),
                      data: (profile) => _ProfileBody(profile: profile),
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

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final ProfileState profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _SectionHeader(title: 'Emergency Contacts'),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              for (final contact in profile.contacts)
                _ContactRow(
                  contact: contact,
                  onDelete: () {
                    ref.read(profileProvider.notifier).deleteContact(contact);
                    _showSavedSnack(context);
                  },
                ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddContactDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Contact'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionHeader(title: 'Language Selection'),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: profile.language,
              dropdownColor: AppColors.deepSpace,
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Sinhala', child: Text('Sinhala')),
                DropdownMenuItem(value: 'Tamil', child: Text('Tamil')),
              ],
              onChanged: (value) {
                if (value == null) return;
                ref.read(profileProvider.notifier).updateLanguage(value);
                _showSavedSnack(context);
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionHeader(title: 'Permissions'),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              _PermissionToggle(
                label: 'Location access',
                value: profile.locationEnabled,
                onChanged: (value) {
                  ref.read(profileProvider.notifier).toggleLocation(value);
                  _showSavedSnack(context);
                },
                icon: Icons.location_on,
              ),
              _PermissionToggle(
                label: 'Notifications',
                value: profile.notificationsEnabled,
                onChanged: (value) {
                  ref.read(profileProvider.notifier).toggleNotifications(value);
                  _showSavedSnack(context);
                },
                icon: Icons.notifications,
              ),
              _PermissionToggle(
                label: 'VPN protection',
                value: profile.vpnEnabled,
                onChanged: (value) {
                  ref.read(profileProvider.notifier).toggleVpn(value);
                  _showSavedSnack(context);
                },
                icon: Icons.shield,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionHeader(title: 'Appearance'),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: SwitchListTile(
            value: profile.darkMode,
            onChanged: (value) {
              ref.read(profileProvider.notifier).toggleTheme(value);
              ref.read(themeModeProvider.notifier).setMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
              _showSavedSnack(context);
            },
            title: const Text('Dark mode'),
            secondary: const Icon(Icons.dark_mode),
            activeThumbColor: AppColors.neonCyan,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionHeader(title: 'About'),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App version',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.mist,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'SafeTour Live 1.0.0',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ice,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening privacy policy...')),
                  );
                },
                child: const Text('Privacy policy'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  void _showSavedSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved')),
    );
  }

  Future<void> _showAddContactDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final result = await showDialog<EmergencyContact>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.deepSpace,
          title: const Text('Add Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    phoneController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  EmergencyContact(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;
    if (result != null) {
      ref.read(profileProvider.notifier).addContact(result);
      _showSavedSnack(context);
    }
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.onDelete,
  });

  final EmergencyContact contact;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.person, color: AppColors.neonCyan),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.ice,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact.phone,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mist,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Delete contact',
          ),
        ],
      ),
    );
  }
}

class _PermissionToggle extends StatelessWidget {
  const _PermissionToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label),
      secondary: Icon(icon, color: AppColors.neonCyan),
      activeThumbColor: AppColors.neonCyan,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.ice,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.neonCyan),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Unable to load profile',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ice,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
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
