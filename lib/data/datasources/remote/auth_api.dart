import 'package:dio/dio.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Token not returned by API.');
    }
    return token;
  }

  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'displayName': name, 'email': email, 'password': password},
    );
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Token not returned by API.');
    }
    return token;
  }

  Future<void> updateFcmToken(String token) async {
    await _dio.post('/auth/fcm-token', data: {'token': token});
  }
}
