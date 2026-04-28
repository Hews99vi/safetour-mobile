import 'package:dio/dio.dart';

import '../../models/alert.dart';
import '../../models/chat_message.dart';
import '../../models/risk_score.dart';
import '../../models/safe_zone.dart';
import '../../models/sos_report.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) return 'ApiException: $message';
    return 'ApiException($statusCode): $message';
  }
}

class SafetyApi {
  SafetyApi(this._dio);

  final Dio _dio;

  Future<List<Alert>> fetchRecentAlerts({
    required double lat,
    required double lng,
    int radius = 5000,
    String? type,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/alerts/recent',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
        'limit': limit,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to fetch recent alerts.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    final alertsData = data is Map<String, dynamic> ? data['alerts'] : data;
    if (alertsData is! List) {
      throw const ApiException('Invalid alerts response.');
    }

    return alertsData
        .map((item) => Alert.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SafeZone>> fetchNearbySafeZones({
    required double lat,
    required double lng,
    int radiusMeters = 2000,
  }) async {
    final response = await _dio.get(
      '/locations/safe-zones',
      queryParameters: {'lat': lat, 'lng': lng, 'radius': radiusMeters},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to fetch nearby safe zones.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is! List) {
      throw const ApiException('Invalid safe zones response.');
    }

    return data
        .map((item) => SafeZone.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<RiskScore> fetchRiskScore({
    required double lat,
    required double lng,
  }) async {
    final response = await _dio.get(
      '/locations/risk-score',
      queryParameters: {'lat': lat, 'lng': lng},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to fetch risk score.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid risk score response.');
    }

    return RiskScore.fromJson(data);
  }

  Future<SosResponse> submitSos({
    required double lat,
    required double lng,
    required String emergencyType,
    String? description,
  }) async {
    final response = await _dio.post(
      '/sos/report',
      data: {
        'lat': lat,
        'lng': lng,
        'emergencyType': emergencyType,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException(
        'Failed to submit SOS.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid SOS response.');
    }

    return SosResponse.fromJson(data);
  }

  Future<void> cancelSos(String sosId) async {
    final response = await _dio.post('/sos/$sosId/cancel');

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to cancel SOS.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<ChatMessage>> fetchChatHistory(String roomId) async {
    final response = await _dio.get('/chat/$roomId/history');

    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to fetch chat history.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is! List) {
      throw const ApiException('Invalid chat history response.');
    }

    return data
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
