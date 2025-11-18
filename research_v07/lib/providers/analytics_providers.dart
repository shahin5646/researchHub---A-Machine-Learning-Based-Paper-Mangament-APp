import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';

/// Provider for AnalyticsService singleton
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Provider for paper analytics
final paperAnalyticsProvider =
    FutureProvider.family<PaperAnalytics?, String>((ref, paperId) async {
  final service = ref.read(analyticsServiceProvider);
  return service.getPaperAnalytics(paperId);
});

/// Provider for trending papers
final trendingPapersProvider = FutureProvider<List<TrendingPaper>>((ref) async {
  final service = ref.read(analyticsServiceProvider);
  return service.getTrendingPapers();
});
