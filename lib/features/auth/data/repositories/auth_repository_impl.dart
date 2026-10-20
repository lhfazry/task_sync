import 'package:task_sync/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:task_sync/features/auth/domain/entities/user.dart';
import 'package:task_sync/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource datasource;

  AuthRepositoryImpl(this.datasource);

  @override
  Future<User> login({required String email, required String password}) async {
    return await datasource.login(email: email, password: password);
  }

  @override
  Future<void> clearSession() async {
    await datasource.clearSession();
  }
}
