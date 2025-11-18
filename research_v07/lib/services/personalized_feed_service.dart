import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/firebase_paper.dart';

/// Service for generating personalized content feeds
/// Combines trending papers, followed users' content, and recommendations
class PersonalizedFeedService {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  PersonalizedFeedService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generate a personalized feed for a user
  /// Combines multiple sources: trending (40%), popular (30%), recent (20%), followed (10%)
  Future<List<FirebasePaper>> getPersonalizedFeed(
    String userId, {
    int limit = 30,
  }) async {
    try {
      _logger.i('Generating personalized feed for user: $userId');

      final papers = <FirebasePaper>[];

      // 1. Get trending papers (40% - 12 papers)
      final trending = await _getTrendingPapers((limit * 0.4).round());
      papers.addAll(trending);

      // 2. Get popular papers (30% - 9 papers)
      final popular = await _getPopularPapers((limit * 0.3).round());
      papers.addAll(popular);

      // 3. Get recent papers (20% - 6 papers)
      final recent = await _getRecentPapers((limit * 0.2).round());
      papers.addAll(recent);

      // 4. Get papers from followed users (10% - 3 papers)
      final followed =
          await _getFollowedUsersPapers(userId, (limit * 0.1).round());
      papers.addAll(followed);

      // Remove duplicates by keeping first occurrence
      final seen = <String>{};
      final uniquePapers = papers
          .where((paper) {
            if (seen.contains(paper.id)) {
              return false;
            }
            seen.add(paper.id);
            return true;
          })
          .take(limit)
          .toList();

      _logger.i('Generated feed with ${uniquePapers.length} papers');
      return uniquePapers;
    } catch (e, stackTrace) {
      _logger.e('Error generating personalized feed',
          error: e, stackTrace: stackTrace);
      // Return fallback feed on error
      return await _getFallbackFeed(limit);
    }
  }

  /// Get trending papers from cache
  Future<List<FirebasePaper>> _getTrendingPapers(int limit) async {
    try {
      final trendingDoc =
          await _firestore.collection('trending').doc('papers').get();

      if (!trendingDoc.exists) {
        return [];
      }

      final data = trendingDoc.data();
      final topPapers = data?['topPapers'] as List<dynamic>? ?? [];

      final papers = <FirebasePaper>[];
      for (var paperData in topPapers.take(limit)) {
        try {
          final paperId = paperData['paperId'] as String;
          final paperDoc =
              await _firestore.collection('papers').doc(paperId).get();

          if (paperDoc.exists) {
            papers.add(FirebasePaper.fromFirestore(paperDoc));
          }
        } catch (e) {
          _logger.w('Error loading trending paper: $e');
        }
      }

      return papers;
    } catch (e) {
      _logger.e('Error getting trending papers: $e');
      return [];
    }
  }

  /// Get popular papers by likes and views
  Future<List<FirebasePaper>> _getPopularPapers(int limit) async {
    try {
      final snapshot = await _firestore
          .collection('papers')
          .orderBy('likesCount', descending: true)
          .limit(limit * 2) // Get more to filter by views
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .take(limit)
          .toList();
    } catch (e) {
      _logger.e('Error getting popular papers: $e');
      return [];
    }
  }

  /// Get recent papers from last 30 days
  Future<List<FirebasePaper>> _getRecentPapers(int limit) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection('papers')
          .where('uploadedAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('uploadedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting recent papers: $e');
      return [];
    }
  }

  /// Get papers from users that current user follows
  Future<List<FirebasePaper>> _getFollowedUsersPapers(
      String userId, int limit) async {
    try {
      // Get following IDs
      final followsSnapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .limit(20)
          .get();

      if (followsSnapshot.docs.isEmpty) {
        return [];
      }

      final followingIds = followsSnapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();

      // Get papers from followed users (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final papers = <FirebasePaper>[];

      // Query in batches (Firestore 'in' query limit is 10)
      for (var i = 0; i < followingIds.length; i += 10) {
        final batch = followingIds.skip(i).take(10).toList();

        final snapshot = await _firestore
            .collection('papers')
            .where('uploadedBy', whereIn: batch)
            .where('uploadedAt',
                isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
            .orderBy('uploadedAt', descending: true)
            .limit(limit)
            .get();

        papers.addAll(
            snapshot.docs.map((doc) => FirebasePaper.fromFirestore(doc)));

        if (papers.length >= limit) break;
      }

      return papers.take(limit).toList();
    } catch (e) {
      _logger.e('Error getting followed users papers: $e');
      return [];
    }
  }

  /// Fallback feed with just recent popular papers
  Future<List<FirebasePaper>> _getFallbackFeed(int limit) async {
    try {
      final snapshot = await _firestore
          .collection('papers')
          .orderBy('views', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Error getting fallback feed: $e');
      return [];
    }
  }

  /// Refresh feed cache for a user
  Future<void> refreshFeedCache(String userId) async {
    try {
      _logger.i('Refreshing feed cache for user: $userId');

      final feed = await getPersonalizedFeed(userId, limit: 50);

      // Cache feed in Firestore
      await _firestore.collection('feedCache').doc(userId).set({
        'papers': feed.map((p) => p.id).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _logger.i('Feed cache refreshed for user: $userId');
    } catch (e, stackTrace) {
      _logger.e('Error refreshing feed cache',
          error: e, stackTrace: stackTrace);
    }
  }
}
