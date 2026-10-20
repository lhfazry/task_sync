import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:task_sync/core/error/exceptions.dart';
import 'package:task_sync/features/tasks/domain/entities/task.dart';
import 'package:task_sync/features/tasks/domain/repositories/task_repository.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_event.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_state.dart';

EventTransformer<E> debounceRestartable<E>(Duration duration) {
  return (events, mapper) =>
      restartable<E>().call(events.debounceTime(duration), mapper);
}

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;

  TaskBloc(this.repository) : super(const TaskState()) {
    on<TaskLoadRequested>(_onLoad, transformer: concurrent());
    on<TaskSearchQueryChanged>(
      _onSearchChanged,
      transformer: debounceRestartable(const Duration(milliseconds: 300)),
    );
    on<TaskCreated>(_onCreated, transformer: droppable());
    on<TaskDeleted>(_onDeleted, transformer: droppable());
    on<TaskMarkedDone>(_onMarkedDone);
    on<TasksPurged>((event, emit) => emit(const TaskState()));
    on<TaskMoved>(_onMoved, transformer: droppable());
    on<TaskBoardSubcsribed>(_onBoardSubscribed, transformer: restartable());
    on<TaskRenamed>(_onRenamed, transformer: droppable());
  }

  Future<void> _onLoad(TaskLoadRequested event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: TaskStatus.loading, message: null));

    try {
      final tasks = await repository.fetchBoard(event.workspaceId);
      if (emit.isDone) return;
      emit(state.copyWith(status: TaskStatus.loaded, tasks: tasks));
    } on AppException catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(status: TaskStatus.failure, message: e.message));
    } catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(status: TaskStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onSearchChanged(
    TaskSearchQueryChanged event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(query: event.query, status: TaskStatus.loading));
    try {
      final tasks = await repository.search(event.query);
      if (emit.isDone) return;
      emit(state.copyWith(status: TaskStatus.loaded, tasks: tasks));
    } on AppException catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(status: TaskStatus.failure, message: e.message));
    }
  }

  Future<void> _onCreated(TaskCreated event, Emitter<TaskState> emit) async {
    if (event.title.trim().isEmpty) return;
    emit(state.copyWith(status: TaskStatus.saving, message: null));
    try {
      final created = await repository.createTask(event.title.trim());
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: TaskStatus.loaded,
          tasks: [...state.tasks, created],
        ),
      );
    } on AppException catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(status: TaskStatus.failure, message: e.message));
    }
  }

  Future<void> _onDeleted(TaskDeleted event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: TaskStatus.saving, message: null));
    try {
      await repository.deleteTask(event.id);
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: TaskStatus.loaded,
          tasks: state.tasks.where((t) => t.id != event.id).toList(),
        ),
      );
    } on AppException catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(status: TaskStatus.failure, message: e.message));
    }
  }

  void _onMarkedDone(TaskMarkedDone event, Emitter<TaskState> emit) async {
    // final updated = state.tasks
    //     .map((t) => t.id == event.id ? t.copyWith(isDone: event.isDone) : t)
    //     .toList();

    // emit(state.copyWith(status: TaskStatus.loaded, tasks: updated));

    final snapshot = state.tasks;
    final optimistic = snapshot
        .map(
          (t) => t.id == event.id
              ? t.copyWith(isDone: event.isDone, isSyncing: true)
              : t,
        )
        .toList();

    emit(state.copyWith(status: TaskStatus.loaded, tasks: optimistic));
    try {
      await repository.setDone(id: event.id, isDone: event.isDone);
      if (emit.isDone) return;
    } on AppException catch (e) {
      if (emit.isDone) return;

      emit(
        state.copyWith(
          status: TaskStatus.failure,
          tasks: snapshot,
          message: e.message,
        ),
      );
    }
  }

  Future<void> _onMoved(TaskMoved event, Emitter<TaskState> emit) async {
    const allowed = {'todo', 'doing', 'done'};
    if (!allowed.contains(event.column)) return;
    try {
      await repository.moveTask(id: event.id, column: event.column);
      if (emit.isDone) return;
    } on AppException catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(status: TaskStatus.failure, message: e.message));
    }
  }

  Future<void> _onBoardSubscribed(
    TaskBoardSubcsribed event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskStatus.loading, message: null));

    await repository.flushSyncQueue();
    if (emit.isDone) return;

    await emit.forEach<List<Task>>(
      repository.watchBoard(event.workspaceId),
      onData: (tasks) =>
          state.copyWith(status: TaskStatus.loaded, tasks: tasks),
      onError: (_, _) => state.copyWith(
        status: TaskStatus.failure,
        message: 'Board disconneted',
      ),
    );
    if (emit.isDone) return;
  }

  Future<void> _onRenamed(TaskRenamed event, Emitter<TaskState> emit) async {
    final title = event.title.trim();
    if (title.isEmpty) return;
    emit(state.copyWith(status: TaskStatus.saving, message: null));
    try {
      await repository.renameTask(id: event.id, title: title);
      if (emit.isDone) return;

      final updated = state.tasks
          .map((t) => t.id == event.id ? t.copyWith(title: title) : t)
          .toList();

      emit(state.copyWith(status: TaskStatus.loaded, tasks: updated));
    } on AppException catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(status: TaskStatus.failure, message: e.message));
    }
  }
}
