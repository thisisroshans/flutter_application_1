import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/api/api_client.dart';
import 'core/local_storage/local_cache_service.dart';
import 'core/network/network_info.dart';
import 'features/todos/bloc/todos_bloc.dart';
import 'features/todos/data/todos_repository.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  // BLoC
  sl.registerFactory(() => TodoBloc(todoRepository: sl()));

  // Repositories
  sl.registerLazySingleton(
    () => TodoRepository(
      apiClient: sl(),
      localCacheService: sl(),
      networkInfo: sl(),
    ),
  );

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton(() => LocalCacheService());
  sl.registerLazySingleton(() => Connectivity());
}
