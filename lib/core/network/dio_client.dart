import 'package:dio/dio.dart';

import '../config/backend_config.dart';
import '../storage/secure_storage_service.dart';

class DioClient {
  DioClient(this._storage);

  final SecureStorageService _storage;

  Dio build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: BackendConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    return dio;
  }
}
