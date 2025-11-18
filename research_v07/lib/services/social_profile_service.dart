import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logging/logging.dart';
import 'dart:io';
import '../models/user_profile.dart';

/// Service for managing enhanced user profiles and social features
class SocialProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger('SocialProfileService');

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection('user_profiles').doc(userId).get();

      if (!doc.exists) {
        _logger.warning('User profile not found: $userId');
        return null;
      }

      return UserProfile.fromFirestore(doc);
    } catch (e) {
      _logger.severe('Error getting user profile: $e');
      return null;
    }
  }

  /// Stream user profile
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _firestore
        .collection('user_profiles')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  /// Create or update user profile
  Future<void> updateUserProfile(String userId, UserProfile profile) async {
    try {
      await _firestore
          .collection('user_profiles')
          .doc(userId)
          .set(profile.toFirestore(), SetOptions(merge: true));

      _logger.info('User profile updated: $userId');
    } catch (e) {
      _logger.severe('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Upload profile picture
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      _logger.info('Uploading profile picture for user: $userId');

      final ref = _storage.ref().child('profiles/$userId/avatar.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update profile with new photo URL
      await _firestore.collection('user_profiles').doc(userId).update({
        'photoURL': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.info('Profile picture uploaded successfully');
      return downloadUrl;
    } catch (e) {
      _logger.severe('Error uploading profile picture: $e');
      rethrow;
    }
  }

  /// Update bio
  Future<void> updateBio(String userId, String bio) async {
    try {
      await _firestore.collection('user_profiles').doc(userId).update({
        'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.severe('Error updating bio: $e');
      rethrow;
    }
  }

  /// Update research interests
  Future<void> updateResearchInterests(
      String userId, List<String> interests) async {
    try {
      await _firestore.collection('user_profiles').doc(userId).update({
        'researchInterests': interests,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.severe('Error updating research interests: $e');
      rethrow;
    }
  }

  /// Update social links
  Future<void> updateSocialLinks(
      String userId, Map<String, String?> links) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (links.containsKey('linkedin'))
        updates['linkedinUrl'] = links['linkedin'];
      if (links.containsKey('googleScholar'))
        updates['googleScholarUrl'] = links['googleScholar'];
      if (links.containsKey('orcid')) updates['orcidId'] = links['orcid'];
      if (links.containsKey('researchGate'))
        updates['researchGateUrl'] = links['researchGate'];
      if (links.containsKey('website'))
        updates['websiteUrl'] = links['website'];

      await _firestore.collection('user_profiles').doc(userId).update(updates);
    } catch (e) {
      _logger.severe('Error updating social links: $e');
      rethrow;
    }
  }

  /// Follow a user
  Future<void> followUser(String followerId, String followingId) async {
    if (followerId == followingId) {
      throw Exception('Cannot follow yourself');
    }

    try {
      final batch = _firestore.batch();

      // Create follow relationship
      final followRef =
          _firestore.collection('follows').doc('${followerId}_$followingId');

      batch.set(followRef, {
        'followerId': followerId,
        'followingId': followingId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment follower's following count
      final followerRef =
          _firestore.collection('user_profiles').doc(followerId);
      batch.update(followerRef, {
        'followingCount': FieldValue.increment(1),
      });

      // Increment following user's followers count
      final followingRef =
          _firestore.collection('user_profiles').doc(followingId);
      batch.update(followingRef, {
        'followersCount': FieldValue.increment(1),
      });

      await batch.commit();
      _logger.info('User $followerId followed $followingId');
    } catch (e) {
      _logger.severe('Error following user: $e');
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      final batch = _firestore.batch();

      // Delete follow relationship
      final followRef =
          _firestore.collection('follows').doc('${followerId}_$followingId');

      batch.delete(followRef);

      // Decrement follower's following count
      final followerRef =
          _firestore.collection('user_profiles').doc(followerId);
      batch.update(followerRef, {
        'followingCount': FieldValue.increment(-1),
      });

      // Decrement following user's followers count
      final followingRef =
          _firestore.collection('user_profiles').doc(followingId);
      batch.update(followingRef, {
        'followersCount': FieldValue.increment(-1),
      });

      await batch.commit();
      _logger.info('User $followerId unfollowed $followingId');
    } catch (e) {
      _logger.severe('Error unfollowing user: $e');
      rethrow;
    }
  }

  /// Check if user is following another user
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final doc = await _firestore
          .collection('follows')
          .doc('${followerId}_$followingId')
          .get();

      return doc.exists;
    } catch (e) {
      _logger.severe('Error checking follow status: $e');
      return false;
    }
  }

  /// Get followers list
  Future<List<UserProfile>> getFollowers(String userId,
      {int limit = 50}) async {
    try {
      final followsSnapshot = await _firestore
          .collection('follows')
          .where('followingId', isEqualTo: userId)
          .limit(limit)
          .get();

      final followerIds = followsSnapshot.docs
          .map((doc) => doc.data()['followerId'] as String)
          .toList();

      if (followerIds.isEmpty) return [];

      // Get user profiles
      final profiles = <UserProfile>[];
      for (var id in followerIds) {
        final profile = await getUserProfile(id);
        if (profile != null) profiles.add(profile);
      }

      return profiles;
    } catch (e) {
      _logger.severe('Error getting followers: $e');
      return [];
    }
  }

  /// Get following list
  Future<List<UserProfile>> getFollowing(String userId,
      {int limit = 50}) async {
    try {
      final followsSnapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .limit(limit)
          .get();

      final followingIds = followsSnapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      // Get user profiles
      final profiles = <UserProfile>[];
      for (var id in followingIds) {
        final profile = await getUserProfile(id);
        if (profile != null) profiles.add(profile);
      }

      return profiles;
    } catch (e) {
      _logger.severe('Error getting following: $e');
      return [];
    }
  }

  /// Search users by name or interests
  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    try {
      _logger.info('Searching users: $query');

      final snapshot = await _firestore
          .collection('user_profiles')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
          .where('isProfilePublic', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error searching users: $e');
      return [];
    }
  }

  /// Get users by research interest
  Future<List<UserProfile>> getUsersByInterest(String interest,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('user_profiles')
          .where('researchInterests', arrayContains: interest)
          .where('isProfilePublic', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error getting users by interest: $e');
      return [];
    }
  }

  /// Update last active timestamp
  Future<void> updateLastActive(String userId) async {
    try {
      await _firestore.collection('user_profiles').doc(userId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.warning('Error updating last active: $e');
    }
  }

  /// Get recommended users (users with similar research interests)
  Future<List<UserProfile>> getRecommendedUsers(
    String userId,
    List<String> userInterests, {
    int limit = 10,
  }) async {
    try {
      if (userInterests.isEmpty) return [];

      final snapshot = await _firestore
          .collection('user_profiles')
          .where('researchInterests',
              arrayContainsAny: userInterests.take(10).toList())
          .where('isProfilePublic', isEqualTo: true)
          .limit(limit + 1) // +1 to account for current user
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .where((profile) => profile.id != userId) // Exclude current user
          .take(limit)
          .toList();
    } catch (e) {
      _logger.severe('Error getting recommended users: $e');
      return [];
    }
  }

  /// Update profile privacy settings
  Future<void> updatePrivacySettings(
    String userId, {
    bool? isProfilePublic,
    bool? showEmail,
    bool? showInstitution,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isProfilePublic != null) updates['isProfilePublic'] = isProfilePublic;
      if (showEmail != null) updates['showEmail'] = showEmail;
      if (showInstitution != null) updates['showInstitution'] = showInstitution;

      await _firestore.collection('user_profiles').doc(userId).update(updates);
    } catch (e) {
      _logger.severe('Error updating privacy settings: $e');
      rethrow;
    }
  }
}
