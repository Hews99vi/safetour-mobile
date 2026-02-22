import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/animated_gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      if (next.isAuthenticated && next.isAuthenticated != prev?.isAuthenticated) {
        context.go('/');
      }
    });

    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Logo(),
                      const SizedBox(height: 20),
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.ice,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Smart Safety for Smart Travelers',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.mist,
                            ),
                      ),
                      const SizedBox(height: 24),
                      _Field(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        controller: _passwordController,
                        label: 'Password',
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      GlowButton(
                        label: 'Login',
                        isLoading: state.isLoading,
                        onPressed: state.isLoading
                            ? null
                            : () {
                                ref.read(authControllerProvider.notifier).login(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    );
                              },
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 12),
                        GlowButton(
                          label: 'Developer Login',
                          isLoading: state.isLoading,
                          onPressed: state.isLoading
                              ? null
                              : () {
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .developerLogin();
                                },
                        ),
                      ],
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Create account'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.neonCyan, AppColors.neonViolet],
            ),
          ),
          child: const Icon(Icons.shield, color: AppColors.midnight),
        ),
        const SizedBox(width: 12),
        Text(
          'SafeTour',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.ice,
              ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.ice,
          ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mist,
            ),
        filled: true,
        fillColor: AppColors.glassFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neonCyan),
        ),
      ),
    );
  }
}
