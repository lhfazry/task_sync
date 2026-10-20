import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:task_sync/core/error/exceptions.dart';
import 'package:task_sync/features/tasks/data/models/task_model.dart';

class TaskSupabaseDatasource {
  TaskSupabaseDatasource({this.client});

  final sb.SupabaseClient? client;

  sb.SupabaseClient get _supabase => client ?? sb.Supabase.instance.client;

  Stream<List<TaskModel>> watchBoard(String workspaceId) {
    try {
      return _supabase
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('workspace_id', workspaceId)
          .order('updated_at')
          .map((rows) => rows.map(rowToModel).toList());
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on sb.AuthRetryableFetchException {
      throw const NetWorkException('Koneksi terputus, coba lagi');
    } on Exception {
      throw const NetWorkException('Koneksi terputus');
    }
  }

  static TaskModel rowToModel(Map<String, dynamic> row) {
    final status = row['status'] as String? ?? 'todo';
    final isDone = row['is_done'] as bool? ?? false;
    return TaskModel(
      id: row['id'] as String,
      title: row['title'] as String,
      column: status,
      isDone: isDone,
    );
  }

  Future<List<TaskModel>> fetchBoard(String workspaceId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('workspace_id', workspaceId)
          .order('updated_at');
      return (response as List)
          .map((row) => rowToModel(row as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on sb.AuthRetryableFetchException {
      throw const NetWorkException('Koneksi terputus, coba lagi');
    } on Exception {
      throw const NetWorkException('Koneksi terputus');
    }
  }

  Future<List<TaskModel>> search(String query, String workspaceId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('workspace_id', workspaceId)
          .ilike('title', '%$query%')
          .or('updated_at');
      return (response as List)
          .map((row) => rowToModel(row as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on sb.AuthRetryableFetchException {
      throw const NetWorkException('Koneksi terputus, coba lagi');
    } on Exception {
      throw const NetWorkException('Koneksi terputus');
    }
  }

  Future<TaskModel> createTask({
    required String title,
    required String workspaceId,
  }) async {
    try {
      final response = await _supabase
          .from('tasks')
          .insert({
            'title': title,
            'status': 'todo',
            'is_done': false,
            'workspace_id': workspaceId,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();
      return rowToModel(response);
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on sb.AuthRetryableFetchException {
      throw const NetWorkException('Koneksi terputus, coba lagi');
    } on Exception {
      throw const NetWorkException('Koneksi terputus');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _supabase.from('tasks').delete().eq('id', id);
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on sb.AuthRetryableFetchException {
      throw const NetWorkException('Koneksi terputus, coba lagi');
    } on Exception {
      throw const NetWorkException('Koneksi terputus');
    }
  }

  Future<void> moveTask({required String id, required String column}) async {
    const allowed = {'todo', 'doing', 'done'};
    if (!allowed.contains(column)) {
      throw ServerException('Invalid column: $column');
    }

    try {
      await _supabase
          .from('tasks')
          .update({
            'status': column,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message);
    } on sb.AuthRetryableFetchException {
      throw const NetWorkException('Koneksi terputus, coba lagi');
    } on Exception {
      throw const NetWorkException('Koneksi terputus');
    }
  }
}
