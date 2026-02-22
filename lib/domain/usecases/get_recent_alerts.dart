import '../entities/alert.dart';
import '../repositories/safety_repository.dart';

class GetRecentAlerts {
  GetRecentAlerts(this._repository);

  final SafetyRepository _repository;

  Future<List<Alert>> call() => _repository.getRecentAlerts();
}
