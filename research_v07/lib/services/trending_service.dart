import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/firebase_paper.dart';
import '../models/user_profile.dart';

/// Service for calculating and retrieving trending content
class TrendingService {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  TrendingService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calculate and cache trending papers
  Future<void> calculateTrendingPapers() async {
    try {
      // Get all public papers (no date filter to avoid Timestamp issues)
      final papersSnapshot =
          await _firestore.collection('papers').limit(100).get();

      // Calculate trending score for each paper using ML-weighted formula
      final List<Map<String, dynamic>> paperScores = [];
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      for (final doc in papersSnapshot.docs) {
        final data = doc.data();

        // Check visibility
        final visibility = data['visibility'] as String? ?? 'public';
        if (visibility != 'public') continue;

        // Get upload date safely - handle multiple possible fields and null values
        DateTime uploadedAt;
        try {
          if (data['uploadedAt'] != null) {
            uploadedAt = (data['uploadedAt'] as Timestamp).toDate();
          } else if (data['createdAt'] != null) {
            uploadedAt = (data['createdAt'] as Timestamp).toDate();
          } else {
            // Use current time for papers without timestamp
            uploadedAt = DateTime.now().subtract(const Duration(days: 1));
          }
        } catch (e) {
          // If timestamp conversion fails, use default
          uploadedAt = DateTime.now().subtract(const Duration(days: 1));
        }

        // Skip papers older than 7 days
        if (uploadedAt.isBefore(sevenDaysAgo)) continue;

        final views = data['views'] ?? 0;
        final clicks = data['clicksCount'] ?? 0;
        final likes = data['likesCount'] ?? 0;
        final comments = data['commentsCount'] ?? 0;
        final shares = data['sharesCount'] ?? 0;
        final downloads = data['downloads'] ?? 0;

        // Get time decay factor (newer papers get boost)
        final ageInHours = DateTime.now().difference(uploadedAt).inHours;
        final timeDecay = 1.0 / (1.0 + (ageInHours / 24.0)); // Decay over days

        // ML-based trending score formula with weighted engagement metrics
        // Comments and shares are most valuable for trending
        final engagementScore = (views * 0.5) +
            (clicks * 1.0) +
            (likes * 3.0) +
            (comments * 8.0) + // Comments weighted highest
            (shares * 10.0) + // Shares indicate quality
            (downloads * 5.0);

        // Apply time decay to favor recent popular content
        final score = engagementScore * (0.3 + (timeDecay * 0.7));

        paperScores.add({
          'paperId': doc.id,
          'score': score,
          'views': views,
          'clicks': clicks,
          'likes': likes,
          'comments': comments,
          'shares': shares,
          'downloads': downloads,
          'ageInHours': ageInHours,
        });
      }

      // Sort by ML score
      paperScores
          .sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

      // Take top 50
      final top50 = paperScores.take(50).toList();

      // Cache results in Firestore
      await _firestore.collection('trending').doc('papers').set({
        'topPapers': top50,
        'lastUpdated': FieldValue.serverTimestamp(),
        'algorithm': 'ML-weighted-engagement-v2',
      });

      _logger
          .i('Calculated ${top50.length} trending papers using ML algorithm');
    } catch (e, stackTrace) {
      _logger.e('Error calculating trending papers',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Get trending papers from cache
  Future<List<FirebasePaper>> getTrendingPapers({int limit = 10}) async {
    try {
      final trendingDoc =
          await _firestore.collection('trending').doc('papers').get();

      if (!trendingDoc.exists) {
        // Calculate if not exists
        await calculateTrendingPapers();
        return getTrendingPapers(limit: limit);
      }

      final data = trendingDoc.data();
      final topPapers = data?['topPapers'] as List<dynamic>? ?? [];

      // Get paper details
      final List<FirebasePaper> papers = [];
      for (final item in topPapers.take(limit)) {
        final paperId = item['paperId'] as String;
        final paperDoc =
            await _firestore.collection('papers').doc(paperId).get();

        if (paperDoc.exists) {
          papers.add(FirebasePaper.fromFirestore(paperDoc));
        }
      }

      return papers;
    } catch (e) {
      _logger.e('Error getting trending papers: $e');
      return [];
    }
  }

  /// Get real-time trending papers stream with auto-refresh
  Stream<List<FirebasePaper>> getTrendingPapersStream({int limit = 20}) async* {
    try {
      // First, ensure trending data exists or is recent
      final trendingDoc =
          await _firestore.collection('trending').doc('papers').get();

      if (!trendingDoc.exists) {
        await calculateTrendingPapers();
      } else {
        final data = trendingDoc.data();
        DateTime? lastUpdated;

        // Safely handle lastUpdated Timestamp
        try {
          if (data?['lastUpdated'] != null) {
            lastUpdated = (data!['lastUpdated'] as Timestamp).toDate();
          }
        } catch (e) {
          _logger.w('Error parsing lastUpdated timestamp: $e');
        }

        // Recalculate if older than 30 minutes or null
        if (lastUpdated == null ||
            DateTime.now().difference(lastUpdated).inMinutes > 30) {
          calculateTrendingPapers(); // Fire and forget, don't await
        }
      }

      // Stream trending papers with real-time updates
      yield* _firestore
          .collection('trending')
          .doc('papers')
          .snapshots(includeMetadataChanges: false)
          .asyncMap((snapshot) async {
        if (!snapshot.exists) return <FirebasePaper>[];

        final data = snapshot.data();
        final topPapers = data?['topPapers'] as List<dynamic>? ?? [];

        // Get paper details for top papers
        final List<FirebasePaper> papers = [];
        for (final item in topPapers.take(limit)) {
          final paperId = item['paperId'] as String;
          final paperDoc =
              await _firestore.collection('papers').doc(paperId).get();

          if (paperDoc.exists) {
            papers.add(FirebasePaper.fromFirestore(paperDoc));
          }
        }

        return papers;
      });
    } catch (e) {
      _logger.e('Error in trending papers stream: $e');
      yield [];
    }
  }

  /// Calculate and cache trending faculty/researchers
  Future<void> calculateTrendingFaculty() async {
    try {
      // Get all papers to find unique authors
      final papersSnapshot =
          await _firestore.collection('papers').limit(100).get();

      // Track authors and their engagement
      final Map<String, Map<String, dynamic>> authorEngagement = {};

      for (final paperDoc in papersSnapshot.docs) {
        final paperData = paperDoc.data();
        final authorId = paperData['uploadedBy'] as String? ??
            paperData['authorId'] as String?;

        if (authorId == null || authorId.isEmpty) continue;

        if (!authorEngagement.containsKey(authorId)) {
          authorEngagement[authorId] = {
            'papersCount': 0,
            'totalViews': 0,
            'totalLikes': 0,
            'totalComments': 0,
          };
        }

        authorEngagement[authorId]!['papersCount'] =
            (authorEngagement[authorId]!['papersCount'] as int) + 1;
        authorEngagement[authorId]!['totalViews'] =
            (authorEngagement[authorId]!['totalViews'] as int) +
                (paperData['views'] ?? 0) as int;
        authorEngagement[authorId]!['totalLikes'] =
            (authorEngagement[authorId]!['totalLikes'] as int) +
                (paperData['likesCount'] ?? 0) as int;
        authorEngagement[authorId]!['totalComments'] =
            (authorEngagement[authorId]!['totalComments'] as int) +
                (paperData['commentsCount'] ?? 0) as int;
      }

      // Calculate scores for each author
      final List<Map<String, dynamic>> facultyScores = [];

      for (final entry in authorEngagement.entries) {
        final authorId = entry.key;
        final engagement = entry.value;

        // Get user info
        final userDoc =
            await _firestore.collection('users').doc(authorId).get();
        final followersCount =
            userDoc.exists ? (userDoc.data()?['followersCount'] ?? 0) : 0;

        // Faculty score formula: engagement-based
        final score = (followersCount * 10.0) +
            (engagement['papersCount'] * 5.0) +
            (engagement['totalViews'] * 0.5) +
            (engagement['totalLikes'] * 2.0) +
            (engagement['totalComments'] * 3.0);

        facultyScores.add({
          'userId': authorId,
          'score': score,
          'followersCount': followersCount,
          'papersCount': engagement['papersCount'],
          'totalViews': engagement['totalViews'],
          'totalLikes': engagement['totalLikes'],
        });
      }

      // Sort by score
      facultyScores
          .sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));

      // Take top 20
      final top20 = facultyScores.take(20).toList();

      // Cache results
      await _firestore.collection('trending').doc('faculty').set({
        'topFaculty': top20,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _logger.i(
          'Trending faculty calculated: ${top20.length} users (from paper authors)');
    } catch (e) {
      _logger.e('Error calculating trending faculty: $e');
    }
  }

  /// Get trending faculty from cache
  Future<List<UserProfile>> getTrendingFaculty({int limit = 10}) async {
    try {
      final trendingDoc =
          await _firestore.collection('trending').doc('faculty').get();

      if (!trendingDoc.exists) {
        await calculateTrendingFaculty();
        return getTrendingFaculty(limit: limit);
      }

      final data = trendingDoc.data();
      final topFaculty = data?['topFaculty'] as List<dynamic>? ?? [];

      // Get user profiles
      final List<UserProfile> profiles = [];
      for (final item in topFaculty.take(limit)) {
        final userId = item['userId'] as String;
        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          profiles.add(UserProfile.fromFirestore(userDoc));
        }
      }

      return profiles;
    } catch (e) {
      _logger.e('Error getting trending faculty: $e');
      return [];
    }
  }

  /// Calculate and cache hot topics
  Future<void> calculateHotTopics() async {
    try {
      // Get all papers (no date filter to avoid Timestamp issues)
      final papersSnapshot =
          await _firestore.collection('papers').limit(200).get();

      // Count keyword/tag frequency from recent papers
      final Map<String, int> topicCount = {};
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      for (final doc in papersSnapshot.docs) {
        final data = doc.data();

        // Check if paper is recent
        try {
          DateTime uploadedAt;
          if (data['uploadedAt'] != null) {
            uploadedAt = (data['uploadedAt'] as Timestamp).toDate();
          } else if (data['createdAt'] != null) {
            uploadedAt = (data['createdAt'] as Timestamp).toDate();
          } else {
            uploadedAt = DateTime.now().subtract(const Duration(days: 15));
          }

          // Skip old papers
          if (uploadedAt.isBefore(thirtyDaysAgo)) continue;
        } catch (e) {
          // If timestamp fails, include the paper anyway
        }

        final keywords = List<String>.from(data['keywords'] ?? []);
        final tags = List<String>.from(data['tags'] ?? []);
        final category = data['category'] as String?;

        for (final keyword in keywords) {
          topicCount[keyword.toLowerCase()] =
              (topicCount[keyword.toLowerCase()] ?? 0) + 1;
        }

        for (final tag in tags) {
          topicCount[tag.toLowerCase()] =
              (topicCount[tag.toLowerCase()] ?? 0) + 1;
        }

        if (category != null && category.isNotEmpty) {
          topicCount[category.toLowerCase()] =
              (topicCount[category.toLowerCase()] ?? 0) + 1;
        }
      }

      // Sort by frequency
      final sortedTopics = topicCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Take top 20
      final top20 = sortedTopics
          .take(20)
          .map((e) => {
                'topic': e.key,
                'count': e.value,
              })
          .toList();

      // Cache results
      await _firestore.collection('trending').doc('topics').set({
        'hotTopics': top20,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _logger.i('Hot topics calculated: ${top20.length} topics');
    } catch (e) {
      _logger.e('Error calculating hot topics: $e');
    }
  }

  /// Get hot topics from cache
  Future<List<Map<String, dynamic>>> getHotTopics({int limit = 10}) async {
    try {
      final trendingDoc =
          await _firestore.collection('trending').doc('topics').get();

      if (!trendingDoc.exists) {
        await calculateHotTopics();
        return getHotTopics(limit: limit);
      }

      final data = trendingDoc.data();
      final hotTopics = data?['hotTopics'] as List<dynamic>? ?? [];

      return hotTopics
          .take(limit)
          .map((item) => {
                'topic': item['topic'] as String,
                'count': item['count'] as int,
              })
          .toList();
    } catch (e) {
      _logger.e('Error getting hot topics: $e');
      return [];
    }
  }

  /// Run all trend calculations (to be called periodically)
  Future<void> calculateAllTrends() async {
    _logger.i('Starting trend calculations...');
    await Future.wait([
      calculateTrendingPapers(),
      calculateTrendingFaculty(),
      calculateHotTopics(),
    ]);
    _logger.i('All trends calculated successfully');
  }
}
