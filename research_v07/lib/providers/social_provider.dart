import 'package:flutter/foundation.dart';
import '../services/social_service.dart';
import '../models/social_models.dart';
import '../models/paper_models.dart';

class SocialProvider extends ChangeNotifier {
  final SocialService _socialService;

  SocialProvider(this._socialService) {
    _socialService.addListener(_onSocialServiceUpdate);
  }

  void _onSocialServiceUpdate() {
    notifyListeners();
  }

  @override
  void dispose() {
    _socialService.removeListener(_onSocialServiceUpdate);
    super.dispose();
  }

  // Getters
  bool get isInitialized => _socialService.isInitialized;
  List<FollowRelationship> get follows => _socialService.follows;
  List<DiscussionThread> get discussions => _socialService.discussions;
  List<SocialNotification> get notifications => _socialService.notifications;
  List<ActivityFeedItem> get activities => _socialService.activities;

  // Follow System
  Future<bool> followUser(String currentUserId, String targetUserId) async {
    final result = await _socialService.followUser(currentUserId, targetUserId);
    if (result) notifyListeners();
    return result;
  }

  Future<bool> unfollowUser(String currentUserId, String targetUserId) async {
    final result =
        await _socialService.unfollowUser(currentUserId, targetUserId);
    if (result) notifyListeners();
    return result;
  }

  bool isFollowing(String currentUserId, String targetUserId) {
    return _socialService.isFollowing(currentUserId, targetUserId);
  }

  List<String> getFollowers(String userId) {
    return _socialService.getFollowers(userId);
  }

  List<String> getFollowing(String userId) {
    return _socialService.getFollowing(userId);
  }

  int getFollowerCount(String userId) {
    return _socialService.getFollowerCount(userId);
  }

  int getFollowingCount(String userId) {
    return _socialService.getFollowingCount(userId);
  }

  // Discussion Threads
  Future<String> createDiscussion({
    required String title,
    required String content,
    required String authorId,
    String? paperId,
    List<String> tags = const [],
    DiscussionCategory category = DiscussionCategory.general,
  }) async {
    final discussionId = await _socialService.createDiscussion(
      title: title,
      content: content,
      authorId: authorId,
      paperId: paperId,
      tags: tags,
      category: category,
    );
    if (discussionId.isNotEmpty) notifyListeners();
    return discussionId;
  }

  Future<bool> addDiscussionComment({
    required String threadId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    final result = await _socialService.addDiscussionComment(
      threadId: threadId,
      userId: userId,
      content: content,
      parentCommentId: parentCommentId,
    );
    if (result) notifyListeners();
    return result;
  }

  Future<bool> reactToDiscussion({
    required String threadId,
    required String userId,
    required DiscussionReactionType reactionType,
  }) async {
    final result = await _socialService.reactToDiscussion(
      threadId: threadId,
      userId: userId,
      reactionType: reactionType,
    );
    if (result) notifyListeners();
    return result;
  }

  // Paper Comments and Reactions
  Future<bool> addPaperComment({
    required String paperId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    final result = await _socialService.addPaperComment(
      paperId: paperId,
      userId: userId,
      content: content,
      parentCommentId: parentCommentId,
    );
    if (result) notifyListeners();
    return result;
  }

  Future<bool> reactToPaper({
    required String paperId,
    required String userId,
    required ReactionType reactionType,
  }) async {
    final result = await _socialService.reactToPaper(
      paperId: paperId,
      userId: userId,
      reactionType: reactionType,
    );
    if (result) notifyListeners();
    return result;
  }

  // Notifications
  Future<bool> markNotificationAsRead(String notificationId) async {
    final result = await _socialService.markNotificationAsRead(notificationId);
    if (result) notifyListeners();
    return result;
  }

  List<SocialNotification> getUserNotifications(String userId) {
    return _socialService.getUserNotifications(userId);
  }

  int getUnreadNotificationCount(String userId) {
    return _socialService.getUnreadNotificationCount(userId);
  }

  // Activity Feed
  List<ActivityFeedItem> getFollowingActivities(String userId) {
    return _socialService.getFollowingActivities(userId);
  }

  // Search and Filter
  List<DiscussionThread> searchDiscussions(String query) {
    return _socialService.searchDiscussions(query);
  }

  List<DiscussionThread> getDiscussionsByCategory(DiscussionCategory category) {
    return _socialService.getDiscussionsByCategory(category);
  }

  List<DiscussionThread> getDiscussionsByPaper(String paperId) {
    return _socialService.getDiscussionsByPaper(paperId);
  }

  // Utility methods for UI
  String getReactionIcon(ReactionType type) {
    switch (type) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.insightful:
        return '💡';
      case ReactionType.helpful:
        return '🔥';
      case ReactionType.bookmark:
        return '🔖';
    }
  }

  String getDiscussionReactionIcon(DiscussionReactionType type) {
    switch (type) {
      case DiscussionReactionType.like:
        return '👍';
      case DiscussionReactionType.insightful:
        return '💡';
      case DiscussionReactionType.helpful:
        return '🔥';
      case DiscussionReactionType.agree:
        return '✅';
      case DiscussionReactionType.disagree:
        return '❌';
    }
  }

  String getCategoryIcon(DiscussionCategory category) {
    switch (category) {
      case DiscussionCategory.general:
        return '💬';
      case DiscussionCategory.research:
        return '🔬';
      case DiscussionCategory.methodology:
        return '⚙️';
      case DiscussionCategory.collaboration:
        return '🤝';
      case DiscussionCategory.feedback:
        return '📝';
      case DiscussionCategory.announcement:
        return '📢';
    }
  }

  String getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.paperUploaded:
        return '📄';
      case ActivityType.paperCommented:
        return '💬';
      case ActivityType.paperReacted:
        return '👍';
      case ActivityType.discussionCreated:
        return '🗨️';
      case ActivityType.discussionCommented:
        return '💬';
      case ActivityType.userFollowed:
        return '👤';
      case ActivityType.paperBookmarked:
        return '🔖';
    }
  }

  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
