import 'package:equatable/equatable.dart';

class Workspace extends Equatable {
  final String id;
  final String name;
  final int memberCount;

  const Workspace({required this.id, required this.name, this.memberCount = 1});

  Workspace copyWith({String? name, int? memberCount}) {
    return Workspace(
      id: id,
      name: name ?? this.name,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  List<Object> get props => [id, name, memberCount];
}
