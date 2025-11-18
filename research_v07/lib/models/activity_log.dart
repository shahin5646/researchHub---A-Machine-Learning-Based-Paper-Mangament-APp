import 'package:hive/hive.dart';

part 'activity_log.g.dart';

@HiveType(typeId: 2)
class ActivityLog extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String projectId;
  @HiveField(2)
  final String userId;
  @HiveField(3)
  final String
      action; // e.g., "created", "updated", "commented", "completed task"
  @HiveField(4)
  final DateTime timestamp;
  @HiveField(5)
  final String details;

  ActivityLog({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.action,
    required this.timestamp,
    this.details = '',
  });
}
