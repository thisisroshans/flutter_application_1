import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/todo.dart';
import '../data/todos_repository.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TodoRepository _todoRepository;

  TaskBloc({required TodoRepository todoRepository})
    : _todoRepository = todoRepository,
      super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<ToggleTaskCompletion>(_onToggleTaskCompletion);
    on<DeleteTask>(_onDeleteTask);
    on<SearchTasks>(_onSearchTasks);
    on<SyncTasks>(_onSyncTasks);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final todos = await _todoRepository.getTodos();
      emit(TaskLoaded(allTodos: todos, filteredTodos: todos));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      final optimisticState = currentState.allTodos..add(event.todo);
      emit(
        TaskLoaded(allTodos: optimisticState, filteredTodos: optimisticState),
      );
      try {
        await _todoRepository.createTodo(event.todo);
      } catch (e) {
        final currentState = state as TaskLoaded;
        final revertedState = currentState.allTodos..remove(event.todo);
        emit(TaskLoaded(allTodos: revertedState, filteredTodos: revertedState));
        emit(TaskError("Failed to add task: ${e.toString()}"));
      }
    }
  }

  Future<void> _onToggleTaskCompletion(
    ToggleTaskCompletion event,
    Emitter<TaskState> emit,
  ) async {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      final originalTodos = List<Todo>.from(currentState.allTodos);
      final todoIndex = originalTodos.indexWhere((t) => t.id == event.id);
      if (todoIndex == -1) return;

      final todo = originalTodos[todoIndex];
      final updatedTodo = Todo(
        id: todo.id,
        userId: todo.userId,
        title: todo.title,
        completed: event.isCompleted,
      );

      final optimisticTodos = List<Todo>.from(originalTodos);
      optimisticTodos[todoIndex] = updatedTodo;

      emit(
        TaskLoaded(allTodos: optimisticTodos, filteredTodos: optimisticTodos),
      );

      try {
        await _todoRepository.updateTodo(event.id, event.isCompleted);
      } catch (e) {
        emit(TaskLoaded(allTodos: originalTodos, filteredTodos: originalTodos));
        emit(TaskError("Failed to update task: ${e.toString()}"));
      }
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      final originalTodos = List<Todo>.from(currentState.allTodos);
      final todoToDelete = originalTodos.firstWhere((t) => t.id == event.id);

      final optimisticTodos = List<Todo>.from(originalTodos)
        ..remove(todoToDelete);
      emit(
        TaskLoaded(allTodos: optimisticTodos, filteredTodos: optimisticTodos),
      );
      try {
        await _todoRepository.deleteTodo(event.id);
      } catch (e) {
        emit(TaskLoaded(allTodos: originalTodos, filteredTodos: originalTodos));
        emit(TaskError("Failed to delete task: ${e.toString()}"));
      }
    }
  }

  void _onSearchTasks(SearchTasks event, Emitter<TaskState> emit) {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      final filteredTodos = currentState.allTodos
          .where(
            (todo) =>
                todo.title.toLowerCase().contains(event.query.toLowerCase()),
          )
          .toList();
      emit(
        TaskLoaded(
          allTodos: currentState.allTodos,
          filteredTodos: filteredTodos,
        ),
      );
    }
  }

  Future<void> _onSyncTasks(SyncTasks event, Emitter<TaskState> emit) async {
    try {
      await _todoRepository.syncPendingChanges();
      add(LoadTasks());
    } catch (e) {
      emit(TaskError("Failed to sync tasks: ${e.toString()}"));
    }
  }
}
