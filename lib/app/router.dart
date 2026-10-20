import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:task_sync/app/di/injection.dart';
import 'package:task_sync/core/theme/cubit/theme_cubit.dart';
import 'package:task_sync/core/theme/cubit/theme_state.dart';
import 'package:task_sync/core/widgets/empty_state.dart';
import 'package:task_sync/core/widgets/error_view.dart';
import 'package:task_sync/core/widgets/task_card.dart';
import 'package:task_sync/features/auth/domain/entities/user.dart';
import 'package:task_sync/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:task_sync/features/auth/presentation/bloc/auth_event.dart';
import 'package:task_sync/features/auth/presentation/bloc/auth_state.dart';
import 'package:task_sync/features/auth/presentation/pages/login_page.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_event.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_state.dart';
import 'package:task_sync/features/tasks/presentation/pages/task_board_page.dart';

String? authRedirect(AuthStatus status, String matchedLocation) {
  if (status == AuthStatus.unauthenticated &&
      !matchedLocation.startsWith('/login')) {
    return '/login';
  }
  if (status == AuthStatus.authenticated &&
      matchedLocation.startsWith('/login')) {
    return '/board';
  }
  return null;
}

bool isRoleAllowed(User? user, String requiredRole) {
  if (user == null) return false;
  if (requiredRole != 'admin') return true;
  return user.role == 'admin';
}

class AuthRefreshListenable extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;
  AuthRefreshListenable(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: AuthRefreshListenable(authBloc.stream),
    redirect: (context, state) =>
        authRedirect(authBloc.state.status, state.matchedLocation),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/board',
        builder: (context, state) => const TaskBoardPage(),
      ),
    ],
  );
}

// class BoardPreviewPage extends StatelessWidget {
//   const BoardPreviewPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('TaskSync'),
//         actions: [
//           // BlocBuilder<ThemeCubit, ThemeState>(
//           //   builder: (context, state) {
//           //     final isDark = state.mode == AppTheme.dark;
//           //     return IconButton(
//           //       tooltip: isDark
//           //           ? 'Switch to light theme'
//           //           : 'Switch to dark theme',
//           //       onPressed: () => context.read<ThemeCubit>().toggle(),
//           //       icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
//           //     );
//           //   },
//           // ),
//           IconButton(
//             onPressed: () =>
//                 context.read<AuthBloc>().add(const AuthLoggedOut()),
//             icon: const Icon(Icons.logout),
//             tooltip: 'Logout',
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => context.read<TaskBloc>().add(
//           TaskCreated('New task ${DateTime.now().second}'),
//         ),
//         child: const Icon(Icons.add),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: TextField(
//               decoration: const InputDecoration(
//                 prefixIcon: Icon(Icons.search),
//                 hintText: "Search tasks ...",
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (q) =>
//                   context.read<TaskBloc>().add(TaskSearchQueryChanged(q)),
//             ),
//           ),
//           Expanded(
//             child: BlocBuilder<TaskBloc, TaskState>(
//               builder: (context, state) {
//                 switch (state.status) {
//                   case TaskStatus.loading:
//                   case TaskStatus.initial:
//                     return const Center(child: CircularProgressIndicator());
//                   case TaskStatus.saving:
//                     return Stack(
//                       children: [
//                         _TaskList(state: state),
//                         const Align(
//                           alignment: Alignment.topCenter,
//                           child: LinearProgressIndicator(),
//                         ),
//                       ],
//                     );
//                   case TaskStatus.failure:
//                     return ErrorView(
//                       message: state.message ?? 'Failed to load tasks',
//                       onRetry: () => context.read<TaskBloc>().add(
//                         const TaskLoadRequested(),
//                       ),
//                     );
//                   case TaskStatus.loaded:
//                     if (state.tasks.isEmpty) {
//                       return const EmptyState(message: 'No tasks yet');
//                     }
//                     return _TaskList(state: state);
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void showInfo(BuildContext context, String message) {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Text('$message (dispatched by the Bloc, not the widget)'),
//         ),
//       );
//   }
// }

// class _TaskList extends StatelessWidget {
//   final TaskState state;

//   const _TaskList({required this.state});

//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       padding: const EdgeInsets.all(12),
//       children: [
//         for (final t in state.tasks)
//           Dismissible(
//             key: ValueKey(t.id),
//             background: Container(color: Colors.red),
//             onDismissed: (_) => context.read<TaskBloc>().add(TaskDeleted(t.id)),
//             child: TaskCard(
//               title: t.title,
//               column: t.column,
//               isSyncing: t.isSyncing,
//               onTap: () => context.read<TaskBloc>().add(
//                 TaskMarkedDone(id: t.id, isDone: !t.isDone),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

// class _SectionCard extends StatelessWidget {
//   final String title;
//   final Widget child;

//   const _SectionCard({required this.title, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title, style: Theme.of(context).textTheme.titleMedium),
//             const SizedBox(height: 12),
//             child,
//           ],
//         ),
//       ),
//     );
//   }
// }
