import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced user profile model for social features
class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? username; // Instagram-like unique username (@username)
  final String? photoURL;
  final String? bio;
  final String? institution;
  final String? department;
  final String? position; // Professor, Researcher, Student, etc.
  final List<String> researchInterests;
  final List<String> specializations;

  // Social stats
  final int followersCount;
  final int followingCount;
  final int papersCount;
  final int citationsCount;

  // Social links
  final String? linkedinUrl;
  final String? googleScholarUrl;
  final String? orcidId;
  final String? researchGateUrl;
  final String? websiteUrl;

  // Privacy settings
  final bool isProfilePublic;
  final bool showEmail;
  final bool showInstitution;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastActive;

  // Verification status
  final bool isVerified;
  final String? verificationBadge; // 'faculty', 'researcher', 'institution'

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.username,
    this.photoURL,
    this.bio,
    this.institution,
    this.department,
    this.position,
    this.researchInterests = const [],
    this.specializations = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.papersCount = 0,
    this.citationsCount = 0,
    this.linkedinUrl,
    this.googleScholarUrl,
    this.orcidId,
    this.researchGateUrl,
    this.websiteUrl,
    this.isProfilePublic = true,
    this.showEmail = false,
    this.showInstitution = true,
    required this.createdAt,
    this.updatedAt,
    this.lastActive,
    this.isVerified = false,
    this.verificationBadge,
  });

  /// Create from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Anonymous',
      username: data['username'],
      photoURL: data['photoURL'],
      bio: data['bio'],
      institution: data['institution'],
      department: data['department'],
      position: data['position'],
      researchInterests: List<String>.from(data['researchInterests'] ?? []),
      specializations: List<String>.from(data['specializations'] ?? []),
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      papersCount: data['papersCount'] ?? 0,
      citationsCount: data['citationsCount'] ?? 0,
      linkedinUrl: data['linkedinUrl'],
      googleScholarUrl: data['googleScholarUrl'],
      orcidId: data['orcidId'],
      researchGateUrl: data['researchGateUrl'],
      websiteUrl: data['websiteUrl'],
      isProfilePublic: data['isProfilePublic'] ?? true,
      showEmail: data['showEmail'] ?? false,
      showInstitution: data['showInstitution'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      isVerified: data['isVerified'] ?? false,
      verificationBadge: data['verificationBadge'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'photoURL': photoURL,
      'bio': bio,
      'institution': institution,
      'department': department,
      'position': position,
      'researchInterests': researchInterests,
      'specializations': specializations,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'papersCount': papersCount,
      'citationsCount': citationsCount,
      'linkedinUrl': linkedinUrl,
      'googleScholarUrl': googleScholarUrl,
      'orcidId': orcidId,
      'researchGateUrl': researchGateUrl,
      'websiteUrl': websiteUrl,
      'isProfilePublic': isProfilePublic,
      'showEmail': showEmail,
      'showInstitution': showInstitution,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'isVerified': isVerified,
      'verificationBadge': verificationBadge,
    };
  }

  /// Copy with modifications
  UserProfile copyWith({
    String? displayName,
    String? username,
    String? photoURL,
    String? bio,
    String? institution,
    String? department,
    String? position,
    List<String>? researchInterests,
    List<String>? specializations,
    int? followersCount,
    int? followingCount,
    int? papersCount,
    int? citationsCount,
    String? linkedinUrl,
    String? googleScholarUrl,
    String? orcidId,
    String? researchGateUrl,
    String? websiteUrl,
    bool? isProfilePublic,
    bool? showEmail,
    bool? showInstitution,
    DateTime? updatedAt,
    DateTime? lastActive,
    bool? isVerified,
    String? verificationBadge,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      institution: institution ?? this.institution,
      department: department ?? this.department,
      position: position ?? this.position,
      researchInterests: researchInterests ?? this.researchInterests,
      specializations: specializations ?? this.specializations,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      papersCount: papersCount ?? this.papersCount,
      citationsCount: citationsCount ?? this.citationsCount,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      googleScholarUrl: googleScholarUrl ?? this.googleScholarUrl,
      orcidId: orcidId ?? this.orcidId,
      researchGateUrl: researchGateUrl ?? this.researchGateUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      isProfilePublic: isProfilePublic ?? this.isProfilePublic,
      showEmail: showEmail ?? this.showEmail,
      showInstitution: showInstitution ?? this.showInstitution,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActive: lastActive ?? this.lastActive,
      isVerified: isVerified ?? this.isVerified,
      verificationBadge: verificationBadge ?? this.verificationBadge,
    );
  }
}

/// Follow/Follower relationship model
class FollowRelationship {
  final String id;
  final String followerId; // User who follows
  final String followingId; // User being followed
  final DateTime createdAt;

  const FollowRelationship({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  factory FollowRelationship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FollowRelationship(
      id: doc.id,
      followerId: data['followerId'] ?? '',
      followingId: data['followingId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
