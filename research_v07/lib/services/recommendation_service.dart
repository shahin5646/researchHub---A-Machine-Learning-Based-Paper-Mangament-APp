import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/research_paper.dart';
import '../data/faculty_data.dart';
import '../services/ml_categorization_service.dart';

class RecommendationService {
  static final RecommendationService _instance =
      RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  final MLCategorizationService _mlService = MLCategorizationService();

  // User behavior tracking
  Map<String, UserBehavior> _userBehaviors = {};

  // Paper-to-paper similarity graph
  Map<String, Map<String, double>> _similarityGraph = {};

  // Initialize recommendation system
  Future<void> initialize() async {
    await _loadUserBehaviors();
    await _buildSimilarityGraph();
  }

  // Graph Neural Network-inspired recommendation
  List<RecommendationResult> getPersonalizedRecommendations(
    String userId, {
    int limit = 10,
    double threshold = 0.1,
  }) {
    final userBehavior = _userBehaviors[userId];
    if (userBehavior == null) {
      return _getPopularRecommendations(limit);
    }

    final recommendations = <RecommendationResult>[];
    final allPapers = _getAllPapers();
    final viewedPapers = userBehavior.viewedPapers.toSet();

    // Calculate recommendation scores using graph propagation
    for (final paper in allPapers) {
      if (viewedPapers.contains(paper.id)) continue;

      double score = 0.0;

      // Content-based similarity to viewed papers
      for (final viewedPaperId in userBehavior.viewedPapers) {
        final viewedPaper = _findPaperById(viewedPaperId);
        if (viewedPaper != null) {
          final similarity = _getSimilarity(paper.id, viewedPaper.id);
          final userRating = userBehavior.ratings[viewedPaperId] ?? 0.0;
          score += similarity * userRating * 0.4; // Content weight
        }
      }

      // Collaborative filtering component
      score += _getCollaborativeScore(paper, userBehavior) * 0.3;

      // Popularity and recency boost
      score += _getPopularityScore(paper) * 0.2;
      score += _getRecencyScore(paper) * 0.1;

      if (score > threshold) {
        recommendations.add(RecommendationResult(
          paper: paper,
          score: score,
          reasoning: _generateReasoning(paper, userBehavior),
          recommendationType: RecommendationType.personalized,
        ));
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  // Collaborative filtering using user similarity
  double _getCollaborativeScore(
      ResearchPaper paper, UserBehavior userBehavior) {
    double score = 0.0;
    int similarUsers = 0;

    for (final otherBehavior in _userBehaviors.values) {
      if (otherBehavior.userId == userBehavior.userId) continue;

      final similarity = _calculateUserSimilarity(userBehavior, otherBehavior);
      if (similarity > 0.3) {
        // Threshold for similar users
        final otherRating = otherBehavior.ratings[paper.id];
        if (otherRating != null) {
          score += similarity * otherRating;
          similarUsers++;
        }
      }
    }

    return similarUsers > 0 ? score / similarUsers : 0.0;
  }

  // Calculate user similarity based on behavior
  double _calculateUserSimilarity(UserBehavior user1, UserBehavior user2) {
    final user1Papers = user1.viewedPapers.toSet();
    final user2Papers = user2.viewedPapers.toSet();

    final intersection = user1Papers.intersection(user2Papers);
    final union = user1Papers.union(user2Papers);

    if (union.isEmpty) return 0.0;

    // Jaccard similarity
    final jaccardSim = intersection.length / union.length;

    // Rating correlation
    double ratingCorr = 0.0;
    if (intersection.isNotEmpty) {
      final user1Ratings =
          intersection.map((id) => user1.ratings[id] ?? 0.0).toList();
      final user2Ratings =
          intersection.map((id) => user2.ratings[id] ?? 0.0).toList();
      ratingCorr = _calculatePearsonCorrelation(user1Ratings, user2Ratings);
    }

    return (jaccardSim + ratingCorr) / 2;
  }

  // Trend-based recommendations
  List<RecommendationResult> getTrendingRecommendations({int limit = 10}) {
    final trends = _mlService.analyzeTrends();
    final trendingPapers = <RecommendationResult>[];

    for (final trend in trends.take(5)) {
      final papers = _getAllPapers()
          .where((paper) => paper.keywords.any((keyword) =>
              keyword.toLowerCase().contains(trend.keyword.toLowerCase())))
          .toList();

      for (final paper in papers.take(2)) {
        trendingPapers.add(RecommendationResult(
          paper: paper,
          score: trend.growthRate,
          reasoning:
              'Trending in ${trend.keyword} (${(trend.growthRate * 100).toStringAsFixed(1)}% growth)',
          recommendationType: RecommendationType.trending,
        ));
      }
    }

    trendingPapers.sort((a, b) => b.score.compareTo(a.score));
    return trendingPapers.take(limit).toList();
  }

  // Similar papers recommendation
  List<RecommendationResult> getSimilarPapersRecommendations(
    String paperId, {
    int limit = 5,
  }) {
    final targetPaper = _findPaperById(paperId);
    if (targetPaper == null) return [];

    final similarPapers =
        _mlService.findSimilarPapers(targetPaper, limit: limit);

    return similarPapers.map((paper) {
      final similarity = _getSimilarity(paperId, paper.id);
      return RecommendationResult(
        paper: paper,
        score: similarity,
        reasoning: 'Similar content and keywords',
        recommendationType: RecommendationType.similar,
      );
    }).toList();
  }

  // Category-based recommendations
  List<RecommendationResult> getCategoryRecommendations(
    String category, {
    int limit = 10,
  }) {
    final allPapers = _getAllPapers();
    final categoryPapers = allPapers.where((paper) {
      return paper.keywords.any(
          (keyword) => keyword.toLowerCase().contains(category.toLowerCase()));
    }).toList();

    // Sort by citations and recency
    categoryPapers.sort((a, b) {
      final scoreA = a.citations * 0.7 + _getRecencyScore(a) * 0.3;
      final scoreB = b.citations * 0.7 + _getRecencyScore(b) * 0.3;
      return scoreB.compareTo(scoreA);
    });

    return categoryPapers.take(limit).map((paper) {
      return RecommendationResult(
        paper: paper,
        score: paper.citations.toDouble(),
        reasoning: 'Top paper in $category',
        recommendationType: RecommendationType.category,
      );
    }).toList();
  }

  // Track user behavior
  Future<void> trackPaperView(String userId, String paperId) async {
    _userBehaviors[userId] =
        _userBehaviors[userId] ?? UserBehavior(userId: userId);
    _userBehaviors[userId]!.viewedPapers.add(paperId);
    _userBehaviors[userId]!.lastActivity = DateTime.now();
    await _saveUserBehaviors();
  }

  Future<void> trackPaperRating(
      String userId, String paperId, double rating) async {
    _userBehaviors[userId] =
        _userBehaviors[userId] ?? UserBehavior(userId: userId);
    _userBehaviors[userId]!.ratings[paperId] = rating;
    await _saveUserBehaviors();
  }

  Future<void> trackPaperBookmark(String userId, String paperId) async {
    _userBehaviors[userId] =
        _userBehaviors[userId] ?? UserBehavior(userId: userId);
    _userBehaviors[userId]!.bookmarkedPapers.add(paperId);
    await _saveUserBehaviors();
  }

  Future<void> trackDownload(String userId, String paperId) async {
    _userBehaviors[userId] =
        _userBehaviors[userId] ?? UserBehavior(userId: userId);
    _userBehaviors[userId]!.downloadedPapers.add(paperId);
    await _saveUserBehaviors();
  }

  // Get user's bookmarked papers
  List<RecommendationResult> getBookmarkedPapers(String userId) {
    final userBehavior = _userBehaviors[userId];
    if (userBehavior == null) return [];

    return userBehavior.bookmarkedPapers
        .map((paperId) {
          final paper = _findPaperById(paperId);
          if (paper != null) {
            return RecommendationResult(
              paper: paper,
              score: 1.0,
              reasoning: 'Bookmarked by you',
              recommendationType: RecommendationType.bookmarked,
            );
          }
          return null;
        })
        .where((result) => result != null)
        .cast<RecommendationResult>()
        .toList();
  }

  // Hybrid recommendations combining multiple approaches
  List<RecommendationResult> getHybridRecommendations(
    String userId, {
    int limit = 15,
  }) {
    final recommendations = <RecommendationResult>[];

    // Personalized (40%)
    final personalized =
        getPersonalizedRecommendations(userId, limit: (limit * 0.4).round());
    recommendations.addAll(personalized);

    // Trending (30%)
    final trending = getTrendingRecommendations(limit: (limit * 0.3).round());
    recommendations.addAll(trending);

    // Popular (20%)
    final popular = _getPopularRecommendations((limit * 0.2).round());
    recommendations.addAll(popular);

    // Recent (10%)
    final recent = _getRecentRecommendations((limit * 0.1).round());
    recommendations.addAll(recent);

    // Remove duplicates and sort
    final uniqueRecommendations = <String, RecommendationResult>{};
    for (final rec in recommendations) {
      final existing = uniqueRecommendations[rec.paper.id];
      if (existing == null || rec.score > existing.score) {
        uniqueRecommendations[rec.paper.id] = rec;
      }
    }

    final result = uniqueRecommendations.values.toList();
    result.sort((a, b) => b.score.compareTo(a.score));
    return result.take(limit).toList();
  }

  // Private helper methods
  List<ResearchPaper> _getAllPapers() {
    final papers = <ResearchPaper>[];
    facultyResearchPapers.forEach((_, paperList) {
      papers.addAll(paperList);
    });
    return papers;
  }

  ResearchPaper? _findPaperById(String id) {
    return _getAllPapers().firstWhere(
      (paper) => paper.id == id,
      orElse: () => _getAllPapers().firstWhere(
        (paper) => paper.title.hashCode.toString() == id,
        orElse: () => _getAllPapers().first,
      ),
    );
  }

  Future<void> _buildSimilarityGraph() async {
    final papers = _getAllPapers();

    for (int i = 0; i < papers.length; i++) {
      _similarityGraph[papers[i].id] = {};

      for (int j = 0; j < papers.length; j++) {
        if (i != j) {
          final similarity =
              _mlService.calculateSemanticSimilarity(papers[i], papers[j]);
          _similarityGraph[papers[i].id]![papers[j].id] = similarity;
        }
      }
    }
  }

  double _getSimilarity(String paper1Id, String paper2Id) {
    return _similarityGraph[paper1Id]?[paper2Id] ?? 0.0;
  }

  double _getPopularityScore(ResearchPaper paper) {
    final maxCitations =
        _getAllPapers().map((p) => p.citations).reduce(math.max);
    return maxCitations > 0 ? paper.citations / maxCitations : 0.0;
  }

  double _getRecencyScore(ResearchPaper paper) {
    final currentYear = DateTime.now().year;
    final paperYear = int.tryParse(paper.year) ?? currentYear;
    final yearsOld = currentYear - paperYear;
    return math.max(0, 1 - (yearsOld / 10)); // Decay over 10 years
  }

  String _generateReasoning(ResearchPaper paper, UserBehavior userBehavior) {
    final reasons = <String>[];

    // Check for similar keywords
    final viewedPapers = userBehavior.viewedPapers
        .map(_findPaperById)
        .where((p) => p != null)
        .cast<ResearchPaper>();
    final userKeywords = <String>{};
    for (final viewedPaper in viewedPapers) {
      userKeywords.addAll(viewedPaper.keywords);
    }

    final commonKeywords =
        paper.keywords.where((k) => userKeywords.contains(k)).toList();
    if (commonKeywords.isNotEmpty) {
      reasons
          .add('Matches your interest in ${commonKeywords.take(2).join(', ')}');
    }

    if (paper.citations > 50) {
      reasons.add('Highly cited (${paper.citations} citations)');
    }

    final paperYear = int.tryParse(paper.year) ?? 0;
    if (paperYear >= DateTime.now().year - 2) {
      reasons.add('Recent publication');
    }

    return reasons.isNotEmpty ? reasons.join(' • ') : 'Recommended for you';
  }

  List<RecommendationResult> _getPopularRecommendations(int limit) {
    final papers = _getAllPapers();
    papers.sort((a, b) => b.citations.compareTo(a.citations));

    return papers.take(limit).map((paper) {
      return RecommendationResult(
        paper: paper,
        score: paper.citations.toDouble(),
        reasoning: 'Popular paper (${paper.citations} citations)',
        recommendationType: RecommendationType.popular,
      );
    }).toList();
  }

  List<RecommendationResult> _getRecentRecommendations(int limit) {
    final papers = _getAllPapers();
    papers.sort((a, b) => b.year.compareTo(a.year));

    return papers.take(limit).map((paper) {
      return RecommendationResult(
        paper: paper,
        score: _getRecencyScore(paper),
        reasoning: 'Recent publication (${paper.year})',
        recommendationType: RecommendationType.recent,
      );
    }).toList();
  }

  double _calculatePearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;

    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);
    final sumY2 = y.map((v) => v * v).reduce((a, b) => a + b);

    final numerator = n * sumXY - sumX * sumY;
    final denominator =
        math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

    return denominator != 0 ? numerator / denominator : 0.0;
  }

  Future<void> _loadUserBehaviors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final behaviorJson = prefs.getString('user_behaviors');

      if (behaviorJson != null) {
        final Map<String, dynamic> data = json.decode(behaviorJson);
        _userBehaviors = data
            .map((key, value) => MapEntry(key, UserBehavior.fromJson(value)));
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveUserBehaviors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data =
          _userBehaviors.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString('user_behaviors', json.encode(data));
    } catch (e) {
      // Handle error silently
    }
  }
}

class UserBehavior {
  final String userId;
  final List<String> viewedPapers;
  final List<String> bookmarkedPapers;
  final List<String> downloadedPapers;
  final Map<String, double> ratings;
  final List<String> searchHistory;
  DateTime lastActivity;

  UserBehavior({
    required this.userId,
    List<String>? viewedPapers,
    List<String>? bookmarkedPapers,
    List<String>? downloadedPapers,
    Map<String, double>? ratings,
    List<String>? searchHistory,
    DateTime? lastActivity,
  })  : viewedPapers = viewedPapers ?? [],
        bookmarkedPapers = bookmarkedPapers ?? [],
        downloadedPapers = downloadedPapers ?? [],
        ratings = ratings ?? {},
        searchHistory = searchHistory ?? [],
        lastActivity = lastActivity ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'viewedPapers': viewedPapers,
        'bookmarkedPapers': bookmarkedPapers,
        'downloadedPapers': downloadedPapers,
        'ratings': ratings,
        'searchHistory': searchHistory,
        'lastActivity': lastActivity.toIso8601String(),
      };

  factory UserBehavior.fromJson(Map<String, dynamic> json) => UserBehavior(
        userId: json['userId'],
        viewedPapers: List<String>.from(json['viewedPapers'] ?? []),
        bookmarkedPapers: List<String>.from(json['bookmarkedPapers'] ?? []),
        downloadedPapers: List<String>.from(json['downloadedPapers'] ?? []),
        ratings: Map<String, double>.from(json['ratings'] ?? {}),
        searchHistory: List<String>.from(json['searchHistory'] ?? []),
        lastActivity: DateTime.parse(
            json['lastActivity'] ?? DateTime.now().toIso8601String()),
      );
}

class RecommendationResult {
  final ResearchPaper paper;
  final double score;
  final String reasoning;
  final RecommendationType recommendationType;

  RecommendationResult({
    required this.paper,
    required this.score,
    required this.reasoning,
    required this.recommendationType,
  });
}

enum RecommendationType {
  personalized,
  trending,
  similar,
  category,
  popular,
  recent,
  bookmarked,
}
