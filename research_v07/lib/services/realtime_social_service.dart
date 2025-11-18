import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Real-time social service that provides instant updates for social features
/// This service works with Firebase Firestore to provide real-time updates
class RealtimeSocialService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Toggle like on a paper (Firebase real-time)
  Future<bool> toggleLike({
    required String paperId,
    required String userId,
    required String userName,
  }) async {
    try {
      final paperRef = _firestore.collection('papers').doc(paperId);
      final paperDoc = await paperRef.get();

      if (!paperDoc.exists) return false;

      final reactions =
          paperDoc.data()?['reactions'] as Map<String, dynamic>? ?? {};

      // Toggle like
      if (reactions.containsKey(userId)) {
        // Unlike
        await paperRef.update({
          'reactions.$userId': FieldValue.delete(),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await paperRef.update({
          'reactions.$userId': {
            'userId': userId,
            'userName': userName,
            'type': 'like',
            'createdAt': FieldValue.serverTimestamp(),
          },
          'likesCount': FieldValue.increment(1),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error toggling like: $e');
      return false;
    }
  }

  /// Add comment to a paper (Firebase real-time)
  Future<String?> addComment({
    required String paperId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
  }) async {
    try {
      final commentRef = _firestore
          .collection('papers')
          .doc(paperId)
          .collection('comments')
          .doc();

      final batch = _firestore.batch();

      // Add comment
      batch.set(commentRef, {
        'id': commentRef.id,
        'paperId': paperId,
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
      });

      // Increment comments count
      final paperRef = _firestore.collection('papers').doc(paperId);
      batch.update(paperRef, {
        'commentsCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return commentRef.id;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  /// Get comments stream for real-time updates
  Stream<List<Map<String, dynamic>>> getCommentsStream(String paperId) {
    return _firestore
        .collection('papers')
        .doc(paperId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Toggle follow user (Firebase real-time)
  Future<bool> toggleFollow({
    required String currentUserId,
    required String targetUserId,
  }) async {
    if (currentUserId == targetUserId) return false;

    try {
      // First, ensure both user documents exist
      await _ensureUserDocumentExists(currentUserId);
      await _ensureUserDocumentExists(targetUserId);

      final followRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      final followDoc = await followRef.get();

      if (followDoc.exists) {
        // Unfollow
        final batch = _firestore.batch();

        batch.delete(followRef);

        batch.delete(_firestore
            .collection('users')
            .doc(targetUserId)
            .collection('followers')
            .doc(currentUserId));

        batch.update(_firestore.collection('users').doc(currentUserId), {
          'followingCount': FieldValue.increment(-1),
        });

        batch.update(_firestore.collection('users').doc(targetUserId), {
          'followersCount': FieldValue.increment(-1),
        });

        await batch.commit();
        return false; // Not following
      } else {
        // Follow
        final batch = _firestore.batch();

        batch.set(followRef, {
          'userId': targetUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        batch.set(
          _firestore
              .collection('users')
              .doc(targetUserId)
              .collection('followers')
              .doc(currentUserId),
          {
            'userId': currentUserId,
            'timestamp': FieldValue.serverTimestamp(),
          },
        );

        batch.update(_firestore.collection('users').doc(currentUserId), {
          'followingCount': FieldValue.increment(1),
        });

        batch.update(_firestore.collection('users').doc(targetUserId), {
          'followersCount': FieldValue.increment(1),
        });

        await batch.commit();
        return true; // Now following
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      rethrow;
    }
  }

  /// Ensure user document exists with default values
  Future<void> _ensureUserDocumentExists(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        await userRef.set({
          'id': userId,
          'name': 'User',
          'email': '$userId@app.com',
          'photoURL': null,
          'role': 'user',
          'followersCount': 0,
          'followingCount': 0,
          'bookmarksCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error ensuring user document exists: $e');
    }
  }

  /// Check if user is following another user (Firebase real-time)
  Future<bool> isFollowing({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final followDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get();

      return followDoc.exists;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  /// Get follow status stream for real-time updates
  Stream<bool> getFollowStatusStream({
    required String currentUserId,
    required String targetUserId,
  }) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get paper stream for real-time updates
  Stream<DocumentSnapshot> getPaperStream(String paperId) {
    return _firestore.collection('papers').doc(paperId).snapshots();
  }

  /// Get papers feed stream (all public papers)
  /// Papers are ranked by engagement score in real-time
  Stream<List<DocumentSnapshot>> getPapersFeedStream({
    int limit = 30,
  }) {
    // Instagram-like feed: Sort by newest first, don't resort on engagement changes
    return _firestore
        .collection('papers')
        .where('visibility', isEqualTo: 'public')
        .orderBy('uploadedAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: false)
        .map((snapshot) => snapshot.docs);
  }

  /// Increment paper click count
  Future<void> incrementPaperClicks(String paperId) async {
    try {
      await _firestore.collection('papers').doc(paperId).update({
        'clicksCount': FieldValue.increment(1),
        'lastInteractionAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error incrementing clicks: $e');
    }
  }

  /// Search users by name or username (Instagram-style)
  Stream<List<DocumentSnapshot>> searchUsers(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }

    final lowercaseQuery = query.toLowerCase();

    return _firestore.collection('users').limit(50).snapshots().map((snapshot) {
      // Filter users by name or email containing query
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();

        return name.contains(lowercaseQuery) || email.contains(lowercaseQuery);
      }).toList();
    });
  }

  /// Get all users (for discovery)
  Stream<List<DocumentSnapshot>> getAllUsers({int limit = 50}) {
    return _firestore
        .collection('users')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  /// Get following papers feed stream (papers from followed users)
  Stream<List<DocumentSnapshot>> getFollowingPapersFeedStream({
    required String currentUserId,
    int limit = 50,
  }) async* {
    // Get list of followed users
    final followingSnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .get();

    final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();

    if (followingIds.isEmpty) {
      yield [];
      return;
    }

    // Firestore has a limit of 10 items in 'in' queries
    // Split into chunks if needed
    if (followingIds.length <= 10) {
      yield* _firestore
          .collection('papers')
          .where('uploadedBy', whereIn: followingIds)
          .where('visibility', isEqualTo: 'public')
          .orderBy('uploadedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs);
    } else {
      // For more than 10, we need to make multiple queries and combine
      final chunks = <List<String>>[];
      for (var i = 0; i < followingIds.length; i += 10) {
        chunks.add(
          followingIds.sublist(
            i,
            i + 10 > followingIds.length ? followingIds.length : i + 10,
          ),
        );
      }

      // Merge multiple streams
      yield* Stream.value([]).asyncExpand((initialValue) async* {
        await for (final chunk in Stream.fromIterable(chunks)) {
          final snapshot = await _firestore
              .collection('papers')
              .where('uploadedBy', whereIn: chunk)
              .where('visibility', isEqualTo: 'public')
              .orderBy('uploadedAt', descending: true)
              .limit(limit)
              .get();

          yield snapshot.docs;
        }
      });
    }
  }

  /// Share paper (increment share count)
  Future<void> sharePaper(String paperId) async {
    try {
      await _firestore.collection('papers').doc(paperId).update({
        'sharesCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sharing paper: $e');
    }
  }

  /// Bookmark paper
  Future<void> bookmarkPaper({
    required String userId,
    required String paperId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(paperId)
          .set({
        'paperId': paperId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(userId).update({
        'bookmarksCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error bookmarking paper: $e');
    }
  }

  /// Remove bookmark
  Future<void> removeBookmark({
    required String userId,
    required String paperId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(paperId)
          .delete();

      await _firestore.collection('users').doc(userId).update({
        'bookmarksCount': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
    }
  }

  /// Check if paper is bookmarked
  Stream<bool> isBookmarkedStream({
    required String userId,
    required String paperId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(paperId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
