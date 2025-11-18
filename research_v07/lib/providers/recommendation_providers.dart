import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recommendation_service.dart';
import '../models/research_paper.dart';

/// Provider for the RecommendationService singleton
final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService();
});

/// Provider for personalized recommendations for a user
final personalizedRecommendationsProvider = FutureProvider.family<
    List<RecommendationResult>,
    ({String userId, int limit})>((ref, params) async {
  final service = ref.watch(recommendationServiceProvider);
  return service.getPersonalizedRecommendations(
    params.userId,
    limit: params.limit,
  );
});

/// Provider for trending recommendations
final trendingRecommendationsProvider =
    FutureProvider.family<List<RecommendationResult>, int>((ref, limit) async {
  final service = ref.watch(recommendationServiceProvider);
  return service.getTrendingRecommendations(limit: limit);
});

/// Provider for similar paper recommendations
final similarPapersRecommendationsProvider = FutureProvider.family<
    List<RecommendationResult>,
    ({String paperId, int limit})>((ref, params) async {
  final service = ref.watch(recommendationServiceProvider);
  return service.getSimilarPapersRecommendations(
    params.paperId,
    limit: params.limit,
  );
});

/// Provider for category-based recommendations
final categoryRecommendationsProvider = FutureProvider.family<
    List<RecommendationResult>,
    ({String category, int limit})>((ref, params) async {
  final service = ref.watch(recommendationServiceProvider);
  return service.getCategoryRecommendations(
    params.category,
    limit: params.limit,
  );
});

/// Provider for user's bookmarked papers
final bookmarkedPapersProvider =
    FutureProvider.family<List<RecommendationResult>, String>(
        (ref, userId) async {
  final service = ref.watch(recommendationServiceProvider);
  return service.getBookmarkedPapers(userId);
});

/// Provider for hybrid recommendations (personalized + trending + popular + recent)
final hybridRecommendationsProvider = FutureProvider.family<
    List<RecommendationResult>,
    ({String userId, int limit})>((ref, params) async {
  final service = ref.watch(recommendationServiceProvider);
  return service.getHybridRecommendations(
    params.userId,
    limit: params.limit,
  );
});
