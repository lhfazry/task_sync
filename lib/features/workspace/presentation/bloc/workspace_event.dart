import 'package:equatable/equatable.dart';

abstract class WorkspaceEvent extends Equatable {
  const WorkspaceEvent();

  @override
  List<Object?> get props => [];
}

class WorkspaceLoadRequested extends WorkspaceEvent {
  const WorkspaceLoadRequested();
}

class WorkspacePurged extends WorkspaceEvent {
  const WorkspacePurged();
}
