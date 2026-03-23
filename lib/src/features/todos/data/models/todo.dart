import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'todo.g.dart';

@HiveType(typeId: 0)
class Todo extends Equatable {
  @HiveField(0)
  final int id;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final bool completed;

  const Todo({
    required this.id,
    required this.title,
    required this.completed,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'Untitled',
      completed: json['completed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': 1,
      'id': id,
      'title': title,
      'completed': completed,
    };
  }

  @override
  List<Object?> get props => [id, title, completed];
}
