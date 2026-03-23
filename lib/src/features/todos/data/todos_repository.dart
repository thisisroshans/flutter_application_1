import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/local_storage/local_cache_service.dart';
import '../../../core/network/network_info.dart';
import 'models/todo.dart';

class TodoRepository {
  final ApiClient _apiClient;
  final LocalCacheService _localCacheService;
  final NetworkInfo _networkInfo;

  TodoRepository({
    required ApiClient apiClient,
    required LocalCacheService localCacheService,
    required NetworkInfo networkInfo,
  })  : _apiClient = apiClient,
        _localCacheService = localCacheService,
        _networkInfo = networkInfo {
    _networkInfo.isConnected.then((connected) {
      if (connected) {
        syncPendingChanges();
      }
    });
  }

  Future<List<Todo>> getTodos() async {
    if (await _networkInfo.isConnected) {
      final todos = await _apiClient.getTodos();
      await _localCacheService.saveTodos(todos);
      return todos;
    } else {
      return await _localCacheService.getTodos();
    }
  }

  Future<void> createTodo(Todo todo) async {
    await _localCacheService.saveTodo(todo);
    if (await _networkInfo.isConnected) {
      await _apiClient.createTodo(todo);
    } else {
      await _localCacheService.queueAction({
        'type': 'create',
        'data': todo.toJson(),
      });
    }
  }

  Future<void> updateTodo(int id, bool completed) async {
    final todos = await _localCacheService.getTodos();
    final index = todos.indexWhere((element) => element.id == id);
    if (index != -1) {
      final todo = todos[index];
      final updatedTodo = Todo(
        id: todo.id,
        title: todo.title,
        completed: completed,
      );
      await _localCacheService.saveTodo(updatedTodo);
    }

    if (await _networkInfo.isConnected) {
      await _apiClient.updateTodo(id, completed);
    } else {
      await _localCacheService.queueAction({
        'type': 'update',
        'data': {'id': id, 'completed': completed},
      });
    }
  }

  Future<void> deleteTodo(int id) async {
    await _localCacheService.deleteTodo(id);
    if (await _networkInfo.isConnected) {
      await _apiClient.deleteTodo(id);
    } else {
      await _localCacheService.queueAction({
        'type': 'delete',
        'data': {'id': id},
      });
    }
  }

  Future<void> syncPendingChanges() async {
    final actions = await _localCacheService.getQueuedActions();
    if (actions.isEmpty) return;

    for (final action in actions) {
      try {
        await _handleAction(action);
      } catch (e, stack) {
        debugPrint('Sync failed for action: ${action['type']}');
        debugPrint('Error: $e');
        debugPrintStack(stackTrace: stack);
        return;
      }
    }
    await _localCacheService.clearQueuedActions();
  }

  Future<void> _handleAction(Map<String, dynamic> action) async {
    final type = action['type'];
    final data = action['data'];

    switch (type) {
      case 'create':
        await _apiClient.createTodo(Todo.fromJson(data));
        break;
      case 'update':
        await _apiClient.updateTodo(data['id'], data['completed']);
        break;
      case 'delete':
        await _apiClient.deleteTodo(data['id']);
        break;
      default:
        debugPrint('Unknown action type: $type');
    }
  }
}
