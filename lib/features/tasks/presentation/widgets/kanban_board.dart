import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_sync/core/widgets/task_card.dart';
import 'package:task_sync/features/tasks/domain/entities/task.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_event.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_state.dart';

class KanbanBoard extends StatelessWidget {
  const KanbanBoard({super.key});

  static const columns = ['todo', 'doing', 'done'];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final column in columns)
          Expanded(child: _KanbanColumn(column: column)),
      ],
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String column;
  const _KanbanColumn({required this.column});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        final tasks = state.tasks.where((t) => t.column == column).toList();
        return Card(
          margin: const EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$column (${tasks.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final task in tasks) _KanbanCard(task: task),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final Task task;
  const _KanbanCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TaskCard(
        title: task.title,
        column: task.column,
        isSyncing: task.isSyncing,
        onTap: () => context.read<TaskBloc>().add(
          TaskMoved(id: task.id, column: _nextColumn(task.column)),
        ),
        onLongPress: () async {
          final controller = TextEditingController(text: task.title);
          final newTitle = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Ubah Judul'),
              content: TextField(controller: controller, autofocus: true),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          if (newTitle != null &&
              newTitle.isNotEmpty &&
              newTitle != task.title) {
            // fire event
            if (context.mounted) {
              context.read<TaskBloc>().add(
                TaskRenamed(id: task.id, title: newTitle),
              );
            }
          }
        },
      ),
    );
  }

  String _nextColumn(String column) {
    return switch (column) {
      'todo' => 'doing',
      'doing' => 'done',
      _ => 'todo',
    };
  }
}
