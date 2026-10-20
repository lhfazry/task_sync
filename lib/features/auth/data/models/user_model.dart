import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:task_sync/features/auth/domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    @Default('member') String role,
    @Default('password') String password,
  }) = _UserModel;

  const UserModel._();

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  User toEntity() {
    return User(id: id, email: email, role: role);
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(id: user.id, email: user.email, role: user.role);
  }
}
