import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../providers/auth_controller.dart';
import '../../widgets/animated_gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
                constraints: const BoxConstraints(maxWidth: 520),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go('/login'),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Create account',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.ice,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Smart Safety for Smart Travelers',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.mist,
                            ),
                      ),
                      const SizedBox(height: 24),
                      _Field(
                        controller: _nameController,
                        label: 'Full name',
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      _Field(
                        controller: _confirmController,
                        label: 'Confirm password',
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      GlowButton(
                        label: 'Register',
                        isLoading: state.isLoading,
                        onPressed: state.isLoading
                            ? null
                            : () {
                                ref.read(authControllerProvider.notifier).register(
                                      name: _nameController.text,
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                      confirmPassword: _confirmController.text,
                                    );
                              },
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Already have an account? Login'),
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
