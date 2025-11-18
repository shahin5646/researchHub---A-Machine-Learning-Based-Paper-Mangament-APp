import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../models/firebase_paper.dart';

/// Service for managing personalized social feed
class SocialFeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('SocialFeedService');

  /// Get personalized feed based on user's following
  Stream<List<FirebasePaper>> getFollowingFeed(String userId) {
    return _firestore
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((followsSnapshot) async {
      if (followsSnapshot.docs.isEmpty) {
        return <FirebasePaper>[];
      }

      // Get list of users being followed
      final followingIds = followsSnapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();

      // Get papers from followed users (limited to 10 users at a time due to Firestore limitations)
      final papersSnapshot = await _firestore
          .collection('papers')
          .where('uploadedBy', whereIn: followingIds.take(10).toList())
          .where('visibility', isEqualTo: 'public')
          .orderBy('uploadedAt', descending: true)
          .limit(50)
          .get();

      return papersSnapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    });
  }

  /// Get trending papers (most engagement in last 7 days)
  Future<List<FirebasePaper>> getTrendingPapers({int limit = 20}) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public')
          .where('uploadedAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('uploadedAt', descending: true)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error getting trending papers: $e');
      return [];
    }
  }

  /// Get recommended papers based on user's research interests
  Future<List<FirebasePaper>> getRecommendedPapers(
    String userId,
    List<String> interests, {
    int limit = 20,
  }) async {
    try {
      if (interests.isEmpty) {
        // If no interests, return recent public papers
        return _getRecentPublicPapers(limit: limit);
      }

      final snapshot = await _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public')
          .where('keywords', arrayContainsAny: interests.take(10).toList())
          .orderBy('uploadedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error getting recommended papers: $e');
      return [];
    }
  }

  /// Get recent public papers
  Future<List<FirebasePaper>> _getRecentPublicPapers({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('papers')
        .where('visibility', isEqualTo: 'public')
        .orderBy('uploadedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => FirebasePaper.fromFirestore(doc))
        .toList();
  }

  /// Get papers by category
  Future<List<FirebasePaper>> getPapersByCategory(
    String category, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public')
          .where('category', isEqualTo: category)
          .orderBy('uploadedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error getting papers by category: $e');
      return [];
    }
  }

  /// Get user's activity feed (their own papers and interactions)
  Stream<List<FirebasePaper>> getUserActivityFeed(String userId) {
    return _firestore
        .collection('papers')
        .where('uploadedBy', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    });
  }

  /// Get papers user has interacted with (liked, bookmarked, commented)
  Future<List<FirebasePaper>> getUserInteractedPapers(
    String userId, {
    int limit = 50,
  }) async {
    try {
      // Get papers user has reacted to
      final reactionsSnapshot = await _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public')
          .orderBy('uploadedAt', descending: true)
          .limit(100)
          .get();

      final interactedPapers = <FirebasePaper>[];

      for (var paperDoc in reactionsSnapshot.docs) {
        final reactionDoc =
            await paperDoc.reference.collection('reactions').doc(userId).get();

        if (reactionDoc.exists) {
          interactedPapers.add(FirebasePaper.fromFirestore(paperDoc));
        }

        if (interactedPapers.length >= limit) break;
      }

      return interactedPapers;
    } catch (e) {
      _logger.severe('Error getting user interacted papers: $e');
      return [];
    }
  }

  /// Get discover feed (mix of trending, recommended, and new papers)
  Future<List<FirebasePaper>> getDiscoverFeed(
    String userId,
    List<String> interests, {
    int limit = 30,
  }) async {
    try {
      final papers = <FirebasePaper>[];

      // Get some trending papers
      final trending = await getTrendingPapers(limit: 10);
      papers.addAll(trending);

      // Get some recommended papers
      final recommended = await getRecommendedPapers(
        userId,
        interests,
        limit: 10,
      );
      papers.addAll(recommended);

      // Get some recent papers
      final recent = await _getRecentPublicPapers(limit: 10);
      papers.addAll(recent);

      // Remove duplicates
      final uniquePapers = <String, FirebasePaper>{};
      for (var paper in papers) {
        uniquePapers[paper.id] = paper;
      }

      // Sort by upload date and return limited results
      final sortedPapers = uniquePapers.values.toList()
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return sortedPapers.take(limit).toList();
    } catch (e) {
      _logger.severe('Error getting discover feed: $e');
      return [];
    }
  }

  /// Search papers by keywords
  Future<List<FirebasePaper>> searchPapers(
    String query, {
    String? category,
    int limit = 20,
  }) async {
    try {
      Query papersQuery = _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public');

      if (category != null) {
        papersQuery = papersQuery.where('category', isEqualTo: category);
      }

      // Note: This is a simple title search. For production, consider using
      // Algolia or ElasticSearch for full-text search
      papersQuery = papersQuery
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .orderBy('title')
          .limit(limit);

      final snapshot = await papersQuery.get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error searching papers: $e');
      return [];
    }
  }

  /// Get popular authors (users with most papers/engagement)
  Future<List<Map<String, dynamic>>> getPopularAuthors({int limit = 10}) async {
    try {
      final usersSnapshot = await _firestore
          .collection('user_profiles')
          .where('isProfilePublic', isEqualTo: true)
          .orderBy('papersCount', descending: true)
          .limit(limit)
          .get();

      return usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'displayName': data['displayName'] ?? 'Unknown',
          'photoURL': data['photoURL'],
          'papersCount': data['papersCount'] ?? 0,
          'followersCount': data['followersCount'] ?? 0,
          'institution': data['institution'],
        };
      }).toList();
    } catch (e) {
      _logger.severe('Error getting popular authors: $e');
      return [];
    }
  }

  /// Get papers by multiple keywords (AND logic)
  Future<List<FirebasePaper>> getPapersByKeywords(
    List<String> keywords, {
    int limit = 20,
  }) async {
    try {
      if (keywords.isEmpty) return [];

      // For multiple keywords with AND logic, we need to fetch and filter
      final snapshot = await _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'public')
          .where('keywords', arrayContainsAny: keywords)
          .orderBy('uploadedAt', descending: true)
          .limit(limit * 2) // Fetch more to account for filtering
          .get();

      final papers = snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .where((paper) {
            // Check if paper contains all keywords
            return keywords
                .every((keyword) => paper.keywords.contains(keyword));
          })
          .take(limit)
          .toList();

      return papers;
    } catch (e) {
      _logger.severe('Error getting papers by keywords: $e');
      return [];
    }
  }
}
