import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String role;

  const User({required this.id, required this.email, this.role = 'member'});

  @override
  List<Object> get props => [id, email, role];
}
