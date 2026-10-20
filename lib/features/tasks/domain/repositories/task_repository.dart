import 'package:task_sync/features/tasks/domain/entities/task.dart';

abstract class TaskRepository {
  Future<List<Task>> fetchBoard(String workspaceId);
  Future<List<Task>> search(String query);
  Future<Task> createTask(String title);
  Future<void> deleteTask(String id);
  Future<void> moveTask({required String id, required String column});
  Stream<List<Task>> watchBoard(String workspaceId);
  Future<void> renameTask({required String id, required String title});
  Future<void> setDone({required String id, required bool isDone});
  Future<void> flushSyncQueue();

  int get pendingCount;
}
