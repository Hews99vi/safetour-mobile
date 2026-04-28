abstract class AuthRepository {
  Future<void> login({required String email, required String password});

  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> updateFcmToken(String token);
}
