import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/todos_bloc.dart';
import '../data/models/todo.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;

  const TodoItem({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TodoBloc>();
    final isDone = todo.completed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDone
            ? Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
        boxShadow: isDone
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: isDone,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (value) {
              if (value != null) {
                bloc.add(ToggleTodoCompletion(todo.id, value));
              }
            },
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isDone ? FontWeight.normal : FontWeight.w500,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color:
                isDone ? Colors.grey : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded,
              color:
                  Theme.of(context).colorScheme.error.withValues(alpha: 0.8)),
          onPressed: () => bloc.add(DeleteTodo(todo.id)),
        ),
      ),
    );
  }
}
