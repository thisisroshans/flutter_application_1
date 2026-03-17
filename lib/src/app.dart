import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/view/login_screen.dart';
import 'features/todos/bloc/task_bloc.dart';
import 'service_locator.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<TaskBloc>()..add(LoadTasks())),
      ],
      child: MaterialApp(
        title: 'Todo App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
