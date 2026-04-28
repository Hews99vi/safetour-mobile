import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import 'safety_providers.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  NotificationService service;
  try {
    service = Firebase.apps.isNotEmpty
        ? FirebaseNotificationService(
            messaging: FirebaseMessaging.instance,
            localNotifications: FlutterLocalNotificationsPlugin(),
            dio: ref.watch(dioProvider),
            storage: ref.watch(secureStorageProvider),
          )
        : NoopNotificationService();
  } catch (_) {
    service = NoopNotificationService();
  }
  ref.onDispose(service.dispose);
  return service;
});
