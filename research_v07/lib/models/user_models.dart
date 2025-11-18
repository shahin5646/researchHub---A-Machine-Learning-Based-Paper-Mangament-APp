import 'package:hive/hive.dart';
part 'user_models.g.dart';

@HiveType(typeId: 10)
class User extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String email;
  @HiveField(3)
  final String? profileImageUrl;
  @HiveField(4)
  final UserRole role;
  @HiveField(5)
  final String? department;
  @HiveField(6)
  final String? affiliation;
  @HiveField(7)
  final List<String> researchInterests;
  @HiveField(8)
  final List<String> bookmarkedPapers;
  @HiveField(9)
  final List<String> downloadedPapers;
  @HiveField(10)
  final Map<String, double> paperRatings;
  @HiveField(11)
  final List<String> searchHistory;
  @HiveField(12)
  final UserPreferences preferences;
  @HiveField(13)
  final DateTime createdAt;
  @HiveField(14)
  final DateTime lastLoginAt;
  @HiveField(15)
  final bool isActive;
  @HiveField(16)
  final String? password; // For local authentication
  @HiveField(17)
  final List<String> following; // Users this user follows
  @HiveField(18)
  final List<String> followers; // Users following this user
  @HiveField(19)
  final String? bio; // User biography
  @HiveField(20)
  final String? website; // User website/portfolio

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.role,
    this.department,
    this.affiliation,
    this.researchInterests = const [],
    this.bookmarkedPapers = const [],
    this.downloadedPapers = const [],
    this.paperRatings = const {},
    this.searchHistory = const [],
    required this.preferences,
    required this.createdAt,
    required this.lastLoginAt,
    this.isActive = true,
    this.password,
    this.following = const [],
    this.followers = const [],
    this.bio,
    this.website,
  });

  // Helper methods for social features
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    UserRole? role,
    String? department,
    String? affiliation,
    List<String>? researchInterests,
    List<String>? bookmarkedPapers,
    List<String>? downloadedPapers,
    Map<String, double>? paperRatings,
    List<String>? searchHistory,
    UserPreferences? preferences,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? password,
    List<String>? following,
    List<String>? followers,
    String? bio,
    String? website,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      department: department ?? this.department,
      affiliation: affiliation ?? this.affiliation,
      researchInterests: researchInterests ?? this.researchInterests,
      bookmarkedPapers: bookmarkedPapers ?? this.bookmarkedPapers,
      downloadedPapers: downloadedPapers ?? this.downloadedPapers,
      paperRatings: paperRatings ?? this.paperRatings,
      searchHistory: searchHistory ?? this.searchHistory,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      password: password ?? this.password,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      bio: bio ?? this.bio,
      website: website ?? this.website,
    );
  }
}

@HiveType(typeId: 11)
enum UserRole {
  @HiveField(0)
  student,
  @HiveField(1)
  researcher,
  @HiveField(2)
  faculty,
  @HiveField(3)
  admin,
  @HiveField(4)
  guest,
}

@HiveType(typeId: 12)
class UserPreferences extends HiveObject {
  @HiveField(0)
  final String theme;
  @HiveField(1)
  final String language;
  @HiveField(2)
  final bool emailNotifications;
  @HiveField(3)
  final bool pushNotifications;
  @HiveField(4)
  final List<String> preferredCategories;
  @HiveField(5)
  final int resultsPerPage;
  @HiveField(6)
  final String citationFormat;
  @HiveField(7)
  final bool autoDownload;
  @HiveField(8)
  final Map<String, dynamic> customSettings;

  UserPreferences({
    this.theme = 'system',
    this.language = 'en',
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.preferredCategories = const [],
    this.resultsPerPage = 20,
    this.citationFormat = 'APA',
    this.autoDownload = false,
    this.customSettings = const {},
  });
}
