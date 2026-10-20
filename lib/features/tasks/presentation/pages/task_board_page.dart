import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_sync/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:task_sync/features/auth/presentation/bloc/auth_event.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_event.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_state.dart';
import 'package:task_sync/features/tasks/presentation/widgets/kanban_board.dart';

class TaskBoardPage extends StatelessWidget {
  const TaskBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == TaskStatus.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Board disconneted'),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () =>
                    context.read<TaskBloc>().add(const TaskBoardSubcsribed()),
              ),
            ),
          );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TaskSync Board'),
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthLoggedOut()),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.read<TaskBloc>().add(
            TaskCreated('New task ${DateTime.now().second}'),
          ),
          child: const Icon(Icons.add),
        ),
        body: KanbanBoard(),
      ),
    );
  }
}
