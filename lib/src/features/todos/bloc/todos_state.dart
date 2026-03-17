part of 'todos_bloc.dart';

abstract class TodoState extends Equatable {
  const TodoState();

  @override
  List<Object> get props => [];
}

class TodoInitial extends TodoState {}

class TodoLoading extends TodoState {}

class TodoLoaded extends TodoState {
  final List<Todo> allTodos;
  final List<Todo> filteredTodos;

  const TodoLoaded({required this.allTodos, required this.filteredTodos});

  @override
  List<Object> get props => [allTodos, filteredTodos];
}

class TodoError extends TodoState {
  final String message;

  const TodoError(this.message);

  @override
  List<Object> get props => [message];
}
