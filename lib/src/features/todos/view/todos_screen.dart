import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/task_bloc.dart';
import '../data/models/todo.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  late final TaskBloc _taskBloc;

  @override
  void initState() {
    super.initState();
    _taskBloc = context.read<TaskBloc>();

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _taskBloc.add(SearchTasks(_searchController.text));
    });
  }

  void _showAddTaskBottomSheet() {
    final titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: 'Task title'),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final text = titleController.text.trim();
                if (text.isEmpty) return;

                _taskBloc.add(
                  AddTask(
                    Todo(
                      id: DateTime.now().millisecondsSinceEpoch,
                      userId: 1,
                      title: text,
                      completed: false,
                    ),
                  ),
                );

                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    _taskBloc.add(LoadTasks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: _SearchBar(controller: _searchController),
        ),
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state is TaskLoaded) {
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  itemCount: state.filteredTodos.length,
                  itemBuilder: (_, index) {
                    final todo = state.filteredTodos[index];
                    return _TodoItem(todo: todo);
                  },
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _TodoItem extends StatelessWidget {
  final Todo todo;

  const _TodoItem({required this.todo});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TaskBloc>();

    return ListTile(
      leading: Checkbox(
        value: todo.completed,
        onChanged: (value) {
          if (value != null) {
            bloc.add(ToggleTaskCompletion(todo.id, value));
          }
        },
      ),
      title: Text(todo.title),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => bloc.add(DeleteTask(todo.id)),
      ),
    );
  }
}
