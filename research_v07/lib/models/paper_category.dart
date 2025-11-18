import 'package:hive/hive.dart';

part 'paper_category.g.dart';

@HiveType(typeId: 1)
class PaperCategory {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String description;
  @HiveField(2)
  final List<String> papers;
  @HiveField(3)
  final String icon;

  PaperCategory({
    required this.name,
    required this.description,
    required this.papers,
    required this.icon,
  });
}
