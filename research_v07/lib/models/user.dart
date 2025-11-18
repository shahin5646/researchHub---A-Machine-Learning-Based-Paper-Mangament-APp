import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String email;

  @HiveField(3)
  String displayName;

  @HiveField(4)
  UserRole role;

  @HiveField(5)
  String? bio;

  @HiveField(6)
  String? profileImagePath;

  @HiveField(7)
  String? department;

  @HiveField(8)
  String? institution;

  @HiveField(9)
  List<String> interests;

  @HiveField(10)
  List<String> following;

  @HiveField(11)
  List<String> followers;

  @HiveField(12)
  int paperCount;

  @HiveField(13)
  int citationCount;

  @HiveField(14)
  DateTime createdAt;

  @HiveField(15)
  DateTime lastLoginAt;

  @HiveField(16)
  bool isActive;

  @HiveField(17)
  bool isVerified;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.role,
    this.bio,
    this.profileImagePath,
    this.department,
    this.institution,
    this.interests = const [],
    this.following = const [],
    this.followers = const [],
    this.paperCount = 0,
    this.citationCount = 0,
    required this.createdAt,
    required this.lastLoginAt,
    this.isActive = true,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'role': role.index,
      'bio': bio,
      'profileImagePath': profileImagePath,
      'department': department,
      'institution': institution,
      'interests': interests,
      'following': following,
      'followers': followers,
      'paperCount': paperCount,
      'citationCount': citationCount,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isActive': isActive,
      'isVerified': isVerified,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      displayName: json['displayName'],
      role: UserRole.values[json['role']],
      bio: json['bio'],
      profileImagePath: json['profileImagePath'],
      department: json['department'],
      institution: json['institution'],
      interests: List<String>.from(json['interests'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      followers: List<String>.from(json['followers'] ?? []),
      paperCount: json['paperCount'] ?? 0,
      citationCount: json['citationCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
      isActive: json['isActive'] ?? true,
      isVerified: json['isVerified'] ?? false,
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    UserRole? role,
    String? bio,
    String? profileImagePath,
    String? department,
    String? institution,
    List<String>? interests,
    List<String>? following,
    List<String>? followers,
    int? paperCount,
    int? citationCount,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      department: department ?? this.department,
      institution: institution ?? this.institution,
      interests: interests ?? this.interests,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      paperCount: paperCount ?? this.paperCount,
      citationCount: citationCount ?? this.citationCount,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

@HiveType(typeId: 1)
enum UserRole {
  @HiveField(0)
  student,
  @HiveField(1)
  professor,
  @HiveField(2)
  researcher,
  @HiveField(3)
  admin,
  @HiveField(4)
  guest,
}

@HiveType(typeId: 2)
class UserSession extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String token;

  @HiveField(2)
  DateTime loginTime;

  @HiveField(3)
  DateTime expiryTime;

  @HiveField(4)
  bool rememberMe;

  UserSession({
    required this.userId,
    required this.token,
    required this.loginTime,
    required this.expiryTime,
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'token': token,
      'loginTime': loginTime.toIso8601String(),
      'expiryTime': expiryTime.toIso8601String(),
      'rememberMe': rememberMe,
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['userId'],
      token: json['token'],
      loginTime: DateTime.parse(json['loginTime']),
      expiryTime: DateTime.parse(json['expiryTime']),
      rememberMe: json['rememberMe'] ?? false,
    );
  }
}

@HiveType(typeId: 3)
class UserPreferences extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  bool enableNotifications;

  @HiveField(2)
  bool enableEmailNotifications;

  @HiveField(3)
  String themeMode;

  @HiveField(4)
  String language;

  @HiveField(5)
  List<String> blockedUsers;

  @HiveField(6)
  bool showProfile;

  @HiveField(7)
  bool allowFollows;

  UserPreferences({
    required this.userId,
    this.enableNotifications = true,
    this.enableEmailNotifications = true,
    this.themeMode = 'light',
    this.language = 'en',
    this.blockedUsers = const [],
    this.showProfile = true,
    this.allowFollows = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'enableNotifications': enableNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'themeMode': themeMode,
      'language': language,
      'blockedUsers': blockedUsers,
      'showProfile': showProfile,
      'allowFollows': allowFollows,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'],
      enableNotifications: json['enableNotifications'] ?? true,
      enableEmailNotifications: json['enableEmailNotifications'] ?? true,
      themeMode: json['themeMode'] ?? 'light',
      language: json['language'] ?? 'en',
      blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
      showProfile: json['showProfile'] ?? true,
      allowFollows: json['allowFollows'] ?? true,
    );
  }
}
