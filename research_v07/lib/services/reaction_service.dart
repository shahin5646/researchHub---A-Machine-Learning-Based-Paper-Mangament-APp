import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../models/firebase_paper.dart';

class ReactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('ReactionService');

  /// Add a reaction to a paper
  Future<void> addReaction({
    required String paperId,
    required String userId,
    required String type, // 'like', 'love', 'insightful', 'bookmark'
  }) async {
    try {
      _logger.info('Adding $type reaction to paper: $paperId by user: $userId');

      final reaction = PaperReaction(
        userId: userId,
        type: type,
        timestamp: DateTime.now(),
      );

      final batch = _firestore.batch();

      // Add/Update reaction document
      final reactionRef = _firestore
          .collection('papers')
          .doc(paperId)
          .collection('reactions')
          .doc(userId);

      batch.set(reactionRef, reaction.toFirestore());

      // Increment likes count on paper
      final paperRef = _firestore.collection('papers').doc(paperId);
      batch.update(paperRef, {
        'likesCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      _logger.info('Reaction added successfully');
    } catch (e) {
      _logger.severe('Error adding reaction: $e');
      rethrow;
    }
  }

  /// Remove a reaction from a paper
  Future<void> removeReaction({
    required String paperId,
    required String userId,
  }) async {
    try {
      _logger.info('Removing reaction from paper: $paperId by user: $userId');

      final batch = _firestore.batch();

      // Delete reaction document
      final reactionRef = _firestore
          .collection('papers')
          .doc(paperId)
          .collection('reactions')
          .doc(userId);

      batch.delete(reactionRef);

      // Decrement likes count on paper
      final paperRef = _firestore.collection('papers').doc(paperId);
      batch.update(paperRef, {
        'likesCount': FieldValue.increment(-1),
      });

      await batch.commit();

      _logger.info('Reaction removed successfully');
    } catch (e) {
      _logger.severe('Error removing reaction: $e');
      rethrow;
    }
  }

  /// Update reaction type (e.g., change from 'like' to 'love')
  Future<void> updateReaction({
    required String paperId,
    required String userId,
    required String newType,
  }) async {
    try {
      _logger.info('Updating reaction type for paper: $paperId');

      await _firestore
          .collection('papers')
          .doc(paperId)
          .collection('reactions')
          .doc(userId)
          .update({
        'type': newType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _logger.info('Reaction updated successfully');
    } catch (e) {
      _logger.severe('Error updating reaction: $e');
      rethrow;
    }
  }

  /// Check if user has reacted to a paper
  Future<PaperReaction?> getUserReaction({
    required String paperId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection('papers')
          .doc(paperId)
          .collection('reactions')
          .doc(userId)
          .get();

      if (doc.exists) {
        return PaperReaction.fromFirestore(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      _logger.warning('Error getting user reaction: $e');
      return null;
    }
  }

  /// Get all reactions for a paper
  Future<List<PaperReaction>> getReactions(String paperId) async {
    try {
      _logger.info('Fetching reactions for paper: $paperId');

      final snapshot = await _firestore
          .collection('papers')
          .doc(paperId)
          .collection('reactions')
          .get();

      return snapshot.docs
          .map((doc) => PaperReaction.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching reactions: $e');
      return [];
    }
  }

  /// Get reaction count by type
  Future<Map<String, int>> getReactionCounts(String paperId) async {
    try {
      _logger.info('Fetching reaction counts for paper: $paperId');

      final snapshot = await _firestore
          .collection('papers')
          .doc(paperId)
          .collection('reactions')
          .get();

      final counts = <String, int>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? 'like';
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      _logger.severe('Error fetching reaction counts: $e');
      return {};
    }
  }

  /// Get users who reacted with specific type
  Future<List<String>> getUsersByReactionType({
    required String paperId,
    required String type,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('papers')
          .doc(paperId)
          .collection('reactions')
          .where('type', isEqualTo: type)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      _logger.warning('Error fetching users by reaction type: $e');
      return [];
    }
  }

  /// Toggle reaction (add if not exists, remove if exists)
  Future<bool> toggleReaction({
    required String paperId,
    required String userId,
    String type = 'like',
  }) async {
    try {
      final existingReaction = await getUserReaction(
        paperId: paperId,
        userId: userId,
      );

      if (existingReaction != null) {
        // Remove reaction
        await removeReaction(paperId: paperId, userId: userId);
        return false; // Reaction removed
      } else {
        // Add reaction
        await addReaction(paperId: paperId, userId: userId, type: type);
        return true; // Reaction added
      }
    } catch (e) {
      _logger.severe('Error toggling reaction: $e');
      rethrow;
    }
  }
}
