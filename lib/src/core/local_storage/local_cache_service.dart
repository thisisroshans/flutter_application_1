import 'package:hive_flutter/hive_flutter.dart';
import '../../features/todos/data/models/todo.dart';

class LocalCacheService {
  static const String _todosBoxName = 'todos';
  static const String _offlineActionsBoxName = 'offline_actions';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TodoAdapter());
    await Hive.openBox<Todo>(_todosBoxName);
    await Hive.openBox<Map<String, dynamic>>(_offlineActionsBoxName);
  }

  // Todos
  Future<void> saveTodos(List<Todo> todos) async {
    final box = Hive.box<Todo>(_todosBoxName);
    await box.clear();
    await box.addAll(todos);
  }

  Future<List<Todo>> getTodos() async {
    final box = Hive.box<Todo>(_todosBoxName);
    return box.values.toList();
  }

  Future<void> saveTodo(Todo todo) async {
    final box = Hive.box<Todo>(_todosBoxName);
    await box.put(todo.id, todo);
  }

  Future<void> deleteTodo(int id) async {
    final box = Hive.box<Todo>(_todosBoxName);
    await box.delete(id);
  }

  // Offline Actions
  Future<void> queueAction(Map<String, dynamic> action) async {
    final box = Hive.box<Map<String, dynamic>>(_offlineActionsBoxName);
    await box.add(action);
  }

  Future<List<Map<String, dynamic>>> getQueuedActions() async {
    final box = Hive.box<Map<String, dynamic>>(_offlineActionsBoxName);
    return box.values.toList();
  }

  Future<void> clearQueuedActions() async {
    final box = Hive.box<Map<String, dynamic>>(_offlineActionsBoxName);
    await box.clear();
  }
}
