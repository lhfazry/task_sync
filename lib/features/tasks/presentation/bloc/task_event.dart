import 'package:equatable/equatable.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class TaskLoadRequested extends TaskEvent {
  final String workspaceId;

  const TaskLoadRequested([
    this.workspaceId = '14ac39e4-aa2f-45d3-923b-09ef1f7773cb',
  ]);

  @override
  List<Object?> get props => [workspaceId];
}

class TaskSearchQueryChanged extends TaskEvent {
  final String query;

  const TaskSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class TaskCreated extends TaskEvent {
  final String title;

  const TaskCreated(this.title);

  @override
  List<Object?> get props => [title];
}

class TaskDeleted extends TaskEvent {
  final String id;

  const TaskDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

class TaskMarkedDone extends TaskEvent {
  final String id;
  final bool isDone;

  const TaskMarkedDone({required this.id, this.isDone = true});

  @override
  List<Object?> get props => [id, isDone];
}

class TasksPurged extends TaskEvent {
  const TasksPurged();

  @override
  List<Object?> get props => [];
}

class TaskMoved extends TaskEvent {
  final String id;
  final String column;

  const TaskMoved({required this.id, required this.column});

  @override
  List<Object?> get props => [id, column];
}

class TaskBoardSubcsribed extends TaskEvent {
  final String workspaceId;

  const TaskBoardSubcsribed([
    this.workspaceId = '14ac39e4-aa2f-45d3-923b-09ef1f7773cb',
  ]);

  @override
  List<Object?> get props => [workspaceId];
}

class TaskRenamed extends TaskEvent {
  final String id;
  final String title;

  const TaskRenamed({required this.id, required this.title});

  @override
  List<Object?> get props => [id, title];
}
