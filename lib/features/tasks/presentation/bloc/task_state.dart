import 'package:equatable/equatable.dart';
import 'package:task_sync/features/tasks/domain/entities/task.dart';

enum TaskStatus { initial, loading, loaded, saving, failure }

class TaskState extends Equatable {
  final TaskStatus status;
  final List<Task> tasks;
  final String query;
  final String? message;

  const TaskState({
    this.status = TaskStatus.initial,
    this.tasks = const [],
    this.query = '',
    this.message,
  });

  TaskState copyWith({
    TaskStatus? status,
    List<Task>? tasks,
    String? query,
    String? message,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      query: query ?? this.query,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, tasks, query, message];
}
