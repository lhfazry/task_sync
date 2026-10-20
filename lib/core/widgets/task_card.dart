import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String column;
  final bool isSyncing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TaskCard({
    super.key,
    required this.title,
    required this.column,
    this.isSyncing = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = switch (column) {
      'todo' => theme.colorScheme.primaryContainer,
      'doing' => theme.colorScheme.secondaryContainer,
      _ => theme.colorScheme.tertiaryContainer,
    };

    final icon = switch (column) {
      'todo' => Icons.radio_button_unchecked,
      'doing' => Icons.timelapse,
      _ => Icons.task_outlined,
    };

    return Card(
      color: bg,
      child: ListTile(
        title: Text(title),
        subtitle: Text(column),
        leading: Icon(icon),
        trailing: isSyncing
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
