part of 'task_bloc.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Todo> allTodos;
  final List<Todo> filteredTodos;

  const TaskLoaded({required this.allTodos, required this.filteredTodos});

  @override
  List<Object> get props => [allTodos, filteredTodos];
}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object> get props => [message];
}
