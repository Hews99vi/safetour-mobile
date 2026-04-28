import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../storage/secure_storage_service.dart';

abstract class NotificationService {
  Future<void> initialise();
  void dispose();
}

class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService({
    required FirebaseMessaging messaging,
    required FlutterLocalNotificationsPlugin localNotifications,
    required Dio dio,
    required SecureStorageService storage,
  }) : _messaging = messaging,
       _localNotifications = localNotifications,
       _dio = dio,
       _storage = storage;

  static const _androidChannel = AndroidNotificationChannel(
    'safetour_alerts',
    'SafeTour Alerts',
    description: 'Safety alerts, SOS updates, and chat notifications.',
    importance: Importance.max,
  );

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Dio _dio;
  final SecureStorageService _storage;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  @override
  Future<void> initialise() async {
    await _requestPermissions();
    await _setupLocalNotifications();
    await _registerFcmToken();

    _onMessageSub ??= FirebaseMessaging.onMessage.listen((message) {
      _showForegroundNotification(message);
    });

    _onMessageOpenedSub ??= FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      _handleNotificationTap(message);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Future<void>.microtask(() => _handleNotificationTap(initialMessage));
    }
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        _go(payload);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _registerFcmToken() async {
    final authToken = await _storage.readToken();
    if (authToken == null || authToken.isEmpty) return;

    final fcmToken = await _messaging.getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    try {
      await _dio.post('/auth/fcm-token', data: {'token': fcmToken});
    } catch (error) {
      debugPrint('Unable to register FCM token: $error');
    }

    _messaging.onTokenRefresh.listen((token) async {
      try {
        await _dio.post('/auth/fcm-token', data: {'token': token});
      } catch (error) {
        debugPrint('Unable to refresh FCM token: $error');
      }
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? _fallbackTitle(message);
    final body = notification?.body ?? _fallbackBody(message);

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _routeForMessage(message),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = _routeForMessage(message);
    if (route == null || route.isEmpty) return;
    _go(route);
  }

  String? _routeForMessage(RemoteMessage message) {
    final data = message.data;

    switch (data['type']) {
      case 'sos_update':
        final sosId = data['sosId']?.toString();
        if (sosId == null || sosId.isEmpty) return '/sos/status';
        return '/sos/status?sosId=$sosId';
      case 'chat':
        final roomId = data['roomId']?.toString();
        if (roomId == null || roomId.isEmpty) return '/chat';
        return '/chat?roomId=$roomId';
      case 'alert':
        return '/alerts';
      case 'sos_alert':
        return _canOpenAdminRoutes() ? '/authority/sos' : null;
    }

    if (data.containsKey('sosId') && data['role'] == 'tourist') {
      final sosId = data['sosId']?.toString();
      if (sosId == null || sosId.isEmpty) return '/sos/status';
      return '/sos/status?sosId=$sosId';
    }

    final route = data['route']?.toString();
    if (route != null && route.isNotEmpty) return route;

    switch (data['screen']) {
      case 'chat':
        return '/chat';
      case 'vpn':
        return '/vpn';
      case 'map':
        return '/map';
      case 'sos':
        return '/sos/status';
    }

    return null;
  }

  bool _canOpenAdminRoutes() {
    // Keep notification routing conservative for admin-only screens. The GoRouter
    // redirect enforces the real guard after this synchronous hint.
    return true;
  }

  String _fallbackTitle(RemoteMessage message) {
    switch (message.data['type']) {
      case 'sos_update':
        return 'SOS update';
      case 'chat':
        return 'New chat message';
      case 'alert':
        return 'Safety alert';
      case 'sos_alert':
        return 'SOS alert';
      default:
        return 'SafeTour';
    }
  }

  String _fallbackBody(RemoteMessage message) {
    return message.data['body']?.toString() ?? 'Tap to open SafeTour.';
  }

  void _go(String route) {
    final context = appRouterKey.currentContext;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final delayedContext = appRouterKey.currentContext;
        if (delayedContext != null) delayedContext.go(route);
      });
      return;
    }
    context.go(route);
  }
}

class NoopNotificationService implements NotificationService {
  @override
  Future<void> initialise() async {}

  @override
  void dispose() {}
}
