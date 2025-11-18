import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'category_service.g.dart';

@HiveType(typeId: 10)
class CustomCategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  int iconCodePoint;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  List<int> gradientColors;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String createdBy;

  @HiveField(8)
  bool isActive;

  @HiveField(9)
  int usageCount;

  CustomCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCodePoint,
    required this.colorValue,
    required this.gradientColors,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
    this.usageCount = 0,
  });

  // Helper getters
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);
  List<Color> get gradient => gradientColors.map((c) => Color(c)).toList();

  // Convert to Map for easy use
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'gradient': gradient,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'isActive': isActive,
      'usageCount': usageCount,
    };
  }
}

class CategoryService {
  static const String _boxName = 'custom_categories';
  Box<CustomCategory>? _categoryBox;

  Future<void> initialize() async {
    try {
      // Register adapter if not already registered
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(CustomCategoryAdapter());
      }
      _categoryBox = await Hive.openBox<CustomCategory>(_boxName);
    } catch (e) {
      print('Error initializing CategoryService: $e');
    }
  }

  // Default categories that come with the app
  static List<Map<String, dynamic>> getDefaultCategories() {
    return [
      {
        'id': 'computer_science',
        'name': 'Computer Science',
        'description': 'Software engineering, AI, algorithms, and computing',
        'icon': Icons.computer_rounded,
        'color': const Color(0xFF6366F1),
        'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        'isDefault': true,
      },
      {
        'id': 'engineering',
        'name': 'Engineering',
        'description':
            'Mechanical, electrical, civil, and other engineering fields',
        'icon': Icons.precision_manufacturing_rounded,
        'color': const Color(0xFF10B981),
        'gradient': [const Color(0xFF10B981), const Color(0xFF059669)],
        'isDefault': true,
      },
      {
        'id': 'business',
        'name': 'Business',
        'description': 'Management, economics, finance, and entrepreneurship',
        'icon': Icons.business_center_rounded,
        'color': const Color(0xFFEF4444),
        'gradient': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        'isDefault': true,
      },
      {
        'id': 'science',
        'name': 'Natural Sciences',
        'description': 'Physics, chemistry, biology, and earth sciences',
        'icon': Icons.science_rounded,
        'color': const Color(0xFF8B5CF6),
        'gradient': [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        'isDefault': true,
      },
      {
        'id': 'social_sciences',
        'name': 'Social Sciences',
        'description': 'Psychology, sociology, anthropology, and humanities',
        'icon': Icons.groups_rounded,
        'color': const Color(0xFFF59E0B),
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFEA580C)],
        'isDefault': true,
      },
      {
        'id': 'mathematics',
        'name': 'Mathematics',
        'description': 'Pure and applied mathematics, statistics',
        'icon': Icons.calculate_rounded,
        'color': const Color(0xFF06B6D4),
        'gradient': [const Color(0xFF06B6D4), const Color(0xFF0891B2)],
        'isDefault': true,
      },
      {
        'id': 'medicine',
        'name': 'Medicine & Health',
        'description': 'Medical research, healthcare, and life sciences',
        'icon': Icons.medical_services_rounded,
        'color': const Color(0xFFDC2626),
        'gradient': [const Color(0xFFDC2626), const Color(0xFFB91C1C)],
        'isDefault': true,
      },
      {
        'id': 'education',
        'name': 'Education',
        'description': 'Pedagogy, learning methods, and educational research',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF7C3AED),
        'gradient': [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
        'isDefault': true,
      },
    ];
  }

  // Get all categories (default + custom)
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final categories = <Map<String, dynamic>>[];

    // Add default categories
    categories.addAll(getDefaultCategories());

    // Add custom categories
    if (_categoryBox != null) {
      for (final customCategory in _categoryBox!.values) {
        if (customCategory.isActive) {
          final categoryMap = customCategory.toMap();
          categoryMap['isDefault'] = false;
          categories.add(categoryMap);
        }
      }
    }

    return categories;
  }

  // Create a new custom category
  Future<bool> createCustomCategory({
    required String name,
    required String description,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    required String createdBy,
  }) async {
    try {
      if (_categoryBox == null) await initialize();

      final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      final category = CustomCategory(
        id: id,
        name: name,
        description: description,
        iconCodePoint: icon.codePoint,
        colorValue: color.value,
        gradientColors: gradient.map((c) => c.value).toList(),
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      await _categoryBox!.put(id, category);
      return true;
    } catch (e) {
      print('Error creating custom category: $e');
      return false;
    }
  }

  // Update category usage count
  Future<void> incrementUsageCount(String categoryId) async {
    try {
      if (_categoryBox == null) return;

      final category = _categoryBox!.get(categoryId);
      if (category != null) {
        category.usageCount++;
        await category.save();
      }
    } catch (e) {
      print('Error incrementing usage count: $e');
    }
  }

  // Delete custom category
  Future<bool> deleteCustomCategory(String categoryId) async {
    try {
      if (_categoryBox == null) await initialize();

      final category = _categoryBox!.get(categoryId);
      if (category != null) {
        category.isActive = false;
        await category.save();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting custom category: $e');
      return false;
    }
  }

  // Get popular categories based on usage
  Future<List<Map<String, dynamic>>> getPopularCategories(
      {int limit = 5}) async {
    final allCategories = await getAllCategories();

    // Sort by usage count (custom categories only)
    final customCategories =
        allCategories.where((cat) => cat['isDefault'] != true).toList();

    customCategories
        .sort((a, b) => (b['usageCount'] ?? 0).compareTo(a['usageCount'] ?? 0));

    return customCategories.take(limit).toList();
  }

  // Search categories
  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    if (query.isEmpty) return await getAllCategories();

    final allCategories = await getAllCategories();
    final lowercaseQuery = query.toLowerCase();

    return allCategories.where((category) {
      final name = category['name'].toString().toLowerCase();
      final description = category['description'].toString().toLowerCase();
      return name.contains(lowercaseQuery) ||
          description.contains(lowercaseQuery);
    }).toList();
  }

  // Predefined icon options for custom categories
  static List<IconData> getCategoryIcons() {
    return [
      Icons.science_rounded,
      Icons.computer_rounded,
      Icons.business_center_rounded,
      Icons.school_rounded,
      Icons.medical_services_rounded,
      Icons.engineering_rounded,
      Icons.psychology_rounded,
      Icons.calculate_rounded,
      Icons.architecture_rounded,
      Icons.art_track_rounded,
      Icons.music_note_rounded,
      Icons.sports_soccer_rounded,
      Icons.restaurant_rounded,
      Icons.travel_explore_rounded,
      Icons.eco_rounded,
      Icons.agriculture_rounded,
      Icons.construction_rounded,
      Icons.design_services_rounded,
      Icons.analytics_rounded,
      Icons.security_rounded,
      Icons.public_rounded,
      Icons.language_rounded,
      Icons.history_rounded,
      Icons.gavel_rounded,
      Icons.biotech_rounded,
      Icons.rocket_launch_rounded,
      Icons.psychology_alt_rounded,
      Icons.theater_comedy_rounded,
      Icons.library_books_rounded,
      Icons.camera_alt_rounded,
    ];
  }

  // Predefined color options for custom categories
  static List<Color> getCategoryColors() {
    return [
      const Color(0xFF6366F1), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF10B981), // Green
      const Color(0xFFEF4444), // Red
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF84CC16), // Lime
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFF97316), // Orange
      const Color(0xFF059669), // Emerald
      const Color(0xFFDC2626), // Red
      const Color(0xFF7C3AED), // Purple
      const Color(0xFF0891B2), // Cyan
      const Color(0xFFCA8A04), // Yellow
    ];
  }
}
