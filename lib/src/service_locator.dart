import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/api/api_client.dart';
import 'core/local_storage/local_cache_service.dart';
import 'core/network/network_info.dart';

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/repository/auth_repository.dart';
import 'features/todos/bloc/todos_bloc.dart';
import 'features/todos/data/todos_repository.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  sl.registerLazySingleton(() => Connectivity());

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton(() => LocalCacheService());

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(),
  );

  sl.registerLazySingleton<TodoRepository>(
    () => TodoRepository(
      apiClient: sl(),
      localCacheService: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl()),
  );

  sl.registerFactory<TodoBloc>(
    () => TodoBloc(todoRepository: sl()),
  );
}
