import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart'; // Import for UserRole enum

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? username; // Unique Instagram-like username
  final String? photoURL;
  final String? bio;
  final String? department;
  final String? institution;
  final String? designation;
  final String? affiliation;
  final String? website;
  final UserRole role;
  final List<String> interests;
  final List<String> researchInterests;
  final List<String> followers;
  final List<String> following;
  final List<String> bookmarkedPapers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEmailVerified;
  final bool hasCompletedOnboarding;
  final bool hasPublicProfile; // Auto-generated when user uploads public paper

  // Compatibility properties
  String get id => uid;
  String get name => displayName;
  String? get profileImageUrl => photoURL;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.username,
    this.photoURL,
    this.bio,
    this.department,
    this.institution,
    this.designation,
    this.affiliation,
    this.website,
    this.role = UserRole.student,
    this.interests = const [],
    this.researchInterests = const [],
    this.followers = const [],
    this.following = const [],
    this.bookmarkedPapers = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isEmailVerified = false,
    this.hasCompletedOnboarding = false,
    this.hasPublicProfile = false,
  });

  // Create AppUser from Firebase Auth User
  factory AppUser.fromFirebaseUser(
    String uid,
    String email,
    String displayName, {
    bool isEmailVerified = false,
    UserRole role = UserRole.student,
  }) {
    // Generate username from email (user_emailname123)
    final emailName =
        email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final username =
        emailName.length > 20 ? emailName.substring(0, 20) : emailName;

    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      username: username,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isEmailVerified: isEmailVerified,
      hasCompletedOnboarding: false,
      hasPublicProfile: false,
    );
  }

  // Create AppUser from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      username: data['username'],
      photoURL: data['photoURL'],
      bio: data['bio'],
      department: data['department'],
      institution: data['institution'],
      designation: data['designation'],
      affiliation: data['affiliation'],
      website: data['website'],
      role: _parseUserRole(data['role']),
      interests: List<String>.from(data['interests'] ?? []),
      researchInterests: List<String>.from(data['researchInterests'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      bookmarkedPapers: List<String>.from(data['bookmarkedPapers'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isEmailVerified: data['isEmailVerified'] ?? false,
      hasCompletedOnboarding: data['hasCompletedOnboarding'] ?? false,
      hasPublicProfile: data['hasPublicProfile'] ?? false,
    );
  }

  static UserRole _parseUserRole(dynamic value) {
    if (value == null) return UserRole.student;
    if (value is String) {
      return UserRole.values.firstWhere(
        (e) => e.toString() == value || e.name == value,
        orElse: () => UserRole.student,
      );
    }
    return UserRole.student;
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'photoURL': photoURL,
      'bio': bio,
      'department': department,
      'institution': institution,
      'designation': designation,
      'affiliation': affiliation,
      'website': website,
      'role': role.name,
      'interests': interests,
      'researchInterests': researchInterests,
      'followers': followers,
      'following': following,
      'bookmarkedPapers': bookmarkedPapers,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isEmailVerified': isEmailVerified,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hasPublicProfile': hasPublicProfile,
    };
  }

  // Create a copy with updated fields
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    String? photoURL,
    String? bio,
    String? department,
    String? institution,
    String? designation,
    String? affiliation,
    String? website,
    UserRole? role,
    List<String>? interests,
    List<String>? researchInterests,
    List<String>? followers,
    List<String>? following,
    List<String>? bookmarkedPapers,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    bool? hasCompletedOnboarding,
    bool? hasPublicProfile,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      department: department ?? this.department,
      institution: institution ?? this.institution,
      designation: designation ?? this.designation,
      affiliation: affiliation ?? this.affiliation,
      website: website ?? this.website,
      role: role ?? this.role,
      interests: interests ?? this.interests,
      researchInterests: researchInterests ?? this.researchInterests,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      bookmarkedPapers: bookmarkedPapers ?? this.bookmarkedPapers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasPublicProfile: hasPublicProfile ?? this.hasPublicProfile,
    );
  }
}
