import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_sync/core/error/exceptions.dart';
import 'package:task_sync/features/auth/domain/repositories/auth_repository.dart';
import 'package:task_sync/features/auth/presentation/bloc/auth_event.dart';
import 'package:task_sync/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc(this.repository)
    : super(const AuthState(status: AuthStatus.initial)) {
    on<AuthSubmitted>(_onSubmitted, transformer: droppable());
    on<AuthLoggedOut>(_onLoggedOut, transformer: droppable());
  }

  Future<void> _onSubmitted(
    AuthSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (event.email.trim().isEmpty || event.password.trim().isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          message: "Email dan password wajib diisi",
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final user = await repository.login(
        email: event.email,
        password: event.password,
      );
      debugPrint('email: ${user.email}');
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } on AppException catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, message: e.message));
    }
  }

  Future<void> _onLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    await repository.clearSession();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
