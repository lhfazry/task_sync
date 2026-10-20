import 'package:flutter/widgets.dart';
import 'package:task_sync/core/error/exceptions.dart';
import 'package:task_sync/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:task_sync/features/auth/data/models/user_model.dart';
import 'package:task_sync/features/auth/domain/entities/user.dart';

class SupabaseAuthRemoteDatasource implements AuthRemoteDatasource {
  SupabaseAuthRemoteDatasource({this.client});

  final sb.SupabaseClient? client;

  sb.SupabaseClient get _supabase => client ?? sb.Supabase.instance.client;

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final sbUser = response.user;
      if (sbUser == null) {
        throw const AuthException('Email atau password salah');
      }
      final role = await _readRole(sbUser.id);
      return UserModel(
        id: sbUser.id,
        email: sbUser.email ?? email,
        role: role,
      ).toEntity();
    } on AppException {
      rethrow;
    } on sb.AuthRetryableFetchException {
      throw const NetWorkException(
        'Koneksi terputus, silahkan periksa coba lagi',
      );
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on sb.AuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
    } on Exception {
      throw const NetWorkException(
        'Koneksi terputus, silahkan periksa koneksi internet',
      );
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _supabase.auth.signOut();
    } on sb.AuthException catch (e) {
      debugPrint("Supabase signout error: ${e.message}");
    } on Exception catch (e) {
      debugPrint("Supabase signout error: ${e.toString()}");
    }
  }

  Future<String> _readRole(String userId) async {
    final row = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    final role = row?['role'];
    if (role is String && role.isNotEmpty) return role;
    return 'member';
  }

  String _friendlyMessage(sb.AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credential')) {
      return 'Email atau password salah';
    }
    if (message.contains('invalid not confirmed')) {
      return 'Email belum dikonfirmasi';
    }
    if (message.contains('rate limit')) {
      return 'Terlalu banyak request';
    }

    return e.message;
  }
}
