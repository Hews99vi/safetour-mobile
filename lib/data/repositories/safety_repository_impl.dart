import '../../domain/entities/alert.dart';
import '../../domain/repositories/safety_repository.dart';
import '../datasources/remote/safety_api.dart';

class SafetyRepositoryImpl implements SafetyRepository {
  SafetyRepositoryImpl(this._api);

  final SafetyApi _api;

  @override
  Future<List<Alert>> getRecentAlerts() => _api.fetchRecentAlerts();
}
