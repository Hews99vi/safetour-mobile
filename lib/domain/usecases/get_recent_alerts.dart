import '../../data/models/alert.dart';
import '../repositories/safety_repository.dart';

class GetRecentAlerts {
  GetRecentAlerts(this._repository);

  final SafetyRepository _repository;

  Future<List<Alert>> call({
    required double lat,
    required double lng,
    int radius = 5000,
    String? type,
    int limit = 20,
  }) {
    return _repository.getRecentAlerts(
      lat: lat,
      lng: lng,
      radius: radius,
      type: type,
      limit: limit,
    );
  }
}
