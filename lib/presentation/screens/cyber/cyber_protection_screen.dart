import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../providers/safe_tour_providers.dart';
import '../../widgets/glass_card.dart';

class CyberProtectionScreen extends ConsumerStatefulWidget {
  const CyberProtectionScreen({super.key});

  @override
  ConsumerState<CyberProtectionScreen> createState() =>
      _CyberProtectionScreenState();
}

class _CyberProtectionScreenState
    extends ConsumerState<CyberProtectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _shieldPulse;
  late final AnimationController _glowController;
  Timer? _sessionTimer;

  bool _autoProtect = true;
  bool _blockUnsafe = true;
  bool _httpsOnly = false;
  bool _scanning = false;

  int _connectedSeconds = 0;
  double _encryptedMb = 0;

  @override
  void initState() {
    super.initState();
    _shieldPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final vpnOn = ref.read(vpnProvider).isOn;
      if (!vpnOn) return;
      setState(() {
        _connectedSeconds += 1;
        _encryptedMb += 0.04;
      });
    });
  }

  @override
  void dispose() {
    _shieldPulse.dispose();
    _glowController.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vpn = ref.watch(vpnProvider);
    final connectivity = ref.watch(connectivityProvider);
    final isOnline = connectivity.isOnline;

    final statusColor = vpn.isOn ? AppColors.neonLime : AppColors.danger;
    final statusLabel = vpn.isOn ? 'Protected' : 'Unsecured';

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
                        'Cyber Protection',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.ice,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  if (!isOnline) const SizedBox(height: AppSpacing.sm),
                  if (!isOnline) const _OfflineBanner(),
                  const SizedBox(height: AppSpacing.md),
                  _ProtectionStatusPanel(
                    statusLabel: statusLabel,
                    statusColor: statusColor,
                    isOn: vpn.isOn,
                    isOnline: isOnline,
                    pulse: _shieldPulse,
                    onToggle: () {
                      if (!isOnline) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed connection. No network.'),
                          ),
                        );
                        return;
                      }
                      ref.read(vpnProvider.notifier).toggle();
                      _glowController.forward(from: 0);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _NetworkInfoCard(
                    isOnline: isOnline,
                    onTap: isOnline
                        ? () => _showScanDialog(context, ref)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      children: [
                        _ToggleRow(
                          label: 'Auto-enable VPN on public Wi-Fi',
                          icon: Icons.wifi_tethering,
                          value: _autoProtect,
                          enabled: isOnline,
                          onChanged: (value) =>
                              setState(() => _autoProtect = value),
                        ),
                        _ToggleRow(
                          label: 'Block unsafe websites',
                          icon: Icons.shield_outlined,
                          value: _blockUnsafe,
                          enabled: isOnline,
                          onChanged: (value) =>
                              setState(() => _blockUnsafe = value),
                        ),
                        _ToggleRow(
                          label: 'HTTPS-only mode',
                          icon: Icons.lock_outline,
                          value: _httpsOnly,
                          enabled: isOnline,
                          onChanged: (value) =>
                              setState(() => _httpsOnly = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _QuickScanSection(
                    scanning: _scanning,
                    enabled: isOnline,
                    onScan: () => _startQuickScan(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SessionInfo(
                    connectedFor: _formatDuration(_connectedSeconds),
                    encryptedMb: _encryptedMb,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startQuickScan(BuildContext context) async {
    if (_scanning) return;
    setState(() => _scanning = true);
    await _showScanDialog(context, ref);
    if (mounted) {
      setState(() => _scanning = false);
    }
  }

  Future<void> _showScanDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const _ScanDialog();
      },
    );
    if (!context.mounted) return;
    final result = Random().nextBool();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result ? 'Scan complete: Network secure.' : 'Scan complete: Risks detected.',
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final sec = seconds % 60;
    final paddedMinutes = minutes.toString().padLeft(2, '0');
    final paddedSeconds = sec.toString().padLeft(2, '0');
    return '$paddedMinutes:$paddedSeconds mins';
  }
}

class _ProtectionStatusPanel extends StatelessWidget {
  const _ProtectionStatusPanel({
    required this.statusLabel,
    required this.statusColor,
    required this.isOn,
    required this.isOnline,
    required this.pulse,
    required this.onToggle,
  });

  final String statusLabel;
  final Color statusColor;
  final bool isOn;
  final bool isOnline;
  final AnimationController pulse;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      shadowColor: statusColor.withValues(alpha: 0.4),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              final scale = isOn ? 1.0 + (pulse.value * 0.08) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.16),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.6),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: isOn ? 0.55 : 0.2),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shield,
                    color: statusColor,
                    size: 32,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  isOn
                      ? 'Encrypted tunnel active for your session.'
                      : 'Protection paused. Enable for safety.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mist,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Semantics(
            label: 'Toggle VPN protection',
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: isOnline ? onToggle : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: AppColors.midnight,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(isOn ? 'Disable' : 'Enable'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkInfoCard extends StatelessWidget {
  const _NetworkInfoCard({
    required this.isOnline,
    this.onTap,
  });

  final bool isOnline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ssid = isOnline ? 'SafeTour-WiFi' : 'No network';
    final encryption = isOnline ? 'WPA2' : 'Open';
    final safe = isOnline ? 'Secure' : 'Risky';
    final badgeColor = isOnline ? AppColors.neonLime : AppColors.danger;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor.withValues(alpha: 0.15),
                border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
              ),
              child: Icon(Icons.wifi, color: badgeColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wi-Fi SSID',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.mist,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ssid,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.ice,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  encryption,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.ice,
                      ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: badgeColor.withValues(alpha: 0.18),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    safe,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: badgeColor,
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: enabled ? AppColors.ice : AppColors.mist,
            ),
      ),
      secondary: Icon(icon, color: enabled ? AppColors.neonCyan : AppColors.mist),
      activeThumbColor: AppColors.neonCyan,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _QuickScanSection extends StatelessWidget {
  const _QuickScanSection({
    required this.scanning,
    required this.enabled,
    required this.onScan,
  });

  final bool scanning;
  final bool enabled;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Scan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ice,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analyze network threats in seconds.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mist,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            label: 'Scan Wi-Fi',
            child: ElevatedButton(
              onPressed: enabled && !scanning ? onScan : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: AppColors.midnight,
              ),
              child: Text(scanning ? 'Scanning...' : 'Scan Wi-Fi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionInfo extends StatelessWidget {
  const _SessionInfo({
    required this.connectedFor,
    required this.encryptedMb,
  });

  final String connectedFor;
  final double encryptedMb;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.timer, color: AppColors.neonCyan, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected for',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.mist,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  connectedFor,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ice,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Data Encrypted',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.mist,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${encryptedMb.toStringAsFixed(1)} MB',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ice,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanDialog extends StatefulWidget {
  const _ScanDialog();

  @override
  State<_ScanDialog> createState() => _ScanDialogState();
}

class _ScanDialogState extends State<_ScanDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scanning Wi-Fi...',
              style: TextStyle(color: AppColors.ice, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 80,
              width: 80,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: _controller.value,
                    strokeWidth: 6,
                    color: AppColors.neonCyan,
                    backgroundColor: AppColors.glassStroke,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Analyzing encryption, DNS, and signal integrity.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mist,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.danger, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'No Network - controls disabled',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.ice,
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
