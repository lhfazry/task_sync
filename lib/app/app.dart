import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_sync/app/di/injection.dart';
import 'package:task_sync/app/router.dart';
import 'package:task_sync/core/theme/cubit/theme_cubit.dart';
import 'package:task_sync/core/theme/cubit/theme_state.dart';
import 'package:task_sync/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:task_sync/features/auth/presentation/bloc/auth_state.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_event.dart';
import 'package:task_sync/features/workspace/presentation/bloc/workspace_bloc.dart';
import 'package:task_sync/features/workspace/presentation/bloc/workspace_event.dart';

class TaskSyncApp extends StatelessWidget {
  const TaskSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = sl<AuthBloc>();
    final taskBloc = sl<TaskBloc>();
    final workspaceBloc = sl<WorkspaceBloc>();

    return BlocProvider(
      create: (_) => sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          final isDark = themeState.mode == AppTheme.dark;
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: authBloc),
              BlocProvider.value(value: taskBloc),
              BlocProvider.value(value: workspaceBloc),
            ],
            child: BlocListener<AuthBloc, AuthState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status,
              listener: (context, state) {
                if (state.status == AuthStatus.authenticated) {
                  context.read<TaskBloc>().add(const TaskBoardSubcsribed());
                  context.read<WorkspaceBloc>().add(
                    const WorkspaceLoadRequested(),
                  );
                }
                if (state.status == AuthStatus.unauthenticated) {
                  context.read<TaskBloc>().add(const TasksPurged());
                  context.read<WorkspaceBloc>().add(const WorkspacePurged());
                }
              },
              child: MaterialApp.router(
                title: 'TaskSync',
                theme: ThemeData(
                  colorSchemeSeed: Colors.indigo,
                  useMaterial3: true,
                ),
                darkTheme: ThemeData.dark(useMaterial3: true),
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                routerConfig: createRouter(authBloc),
              ),
            ),
          );
        },
      ),
    );
  }
}
