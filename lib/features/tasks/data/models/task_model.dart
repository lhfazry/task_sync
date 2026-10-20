import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:task_sync/features/tasks/domain/entities/task.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
abstract class TaskModel with _$TaskModel {
  const factory TaskModel({
    required String id,
    required String title,
    @Default('todo') String column,
    @Default(false) bool isDone,
    @Default(false) bool isSyncing,
  }) = _TaskModel;

  const TaskModel._();

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  Task toEntity() {
    return Task(
      id: id,
      title: title,
      column: column,
      isDone: isDone,
      isSyncing: isSyncing,
    );
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      column: task.column,
      isDone: task.isDone,
      isSyncing: task.isSyncing,
    );
  }
}
