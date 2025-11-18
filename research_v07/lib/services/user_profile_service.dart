import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../models/app_user.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('UserProfileService');

  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create user profile in Firestore
  Future<void> createUserProfile(AppUser user) async {
    try {
      _logger.info('Creating user profile for: ${user.uid}');
      await _usersCollection.doc(user.uid).set(user.toFirestore());
      _logger.info('User profile created successfully');
    } catch (e) {
      _logger.severe('Error creating user profile: $e');
      rethrow;
    }
  }

  // Get user profile from Firestore
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      _logger.info('Fetching user profile for: $uid');
      final doc = await _usersCollection.doc(uid).get();

      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logger.severe('Error fetching user profile: $e');
      rethrow;
    }
  }

  // Get user profile stream
  Stream<AppUser?> getUserProfileStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    });
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      _logger.info('Updating user profile for: $uid');
      data['updatedAt'] = Timestamp.now();
      await _usersCollection.doc(uid).update(data);
      _logger.info('User profile updated successfully');
    } catch (e) {
      _logger.severe('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update specific fields
  Future<void> updateDisplayName(String uid, String displayName) async {
    await updateUserProfile(uid, {'displayName': displayName});
  }

  Future<void> updateBio(String uid, String bio) async {
    await updateUserProfile(uid, {'bio': bio});
  }

  Future<void> updateDepartment(String uid, String department) async {
    await updateUserProfile(uid, {'department': department});
  }

  Future<void> updateInstitution(String uid, String institution) async {
    await updateUserProfile(uid, {'institution': institution});
  }

  Future<void> updateDesignation(String uid, String designation) async {
    await updateUserProfile(uid, {'designation': designation});
  }

  Future<void> updatePhotoURL(String uid, String photoURL) async {
    await updateUserProfile(uid, {'photoURL': photoURL});
  }

  Future<void> updateInterests(String uid, List<String> interests) async {
    await updateUserProfile(uid, {'interests': interests});
  }

  // Bookmark management
  Future<void> bookmarkPaper(String uid, String paperId) async {
    try {
      _logger.info('Bookmarking paper $paperId for user $uid');
      await _usersCollection.doc(uid).update({
        'bookmarkedPapers': FieldValue.arrayUnion([paperId])
      });
      _logger.info('Paper bookmarked successfully');
    } catch (e) {
      _logger.severe('Error bookmarking paper: $e');
      rethrow;
    }
  }

  Future<void> unbookmarkPaper(String uid, String paperId) async {
    try {
      _logger.info('Unbookmarking paper $paperId for user $uid');
      await _usersCollection.doc(uid).update({
        'bookmarkedPapers': FieldValue.arrayRemove([paperId])
      });
      _logger.info('Paper unbookmarked successfully');
    } catch (e) {
      _logger.severe('Error unbookmarking paper: $e');
      rethrow;
    }
  }

  Future<bool> isPaperBookmarked(String uid, String paperId) async {
    try {
      final user = await getUserProfile(uid);
      return user?.bookmarkedPapers.contains(paperId) ?? false;
    } catch (e) {
      _logger.severe('Error checking bookmark status: $e');
      return false;
    }
  }

  // Follow/Unfollow functionality
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      _logger.info('$currentUserId following $targetUserId');

      final batch = _firestore.batch();

      // Add to current user's following list
      batch.update(_usersCollection.doc(currentUserId), {
        'following': FieldValue.arrayUnion([targetUserId])
      });

      // Add to target user's followers list
      batch.update(_usersCollection.doc(targetUserId), {
        'followers': FieldValue.arrayUnion([currentUserId])
      });

      await batch.commit();
      _logger.info('Follow operation successful');
    } catch (e) {
      _logger.severe('Error following user: $e');
      rethrow;
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      _logger.info('$currentUserId unfollowing $targetUserId');

      final batch = _firestore.batch();

      // Remove from current user's following list
      batch.update(_usersCollection.doc(currentUserId), {
        'following': FieldValue.arrayRemove([targetUserId])
      });

      // Remove from target user's followers list
      batch.update(_usersCollection.doc(targetUserId), {
        'followers': FieldValue.arrayRemove([currentUserId])
      });

      await batch.commit();
      _logger.info('Unfollow operation successful');
    } catch (e) {
      _logger.severe('Error unfollowing user: $e');
      rethrow;
    }
  }

  // Get followers
  Future<List<AppUser>> getFollowers(String uid) async {
    try {
      final user = await getUserProfile(uid);
      if (user == null || user.followers.isEmpty) return [];

      final followers = <AppUser>[];
      for (final followerId in user.followers) {
        final follower = await getUserProfile(followerId);
        if (follower != null) followers.add(follower);
      }
      return followers;
    } catch (e) {
      _logger.severe('Error fetching followers: $e');
      return [];
    }
  }

  // Get following
  Future<List<AppUser>> getFollowing(String uid) async {
    try {
      final user = await getUserProfile(uid);
      if (user == null || user.following.isEmpty) return [];

      final following = <AppUser>[];
      for (final followingId in user.following) {
        final followedUser = await getUserProfile(followingId);
        if (followedUser != null) following.add(followedUser);
      }
      return following;
    } catch (e) {
      _logger.severe('Error fetching following: $e');
      return [];
    }
  }

  // Search users by name or email
  Future<List<AppUser>> searchUsers(String query) async {
    try {
      _logger.info('Searching users with query: $query');

      final querySnapshot = await _usersCollection
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error searching users: $e');
      return [];
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      _logger.info('Deleting user profile for: $uid');
      await _usersCollection.doc(uid).delete();
      _logger.info('User profile deleted successfully');
    } catch (e) {
      _logger.severe('Error deleting user profile: $e');
      rethrow;
    }
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      _logger.severe('Error checking if user exists: $e');
      return false;
    }
  }

  // Public profile management
  Future<void> enablePublicProfile(String uid) async {
    try {
      _logger.info('Enabling public profile for: $uid');
      await _usersCollection.doc(uid).update({
        'hasPublicProfile': true,
        'updatedAt': Timestamp.now(),
      });
      _logger.info('Public profile enabled successfully');
    } catch (e) {
      _logger.severe('Error enabling public profile: $e');
      rethrow;
    }
  }

  // Get all users with public profiles
  Future<List<AppUser>> getPublicProfiles({
    int limit = 50,
    String? lastUserId,
  }) async {
    try {
      Query query = _usersCollection
          .where('hasPublicProfile', isEqualTo: true)
          .orderBy('displayName')
          .limit(limit);

      if (lastUserId != null) {
        final lastDoc = await _usersCollection.doc(lastUserId).get();
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.severe('Error fetching public profiles: $e');
      return [];
    }
  }

  // Search public profiles
  Future<List<AppUser>> searchPublicProfiles(String query) async {
    try {
      if (query.isEmpty) return [];

      // Search by display name or username
      final snapshot = await _usersCollection
          .where('hasPublicProfile', isEqualTo: true)
          .orderBy('displayName')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.severe('Error searching public profiles: $e');
      // Try alternate search
      try {
        final snapshot = await _usersCollection
            .where('hasPublicProfile', isEqualTo: true)
            .limit(50)
            .get();

        final results = snapshot.docs
            .map((doc) => AppUser.fromFirestore(doc))
            .where((user) =>
                user.displayName.toLowerCase().contains(query.toLowerCase()) ||
                (user.username?.toLowerCase().contains(query.toLowerCase()) ??
                    false))
            .take(20)
            .toList();

        return results;
      } catch (e2) {
        _logger.severe('Error in alternate search: $e2');
        return [];
      }
    }
  }
}
