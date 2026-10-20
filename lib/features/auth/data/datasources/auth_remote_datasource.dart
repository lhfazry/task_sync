import 'package:task_sync/features/auth/domain/entities/user.dart';

abstract class AuthRemoteDatasource {
  Future<User> login({required String email, required String password});

  Future<void> clearSession();
}
