import 'package:firebase_messaging/firebase_messaging.dart';

abstract class PushNotificationService {
  Future<void> init();
  Future<String?> getToken();
}

class FirebasePushNotificationService implements PushNotificationService {
  FirebasePushNotificationService(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<void> init() async {
    try {
      await _messaging.requestPermission();
    } catch (e) {
      return;
    }
  }

  @override
  Future<String?> getToken() => _messaging.getToken();
}

class NoopPushNotificationService implements PushNotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<String?> getToken() async => null;
}
