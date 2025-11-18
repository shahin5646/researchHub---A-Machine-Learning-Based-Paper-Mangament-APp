import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firebase_paper.dart';
import '../services/personalized_feed_service.dart';

/// Provider for PersonalizedFeedService singleton
final personalizedFeedServiceProvider =
    Provider<PersonalizedFeedService>((ref) {
  return PersonalizedFeedService();
});

/// Provider for personalized feed
/// Usage: ref.watch(personalizedFeedProvider((userId: 'user123', limit: 30)))
final personalizedFeedProvider =
    FutureProvider.family<List<FirebasePaper>, ({String userId, int limit})>(
        (ref, params) async {
  final service = ref.watch(personalizedFeedServiceProvider);
  return service.getPersonalizedFeed(params.userId, limit: params.limit);
});

/// Provider to refresh feed cache
/// Usage: ref.read(refreshFeedCacheProvider('user123'))
final refreshFeedCacheProvider =
    FutureProvider.family<void, String>((ref, userId) async {
  final service = ref.watch(personalizedFeedServiceProvider);
  await service.refreshFeedCache(userId);
});
