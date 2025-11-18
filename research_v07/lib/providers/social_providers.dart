import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/firebase_paper.dart';
import '../services/social_profile_service.dart';
import '../services/social_feed_service.dart';

/// Provider for SocialProfileService
final socialProfileServiceProvider = Provider<SocialProfileService>((ref) {
  return SocialProfileService();
});

/// Provider for SocialFeedService
final socialFeedServiceProvider = Provider<SocialFeedService>((ref) {
  return SocialFeedService();
});

/// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

/// Provider for current user profile (real-time stream)
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);

  final service = ref.watch(socialProfileServiceProvider);
  return service.streamUserProfile(userId);
});

/// Provider for a specific user profile
final userProfileProvider =
    StreamProvider.family<UserProfile?, String>((ref, userId) {
  final service = ref.watch(socialProfileServiceProvider);
  return service.streamUserProfile(userId);
});

/// Provider for followers list
final followersProvider = FutureProvider.family<List<UserProfile>, String>(
  (ref, userId) async {
    final service = ref.watch(socialProfileServiceProvider);
    return service.getFollowers(userId, limit: 100);
  },
);

/// Provider for following list
final followingProvider = FutureProvider.family<List<UserProfile>, String>(
  (ref, userId) async {
    final service = ref.watch(socialProfileServiceProvider);
    return service.getFollowing(userId, limit: 100);
  },
);

/// Provider to check if current user is following another user
final isFollowingProvider = FutureProvider.family<bool, String>(
  (ref, targetUserId) async {
    final currentUserId = ref.watch(currentUserIdProvider);
    if (currentUserId == null) return false;

    final service = ref.watch(socialProfileServiceProvider);
    return service.isFollowing(currentUserId, targetUserId);
  },
);

/// Provider for recommended users based on current user's interests
final recommendedUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return [];

  final currentProfile = await ref.watch(
    currentUserProfileProvider.future,
  );

  if (currentProfile == null) return [];

  final service = ref.watch(socialProfileServiceProvider);
  return service.getRecommendedUsers(
    currentUserId,
    currentProfile.researchInterests,
    limit: 10,
  );
});

/// Provider for user search results
final userSearchProvider =
    FutureProvider.family<List<UserProfile>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final service = ref.watch(socialProfileServiceProvider);
  return service.searchUsers(query, limit: 20);
});

/// Provider for users by research interest
final usersByInterestProvider =
    FutureProvider.family<List<UserProfile>, String>((ref, interest) async {
  final service = ref.watch(socialProfileServiceProvider);
  return service.getUsersByInterest(interest, limit: 20);
});

/// Provider for following feed (papers from followed users)
final followingFeedProvider = StreamProvider<List<FirebasePaper>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final service = ref.watch(socialFeedServiceProvider);
  return service.getFollowingFeed(userId);
});

/// Provider for trending papers
final trendingPapersProvider = FutureProvider<List<FirebasePaper>>((ref) async {
  final service = ref.watch(socialFeedServiceProvider);
  return service.getTrendingPapers(limit: 20);
});

/// Provider for recommended papers based on user's interests
final recommendedPapersProvider =
    FutureProvider<List<FirebasePaper>>((ref) async {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return [];

  final currentProfile = await ref.watch(
    currentUserProfileProvider.future,
  );

  if (currentProfile == null) return [];

  final service = ref.watch(socialFeedServiceProvider);
  return service.getRecommendedPapers(
    currentUserId,
    currentProfile.researchInterests,
    limit: 20,
  );
});

/// Provider for discover feed (mix of trending, recommended, new)
final discoverFeedProvider = FutureProvider<List<FirebasePaper>>((ref) async {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return [];

  final currentProfile = await ref.watch(
    currentUserProfileProvider.future,
  );

  if (currentProfile == null) return [];

  final service = ref.watch(socialFeedServiceProvider);
  return service.getDiscoverFeed(
    currentUserId,
    currentProfile.researchInterests,
    limit: 30,
  );
});

/// Provider for user's activity feed
final userActivityFeedProvider =
    StreamProvider.family<List<FirebasePaper>, String>((ref, userId) {
  final service = ref.watch(socialFeedServiceProvider);
  return service.getUserActivityFeed(userId);
});

/// Provider for papers by category
final papersByCategoryProvider =
    FutureProvider.family<List<FirebasePaper>, String>((ref, category) async {
  final service = ref.watch(socialFeedServiceProvider);
  return service.getPapersByCategory(category, limit: 20);
});

/// Provider for popular authors
final popularAuthorsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(socialFeedServiceProvider);
  return service.getPopularAuthors(limit: 10);
});

/// Provider for paper search results
final paperSearchProvider =
    FutureProvider.family<List<FirebasePaper>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final service = ref.watch(socialFeedServiceProvider);
  return service.searchPapers(query, limit: 20);
});

/// Provider for papers by multiple keywords
final papersByKeywordsProvider =
    FutureProvider.family<List<FirebasePaper>, List<String>>(
        (ref, keywords) async {
  if (keywords.isEmpty) return [];

  final service = ref.watch(socialFeedServiceProvider);
  return service.getPapersByKeywords(keywords, limit: 20);
});

/// Notifier for managing follow/unfollow state
class FollowNotifier extends StateNotifier<AsyncValue<bool>> {
  FollowNotifier(this.service, this.currentUserId, this.targetUserId)
      : super(const AsyncValue.loading()) {
    _checkFollowStatus();
  }

  final SocialProfileService service;
  final String currentUserId;
  final String targetUserId;

  Future<void> _checkFollowStatus() async {
    try {
      final isFollowing =
          await service.isFollowing(currentUserId, targetUserId);
      state = AsyncValue.data(isFollowing);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleFollow() async {
    final currentState = state.value;
    if (currentState == null) return;

    state = const AsyncValue.loading();

    try {
      if (currentState) {
        await service.unfollowUser(currentUserId, targetUserId);
        state = const AsyncValue.data(false);
      } else {
        await service.followUser(currentUserId, targetUserId);
        state = const AsyncValue.data(true);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      // Revert to previous state on error
      state = AsyncValue.data(currentState);
    }
  }
}

/// Provider for follow notifier
final followNotifierProvider = StateNotifierProvider.family<FollowNotifier,
    AsyncValue<bool>, ({String currentUserId, String targetUserId})>(
  (ref, params) {
    final service = ref.watch(socialProfileServiceProvider);
    return FollowNotifier(
      service,
      params.currentUserId,
      params.targetUserId,
    );
  },
);
