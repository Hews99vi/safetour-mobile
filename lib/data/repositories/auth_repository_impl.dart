import '../../core/storage/secure_storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._storage);

  final AuthApi _api;
  final SecureStorageService _storage;

  @override
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final token = await _api.login(email: email, password: password);
    await _storage.writeToken(token);
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final token = await _api.register(
      name: name,
      email: email,
      password: password,
    );
    await _storage.writeToken(token);
  }
}
