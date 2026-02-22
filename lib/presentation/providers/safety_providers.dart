import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/datasources/remote/safety_api.dart';
import '../../data/repositories/safety_repository_impl.dart';
import '../../data/services/push_notification_service.dart';
import '../../domain/entities/alert.dart';
import '../../domain/repositories/safety_repository.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient(storage).build();
});

final safetyApiProvider = Provider<SafetyApi>((ref) {
  return SafetyApi(ref.watch(dioProvider));
});

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  return SafetyRepositoryImpl(ref.watch(safetyApiProvider));
});

final alertsProvider = FutureProvider<List<Alert>>((ref) async {
  final repository = ref.watch(safetyRepositoryProvider);
  return repository.getRecentAlerts();
});

final pushNotificationProvider = Provider<PushNotificationService>((ref) {
  try {
    return FirebasePushNotificationService(FirebaseMessaging.instance);
  } catch (_) {
    return NoopPushNotificationService();
  }
});
