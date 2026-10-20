import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:task_sync/core/error/exceptions.dart';
import 'package:task_sync/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:task_sync/features/tasks/data/models/task_model.dart';
import 'package:task_sync/features/tasks/domain/entities/task.dart';
import 'package:task_sync/features/tasks/domain/repositories/task_repository.dart';

class InMemoryTaskRepository implements TaskRepository {
  final List<TaskModel> _store;
  final TaskLocalDatasource? local;
  final _boardController = StreamController<List<Task>>.broadcast();

  InMemoryTaskRepository({List<TaskModel>? seed, this.local})
    : _store = List.of(_resolveSeed(local));

  static List<TaskModel> _resolveSeed(TaskLocalDatasource? local) {
    final cached = local?.loadBoard('w1').map(TaskModel.fromJson).toList();
    if (cached != null && cached.isNotEmpty) return cached;
    return const [];
  }

  @override
  Future<List<Task>> fetchBoard(String workspaceId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _store.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Task>> search(String query) async {
    final all = await fetchBoard('any');
    if (query.isEmpty) return all;
    return all
        .where((t) => t.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<Task> createTask(String title) async {
    await Future<void>.delayed(const Duration(microseconds: 150));
    final model = TaskModel(
      id: 't${DateTime.now().microsecondsSinceEpoch}',
      title: title,
    );
    _store.add(model);
    _emitBoard();
    return model.toEntity();
  }

  @override
  Future<void> deleteTask(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _store.removeWhere((m) => m.id == id);
    _emitBoard();
  }

  @override
  Stream<List<Task>> watchBoard(String workspaceId) async* {
    yield _store.map((m) => m.toEntity()).toList();
    yield* _boardController.stream;
  }

  void _emitBoard() {
    if (_boardController.isClosed) return;
    //_boardController.add(_store.map((m) => m.toEntity()).toList());

    final entities = _store.map((m) => m.toEntity()).toList();
    _boardController.add(entities);

    unawaited(local?.saveBoard('w1', _store.map((m) => m.toJson()).toList()));
  }

  void dispose() => _boardController.close();

  @override
  Future<void> moveTask({required String id, required String column}) async {
    const allowed = {'todo', 'doing', 'done'};
    if (!allowed.contains(column)) {
      throw ServerException('Invalid column: $column');
    }

    debugPrint('moving task $id');

    await Future<void>.delayed(const Duration(microseconds: 50));
    final index = _store.indexWhere((m) => m.id == id);
    if (index == -1) return;
    _store[index] = _store[index].copyWith(column: column);
    _emitBoard();
  }

  @override
  Future<void> renameTask({required String id, required String title}) async {
    await Future<void>.delayed(const Duration(microseconds: 150));
    final index = _store.indexWhere((m) => m.id == id);
    debugPrint("index: $index, title: $title");
    if (index == -1) return;
    _store[index] = _store[index].copyWith(title: title);
    _emitBoard();
  }

  @override
  Future<void> setDone({required String id, required bool isDone}) async {
    final op = {'op': 'setDone', 'id': id, 'isDone': isDone};

    await local?.enqueque(op);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final index = _store.indexWhere((m) => m.id == id);
      if (index != -1) {
        _store[index] = _store[index].copyWith(isDone: isDone);
        _emitBoard();
      }

      await local?.dequeue(op);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> flushSyncQueue() async {
    final pending = local?.pendingOps() ?? const [];
    for (final op in pending) {
      if (op['op'] != 'setDone') continue;

      try {
        await Future<void>.delayed(const Duration(microseconds: 50));
        final index = _store.indexWhere((m) => m.id == op['id'] as String);
        if (index != -1) {
          _store[index] = _store[index].copyWith(isDone: op['isDone'] as bool);
          _emitBoard();
        }
        await local?.dequeue(op);
      } catch (_) {}
    }
  }

  @override
  int get pendingCount => local?.pendingOps().length ?? 0;
}
