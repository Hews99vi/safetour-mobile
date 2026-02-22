import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

abstract class NotificationService {
  Future<void> init(GoRouter router);
  void dispose();
}

class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService(this._messaging);

  final FirebaseMessaging _messaging;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  @override
  Future<void> init(GoRouter router) async {
    await _messaging.requestPermission();

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRouting(initialMessage, router);
    }

    _onMessageSub ??= FirebaseMessaging.onMessage.listen((message) {
      // Foreground handling placeholder.
    });

    _onMessageOpenedSub ??= FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleRouting(message, router);
    });
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
  }

  void _handleRouting(RemoteMessage message, GoRouter router) {
    final route = _resolveRoute(message);
    if (route == null) return;
    router.go(route);
  }

  String? _resolveRoute(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('route')) {
      return data['route'] as String?;
    }
    if (data.containsKey('screen')) {
      switch (data['screen']) {
        case 'chat':
          return '/chat';
        case 'vpn':
          return '/vpn';
        case 'map':
          return '/map';
        case 'sos':
          return '/sos-success';
      }
    }
    return null;
  }
}

class NoopNotificationService implements NotificationService {
  @override
  Future<void> init(GoRouter router) async {}

  @override
  void dispose() {}
}
