import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/todo.dart';
import '../data/todos_repository.dart';

part 'todos_event.dart';
part 'todos_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository _todoRepository;
  String _currentSearchQuery = '';

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

  // apply the current search filter
  List<Todo> _applySearchFilter(List<Todo> todos) {
    if (_currentSearchQuery.isEmpty) return todos;
    return todos
        .where((todo) => todo.title
            .toLowerCase()
            .contains(_currentSearchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    emit(TodoLoading());
    try {
      final todos = await _todoRepository.getTodos();
      emit(TodoLoaded(
          allTodos: todos, filteredTodos: _applySearchFilter(todos)));
    } catch (e) {
      emit(TodoError("Failed to load todos: ${e.toString()}"));
    }
  }

  Future<void> _onAddTodo(AddTodo event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
      final optimisticState = List<Todo>.from(currentState.allTodos)
        ..insert(0, event.todo);

      emit(TodoLoaded(
          allTodos: optimisticState,
          filteredTodos: _applySearchFilter(optimisticState)));

      try {
        await _todoRepository.createTodo(event.todo);
      } catch (e, stackTrace) {
        final revertedState = List<Todo>.from(currentState.allTodos)
          ..remove(event.todo);
        emit(TodoLoaded(
            allTodos: revertedState,
            filteredTodos: _applySearchFilter(revertedState)));
        debugPrint('--- ADD TODO FAILED ---');
        debugPrint(e.toString());
        debugPrint(stackTrace.toString());
        emit(TodoError("Failed to add Todo: $e"));
      }
    }
  }

  Future<void> _onToggleTodoCompletion(
      ToggleTodoCompletion event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
      final originalTodos = List<Todo>.from(currentState.allTodos);
      final todoIndex = originalTodos.indexWhere((t) => t.id == event.id);
      if (todoIndex == -1) return;

      final todo = originalTodos[todoIndex];
      final updatedTodo =
          Todo(id: todo.id, title: todo.title, completed: event.isCompleted);

      final optimisticTodos = List<Todo>.from(originalTodos);
      optimisticTodos[todoIndex] = updatedTodo;

      emit(TodoLoaded(
          allTodos: optimisticTodos,
          filteredTodos: _applySearchFilter(optimisticTodos)));

      try {
        await _todoRepository.updateTodo(event.id, event.isCompleted);
      } catch (e) {
        emit(TodoLoaded(
            allTodos: originalTodos,
            filteredTodos: _applySearchFilter(originalTodos)));
        emit(TodoError("Failed to update Todo. Reverted changes."));
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
      emit(TodoLoaded(
          allTodos: optimisticTodos,
          filteredTodos: _applySearchFilter(optimisticTodos)));

      try {
        await _todoRepository.deleteTodo(event.id);
      } catch (e) {
        emit(TodoLoaded(
            allTodos: originalTodos,
            filteredTodos: _applySearchFilter(originalTodos)));
        emit(TodoError("Failed to delete Todo. Reverted changes."));
      }
    }
  }

  void _onSearchTodos(SearchTodos event, Emitter<TodoState> emit) {
    if (state is TodoLoaded) {
      _currentSearchQuery = event.query;
      final currentState = state as TodoLoaded;
      emit(TodoLoaded(
        allTodos: currentState.allTodos,
        filteredTodos: _applySearchFilter(currentState.allTodos),
      ));
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
