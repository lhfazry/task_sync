import 'package:task_sync/features/tasks/data/datasources/task_supabase_datasource.dart';
import 'package:task_sync/features/tasks/domain/entities/task.dart';
import 'package:task_sync/features/tasks/domain/repositories/task_repository.dart';

class SupabaseTaskRepository implements TaskRepository {
  final TaskSupabaseDatasource datasource;
  SupabaseTaskRepository(this.datasource);

  static const _defaultWorkspaceId = '14ac39e4-aa2f-45d3-923b-09ef1f7773cb';

  @override
  Future<List<Task>> fetchBoard(String workspaceId) async {
    final models = await datasource.fetchBoard(workspaceId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Task>> search(String query) async {
    if (query.isEmpty) {
      return fetchBoard(_defaultWorkspaceId);
    }

    final models = await datasource.search(query, _defaultWorkspaceId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Task> createTask(String title) async {
    final model = await datasource.createTask(
      title: title,
      workspaceId: _defaultWorkspaceId,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteTask(String id) async {
    await datasource.deleteTask(id);
  }

  @override
  Stream<List<Task>> watchBoard(String workspaceId) {
    return datasource
        .watchBoard(workspaceId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<void> moveTask({required String id, required String column}) async {
    await datasource.moveTask(id: id, column: column);
  }

  @override
  Future<void> setDone({required String id, required bool isDone}) async {
    // kosong
  }

  @override
  Future<void> renameTask({required String id, required String title}) async {
    // kosong
  }

  @override
  Future<void> flushSyncQueue() async {
    // kosong
  }

  @override
  int get pendingCount => 0;
}
