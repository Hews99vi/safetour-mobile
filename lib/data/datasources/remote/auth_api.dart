import 'package:dio/dio.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return _readToken(response.data);
    } on DioException catch (error) {
      throw AuthApiException(_messageFromDio(error));
    }
  }

  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'displayName': name, 'email': email, 'password': password},
      );
      return _readToken(response.data);
    } on DioException catch (error) {
      throw AuthApiException(_messageFromDio(error));
    }
  }

  Future<void> updateFcmToken(String token) async {
    await _dio.post('/auth/fcm-token', data: {'token': token});
  }

  Future<String> resetPassword({
    required String email,
    required String password,
  }) async {
    try {
      final forgotResponse = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      final forgotData = forgotResponse.data;
      if (forgotData is! Map<String, dynamic>) {
        throw const AuthApiException('Invalid password reset response.');
      }

      final resetToken = forgotData['resetToken']?.toString();
      if (resetToken == null || resetToken.isEmpty) {
        return forgotData['message']?.toString() ??
            'If this email exists, reset instructions have been sent.';
      }

      final resetResponse = await _dio.post(
        '/auth/reset-password',
        data: {'token': resetToken, 'password': password},
      );
      final resetData = resetResponse.data;
      if (resetData is Map<String, dynamic>) {
        return resetData['message']?.toString() ??
            'Password has been reset successfully.';
      }

      return 'Password has been reset successfully.';
    } on DioException catch (error) {
      throw AuthApiException(_messageFromDio(error));
    }
  }

  String _readToken(Object? responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw const AuthApiException('Invalid authentication response.');
    }

    final token = responseData['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const AuthApiException('Token not returned by API.');
    }

    return token;
  }

  String _messageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Cannot reach SafeTour backend. Check the server URL and network.';
      case DioExceptionType.badCertificate:
        return 'Secure connection to backend failed.';
      case DioExceptionType.badResponse:
        return 'Authentication request failed.';
      case DioExceptionType.cancel:
        return 'Authentication request was cancelled.';
      case DioExceptionType.unknown:
        return 'Unable to connect to SafeTour backend.';
    }
  }
}
