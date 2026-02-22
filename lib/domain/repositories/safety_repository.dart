import '../entities/alert.dart';

abstract class SafetyRepository {
  Future<List<Alert>> getRecentAlerts();
}
