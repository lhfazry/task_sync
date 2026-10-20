import 'package:flutter/foundation.dart';
import 'package:task_sync/core/error/exceptions.dart';
import 'package:task_sync/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:task_sync/features/auth/data/models/user_model.dart';
import 'package:task_sync/features/auth/domain/entities/user.dart';

class InMemoryAuthRemoteDatasource implements AuthRemoteDatasource {
  late final Map<String, UserModel> _users;

  InMemoryAuthRemoteDatasource() {
    _users = {
      'admin@tasksync.dev': UserModel(
        id: '1',
        email: 'admin@tasksync.dev',
        role: 'admin',
      ),
      'member@tasksync.dev': UserModel(
        id: '2',
        email: 'member@tasksync.dev',
        role: 'member',
      ),
    };
  }

  @override
  Future<User> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final userModel = _users[email];
    if (userModel == null) {
      throw AuthException('Email atau password salah');
    }

    if (password != 'password') {
      throw AuthException('Email atau password salah');
    }

    debugPrint('email: ${userModel.email}');

    return userModel.toEntity();
  }

  @override
  Future<void> clearSession() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
