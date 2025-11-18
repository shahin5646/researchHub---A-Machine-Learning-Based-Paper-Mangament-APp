import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../models/firebase_paper.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('CommentService');

  /// Add a comment to a paper
  Future<String> addComment({
    required String paperId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      _logger.info('Adding comment to paper: $paperId');

      final comment = PaperComment(
        id: '',
        paperId: paperId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        content: content,
        timestamp: DateTime.now(),
        parentCommentId: parentCommentId,
      );

      final batch = _firestore.batch();

      // Add comment document
      final commentRef = _firestore
          .collection('papers')
          .doc(paperId)
          .collection('comments')
          .doc();

      batch.set(commentRef, comment.toFirestore());

      // Increment comments count on paper
      final paperRef = _firestore.collection('papers').doc(paperId);
      batch.update(paperRef, {
        'commentsCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      _logger.info('Comment added successfully: ${commentRef.id}');
      return commentRef.id;
    } catch (e) {
      _logger.severe('Error adding comment: $e');
      rethrow;
    }
  }

  /// Update a comment
  Future<void> updateComment({
    required String paperId,
    required String commentId,
    required String content,
  }) async {
    try {
      _logger.info('Updating comment: $commentId');

      await _firestore
          .collection('papers')
          .doc(paperId)
          .collection('comments')
          .doc(commentId)
          .update({
        'content': content,
        'edited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });

      _logger.info('Comment updated successfully');
    } catch (e) {
      _logger.severe('Error updating comment: $e');
      rethrow;
    }
  }

  /// Delete a comment
  Future<void> deleteComment({
    required String paperId,
    required String commentId,
  }) async {
    try {
      _logger.info('Deleting comment: $commentId');

      final batch = _firestore.batch();

      // Delete comment
      final commentRef = _firestore
          .collection('papers')
          .doc(paperId)
          .collection('comments')
          .doc(commentId);

      batch.delete(commentRef);

      // Decrement comments count
      final paperRef = _firestore.collection('papers').doc(paperId);
      batch.update(paperRef, {
        'commentsCount': FieldValue.increment(-1),
      });

      await batch.commit();

      _logger.info('Comment deleted successfully');
    } catch (e) {
      _logger.severe('Error deleting comment: $e');
      rethrow;
    }
  }

  /// Get comments for a paper
  Future<List<PaperComment>> getComments(String paperId,
      {int limit = 50}) async {
    try {
      _logger.info('Fetching comments for paper: $paperId');

      final snapshot = await _firestore
          .collection('papers')
          .doc(paperId)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PaperComment.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching comments: $e');
      return [];
    }
  }

  /// Get comments stream for real-time updates
  Stream<List<PaperComment>> getCommentsStream(String paperId) {
    return _firestore
        .collection('papers')
        .doc(paperId)
        .collection('comments')
        .where('parentCommentId', isNull: true) // Only top-level comments
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaperComment.fromFirestore(doc))
          .toList();
    });
  }

  /// Get replies to a comment
  Future<List<PaperComment>> getReplies(
      String paperId, String parentCommentId) async {
    try {
      _logger.info('Fetching replies for comment: $parentCommentId');

      final snapshot = await _firestore
          .collection('papers')
          .doc(paperId)
          .collection('comments')
          .where('parentCommentId', isEqualTo: parentCommentId)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => PaperComment.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching replies: $e');
      return [];
    }
  }

  /// Like a comment
  Future<void> likeComment({
    required String paperId,
    required String commentId,
    required String userId,
  }) async {
    try {
      _logger.info('Liking comment: $commentId');

      await _firestore
          .collection('papers')
          .doc(paperId)
          .collection('comments')
          .doc(commentId)
          .update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });

      _logger.info('Comment liked successfully');
    } catch (e) {
      _logger.severe('Error liking comment: $e');
      rethrow;
    }
  }

  /// Unlike a comment
  Future<void> unlikeComment({
    required String paperId,
    required String commentId,
    required String userId,
  }) async {
    try {
      _logger.info('Unliking comment: $commentId');

      await _firestore
          .collection('papers')
          .doc(paperId)
          .collection('comments')
          .doc(commentId)
          .update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });

      _logger.info('Comment unliked successfully');
    } catch (e) {
      _logger.severe('Error unliking comment: $e');
      rethrow;
    }
  }

  /// Check if user has liked a comment
  Future<bool> hasUserLikedComment({
    required String paperId,
    required String commentId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection('papers')
          .doc(paperId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        return likedBy.contains(userId);
      }

      return false;
    } catch (e) {
      _logger.warning('Error checking like status: $e');
      return false;
    }
  }

  /// Get comment count for a paper
  Future<int> getCommentCount(String paperId) async {
    try {
      final snapshot = await _firestore
          .collection('papers')
          .doc(paperId)
          .collection('comments')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      _logger.warning('Error getting comment count: $e');
      return 0;
    }
  }
}
