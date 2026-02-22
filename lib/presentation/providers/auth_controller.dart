import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';
import 'safety_providers.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final validation = _validateLogin(email: email, password: password);
    if (validation != null) {
      state = state.copyWith(errorMessage: validation);
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      state = state.copyWith(isLoading: false, isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed. Please try again.',
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final validation = _validateRegister(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (validation != null) {
      state = state.copyWith(errorMessage: validation);
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).register(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed. Please try again.',
      );
    }
  }

  Future<void> developerLogin() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(secureStorageProvider).writeToken('dev-token');
      state = state.copyWith(isLoading: false, isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Developer login failed.',
      );
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  String? _validateLogin({
    required String email,
    required String password,
  }) {
    if (!_isEmailValid(email)) {
      return 'Enter a valid email.';
    }
    if (!_isPasswordStrong(password)) {
      return 'Password must be 8+ chars with a number and uppercase letter.';
    }
    return null;
  }

  String? _validateRegister({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (name.trim().length < 2) {
      return 'Enter your full name.';
    }
    final loginValidation = _validateLogin(email: email, password: password);
    if (loginValidation != null) {
      return loginValidation;
    }
    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  bool _isEmailValid(String email) {
    final regex = RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$');
    return regex.hasMatch(email.trim());
  }

  bool _isPasswordStrong(String password) {
    if (password.length < 8) {
      return false;
    }
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    return hasUppercase && hasNumber;
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
