import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:task_sync/core/network/connectivity_service.dart';
import 'package:task_sync/core/theme/cubit/theme_cubit.dart';
import 'package:task_sync/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:task_sync/features/auth/data/datasources/in_memory_auth_remote_datasource.dart';
import 'package:task_sync/features/auth/data/datasources/supabase_auth_remote_datasource.dart';
import 'package:task_sync/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:task_sync/features/auth/domain/repositories/auth_repository.dart';
import 'package:task_sync/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:task_sync/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:task_sync/features/tasks/data/datasources/task_supabase_datasource.dart';
import 'package:task_sync/features/tasks/data/repositories/supabase_task_repository.dart';
import 'package:task_sync/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:task_sync/features/tasks/domain/repositories/task_repository.dart';
import 'package:task_sync/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_sync/features/workspace/data/repositories/workspace_reposity_impl.dart';
import 'package:task_sync/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:task_sync/features/workspace/presentation/bloc/workspace_bloc.dart';

final sl = GetIt.instance;

const supabaseUrl = 'https://kqzjjuapaqaeqkwepxxo.supabase.co';
const supabaseAnonKey = 'sb_publishable_IS2M7ojNJ-mXkYrVM8SOLA_jTvtga2B';

bool get supabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

void setupInjection({Box? storeBox, bool useSupabase = false}) {
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerFactory<ThemeCubit>(() => ThemeCubit());

  sl.registerLazySingleton<TaskLocalDatasource>(
    () => TaskLocalDatasource(storeBox),
  );

  sl.registerFactory<TaskBloc>(() => TaskBloc(sl()));

  sl.registerLazySingleton<WorkspaceRepository>(
    () => InMemoryWorkspaceRepository(),
  );
  sl.registerFactory<WorkspaceBloc>(() => WorkspaceBloc(sl()));

  if (useSupabase) {
    sl.registerLazySingleton<TaskSupabaseDatasource>(
      () => TaskSupabaseDatasource(),
    );
    sl.registerLazySingleton<TaskRepository>(
      () => SupabaseTaskRepository(sl()),
    );
    sl.registerLazySingleton<AuthRemoteDatasource>(
      () => SupabaseAuthRemoteDatasource(),
    );
  } else {
    sl.registerLazySingleton<TaskRepository>(
      () => InMemoryTaskRepository(local: sl()),
    );
    sl.registerLazySingleton<AuthRemoteDatasource>(
      () => InMemoryAuthRemoteDatasource(),
    );
  }

  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
}
