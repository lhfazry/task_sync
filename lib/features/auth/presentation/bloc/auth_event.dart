import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthSubmitted extends AuthEvent {
  final String email;
  final String password;

  const AuthSubmitted(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthLoggedOut extends AuthEvent {
  const AuthLoggedOut();

  @override
  List<Object?> get props => [];
}
