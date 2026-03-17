import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/todo.dart';
import '../data/todos_repository.dart';

part 'todos_event.dart';
part 'todos_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository _todoRepository;

  TodoBloc({required TodoRepository todoRepository})
    : _todoRepository = todoRepository,
      super(TodoInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    on<ToggleTodoCompletion>(_onToggleTodoCompletion);
    on<DeleteTodo>(_onDeleteTodo);
    on<SearchTodos>(_onSearchTodos);
    on<SyncTodos>(_onSyncTodos);
  }

  Future<void> _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    emit(TodoLoading());
    try {
      final todos = await _todoRepository.getTodos();
      emit(TodoLoaded(allTodos: todos, filteredTodos: todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onAddTodo(AddTodo event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
      final optimisticState = currentState.allTodos..add(event.todo);
      emit(
        TodoLoaded(allTodos: optimisticState, filteredTodos: optimisticState),
      );
      try {
        await _todoRepository.createTodo(event.todo);
      } catch (e) {
        final currentState = state as TodoLoaded;
        final revertedState = currentState.allTodos..remove(event.todo);
        emit(TodoLoaded(allTodos: revertedState, filteredTodos: revertedState));
        emit(TodoError("Failed to add Todo: ${e.toString()}"));
      }
    }
  }

  Future<void> _onToggleTodoCompletion(
    ToggleTodoCompletion event,
    Emitter<TodoState> emit,
  ) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
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
        TodoLoaded(allTodos: optimisticTodos, filteredTodos: optimisticTodos),
      );

      try {
        await _todoRepository.updateTodo(event.id, event.isCompleted);
      } catch (e) {
        emit(TodoLoaded(allTodos: originalTodos, filteredTodos: originalTodos));
        emit(TodoError("Failed to update Todo: ${e.toString()}"));
      }
    }
  }

  Future<void> _onDeleteTodo(DeleteTodo event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
      final originalTodos = List<Todo>.from(currentState.allTodos);
      final todoToDelete = originalTodos.firstWhere((t) => t.id == event.id);

      final optimisticTodos = List<Todo>.from(originalTodos)
        ..remove(todoToDelete);
      emit(
        TodoLoaded(allTodos: optimisticTodos, filteredTodos: optimisticTodos),
      );
      try {
        await _todoRepository.deleteTodo(event.id);
      } catch (e) {
        emit(TodoLoaded(allTodos: originalTodos, filteredTodos: originalTodos));
        emit(TodoError("Failed to delete Todo: ${e.toString()}"));
      }
    }
  }

  void _onSearchTodos(SearchTodos event, Emitter<TodoState> emit) {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
      final filteredTodos = currentState.allTodos
          .where(
            (todo) =>
                todo.title.toLowerCase().contains(event.query.toLowerCase()),
          )
          .toList();
      emit(
        TodoLoaded(
          allTodos: currentState.allTodos,
          filteredTodos: filteredTodos,
        ),
      );
    }
  }

  Future<void> _onSyncTodos(SyncTodos event, Emitter<TodoState> emit) async {
    try {
      await _todoRepository.syncPendingChanges();
      add(LoadTodos());
    } catch (e) {
      emit(TodoError("Failed to sync Todos: ${e.toString()}"));
    }
  }
}
