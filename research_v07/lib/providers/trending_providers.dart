import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/trending_service.dart';
import '../models/firebase_paper.dart';
import '../models/user_profile.dart';

/// Provider for TrendingService singleton
final trendingServiceProvider = Provider<TrendingService>((ref) {
  return TrendingService();
});

/// Provider for trending papers (cached)
final trendingFirebasePapersProvider =
    FutureProvider.family<List<FirebasePaper>, int>((ref, limit) async {
  final service = ref.read(trendingServiceProvider);
  return service.getTrendingPapers(limit: limit);
});

/// Provider for real-time trending papers stream with ML ranking
final trendingPapersStreamProvider =
    StreamProvider.family<List<FirebasePaper>, int>((ref, limit) {
  final service = ref.read(trendingServiceProvider);
  return service.getTrendingPapersStream(limit: limit);
});

/// Provider for trending faculty
final trendingFacultyProvider =
    FutureProvider.family<List<UserProfile>, int>((ref, limit) async {
  final service = ref.read(trendingServiceProvider);
  return service.getTrendingFaculty(limit: limit);
});

/// Provider for hot topics
final hotTopicsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, limit) async {
  final service = ref.read(trendingServiceProvider);
  return service.getHotTopics(limit: limit);
});
