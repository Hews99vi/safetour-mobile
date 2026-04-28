import '../../data/models/alert.dart';

abstract class SafetyRepository {
  Future<List<Alert>> getRecentAlerts({
    required double lat,
    required double lng,
    int radius = 5000,
    String? type,
    int limit = 20,
  });
}
