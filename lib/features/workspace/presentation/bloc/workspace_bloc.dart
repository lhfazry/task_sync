import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_sync/core/error/exceptions.dart';
import 'package:task_sync/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:task_sync/features/workspace/presentation/bloc/workspace_event.dart';
import 'package:task_sync/features/workspace/presentation/bloc/workspace_state.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  final WorkspaceRepository repository;

  WorkspaceBloc(this.repository) : super(const WorkspaceState()) {
    on<WorkspaceLoadRequested>(_onLoad);
    on<WorkspacePurged>((event, emit) => emit(const WorkspaceState()));
  }

  Future<void> _onLoad(
    WorkspaceLoadRequested event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(state.copyWith(status: WorkspaceStatus.loading, message: null));
    try {
      final workspaces = await repository.fetchWorkspaces();
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: WorkspaceStatus.loaded,
          workspaces: workspaces,
          selectedId: workspaces.isNotEmpty ? workspaces.first.id : null,
        ),
      );
    } on AppException catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(status: WorkspaceStatus.failure, message: e.message));
    }
  }
}
