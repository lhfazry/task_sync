import 'package:equatable/equatable.dart';
import 'package:task_sync/features/workspace/domain/entities/workspace.dart';

enum WorkspaceStatus { initial, loading, loaded, failure }

class WorkspaceState extends Equatable {
  final WorkspaceStatus status;
  final List<Workspace> workspaces;
  final String? selectedId;
  final String? message;

  const WorkspaceState({
    this.status = WorkspaceStatus.initial,
    this.workspaces = const [],
    this.selectedId,
    this.message,
  });

  WorkspaceState copyWith({
    WorkspaceStatus? status,
    List<Workspace>? workspaces,
    String? selectedId,
    String? message,
  }) {
    return WorkspaceState(
      status: status ?? this.status,
      workspaces: workspaces ?? this.workspaces,
      selectedId: selectedId ?? this.selectedId,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, workspaces, selectedId, message];
}
