import '../models/alert.dart';
import '../../domain/repositories/safety_repository.dart';
import '../datasources/remote/safety_api.dart';

class SafetyRepositoryImpl implements SafetyRepository {
  SafetyRepositoryImpl(this._api);

  final SafetyApi _api;

  @override
  Future<List<Alert>> getRecentAlerts({
    required double lat,
    required double lng,
    int radius = 5000,
    String? type,
    int limit = 20,
  }) {
    return _api.fetchRecentAlerts(
      lat: lat,
      lng: lng,
      radius: radius,
      type: type,
      limit: limit,
    );
  }
}
