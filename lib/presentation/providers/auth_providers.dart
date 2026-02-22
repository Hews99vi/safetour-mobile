import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/auth_api.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'safety_providers.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authApiProvider),
    ref.watch(secureStorageProvider),
  );
});
