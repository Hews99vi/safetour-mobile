import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/alerts/alerts_feed_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/cyber/cyber_protection_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/map/map_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/sos/confirm_sos_screen.dart';
import '../../presentation/screens/sos/sos_success_screen.dart';
import '../../presentation/screens/vpn/vpn_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            _fadeSlideTransition(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) =>
            _fadeSlideTransition(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) =>
            _fadeSlideTransition(state, const HomeScreen()),
        routes: [
          GoRoute(
            path: 'chat',
            name: 'chat',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const ChatScreen()),
          ),
          GoRoute(
            path: 'alerts',
            name: 'alerts',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const AlertsFeedScreen()),
          ),
          GoRoute(
            path: 'cyber-protection',
            name: 'cyber-protection',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const CyberProtectionScreen()),
          ),
          GoRoute(
            path: 'vpn',
            name: 'vpn',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const VpnScreen()),
          ),
          GoRoute(
            path: 'map',
            name: 'map',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const MapScreen()),
          ),
          GoRoute(
            path: 'sos-success',
            name: 'sos-success',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const SOSSentScreen()),
          ),
          GoRoute(
            path: 'sos-confirm',
            name: 'sos-confirm',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const ConfirmSOSScreen()),
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                _fadeSlideTransition(state, const ProfileScreen()),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fadeSlideTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final offset = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(fade);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
