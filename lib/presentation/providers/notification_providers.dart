import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  NotificationService service;
  try {
    service = Firebase.apps.isNotEmpty
        ? FirebaseNotificationService(FirebaseMessaging.instance)
        : NoopNotificationService();
  } catch (_) {
    service = NoopNotificationService();
  }
  ref.onDispose(service.dispose);
  return service;
});
