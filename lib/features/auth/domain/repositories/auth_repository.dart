import 'package:task_sync/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});

  Future<void> clearSession();
}
