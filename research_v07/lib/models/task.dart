import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String projectId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final String assignedToId;
  @HiveField(5)
  final DateTime dueDate;
  @HiveField(6)
  final String priority; // Low, Medium, High
  @HiveField(7)
  final String status; // To Do, In Progress, Review, Done
  @HiveField(8)
  final List<String> comments;
  @HiveField(9)
  final List<String> subTasks;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.assignedToId,
    required this.dueDate,
    required this.priority,
    required this.status,
    this.comments = const [],
    this.subTasks = const [],
  });
}
