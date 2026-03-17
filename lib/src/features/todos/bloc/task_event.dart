part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object> get props => [];
}

class LoadTasks extends TaskEvent {}

class AddTask extends TaskEvent {
  final Todo todo;

  const AddTask(this.todo);

  @override
  List<Object> get props => [todo];
}

class ToggleTaskCompletion extends TaskEvent {
  final int id;
  final bool isCompleted;

  const ToggleTaskCompletion(this.id, this.isCompleted);

  @override
  List<Object> get props => [id, isCompleted];
}

class DeleteTask extends TaskEvent {
  final int id;

  const DeleteTask(this.id);

  @override
  List<Object> get props => [id];
}

class SearchTasks extends TaskEvent {
  final String query;

  const SearchTasks(this.query);

  @override
  List<Object> get props => [query];
}

class SyncTasks extends TaskEvent {}
