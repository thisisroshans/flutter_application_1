part of 'todos_bloc.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object> get props => [];
}

class LoadTodos extends TodoEvent {}

class AddTodo extends TodoEvent {
  final Todo todo;

  const AddTodo(this.todo);

  @override
  List<Object> get props => [todo];
}

class ToggleTodoCompletion extends TodoEvent {
  final int id;
  final bool isCompleted;

  const ToggleTodoCompletion(this.id, this.isCompleted);

  @override
  List<Object> get props => [id, isCompleted];
}

class DeleteTodo extends TodoEvent {
  final int id;

  const DeleteTodo(this.id);

  @override
  List<Object> get props => [id];
}

class SearchTodos extends TodoEvent {
  final String query;

  const SearchTodos(this.query);

  @override
  List<Object> get props => [query];
}

class SyncTodos extends TodoEvent {}
