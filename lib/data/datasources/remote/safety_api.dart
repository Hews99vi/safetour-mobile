import 'package:dio/dio.dart';

import '../../models/alert_model.dart';

class SafetyApi {
  SafetyApi(this._dio);

  final Dio _dio;

  Future<List<AlertModel>> fetchRecentAlerts() async {
    final response = await _dio.get('/alerts/recent');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => AlertModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
