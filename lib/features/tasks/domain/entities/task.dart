import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String title;
  final String column;
  final bool isDone;
  final bool isSyncing;

  const Task({
    required this.id,
    required this.title,
    this.column = 'todo',
    this.isDone = false,
    this.isSyncing = false,
  });

  Task copyWith({
    String? title,
    String? column,
    bool? isDone,
    bool? isSyncing,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      column: column ?? this.column,
      isDone: isDone ?? this.isDone,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object> get props => [id, title, column, isDone, isSyncing];
}
