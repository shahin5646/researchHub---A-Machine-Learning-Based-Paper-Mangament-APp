import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/social_models.dart';
import '../models/user.dart';
import '../models/paper_models.dart';

class SocialService extends ChangeNotifier {
  // Use late but make initialization safer
  late Box<FollowRelationship> _followBox;
  late Box<DiscussionThread> _discussionBox;
  late Box<SocialNotification> _notificationBox;
  late Box<ActivityFeedItem> _activityBox;
  late Box<User> _userBox;
  late Box<ResearchPaper> _paperBox;

  List<FollowRelationship> _follows = [];
  List<DiscussionThread> _discussions = [];
  List<SocialNotification> _notifications = [];
  List<ActivityFeedItem> _activities = [];

  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  List<FollowRelationship> get follows => _follows;
  List<DiscussionThread> get discussions => _discussions;
  List<SocialNotification> get notifications => _notifications;
  List<ActivityFeedItem> get activities => _activities;

  // Constructor that immediately attempts initialization
  SocialService() {
    // Attempt initialization asynchronously
    initialize().catchError((e) {
      debugPrint('Failed to initialize SocialService: $e');
    });
  }

  // Method to safely access boxes and provide better error messages
  bool _checkInitialized() {
    if (!_isInitialized) {
      debugPrint(
          'Warning: SocialService not initialized yet. Operations might fail.');
      return false;
    }
    return true;
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('SocialService already initialized');
      return;
    }

    try {
      debugPrint('Initializing SocialService...');

      // Open Hive boxes - check if already open first
      _followBox = Hive.isBoxOpen('follows')
          ? Hive.box<FollowRelationship>('follows')
          : await Hive.openBox<FollowRelationship>('follows');

      _discussionBox = Hive.isBoxOpen('discussions')
          ? Hive.box<DiscussionThread>('discussions')
          : await Hive.openBox<DiscussionThread>('discussions');

      _notificationBox = Hive.isBoxOpen('notifications')
          ? Hive.box<SocialNotification>('notifications')
          : await Hive.openBox<SocialNotification>('notifications');

      _activityBox = Hive.isBoxOpen('activities')
          ? Hive.box<ActivityFeedItem>('activities')
          : await Hive.openBox<ActivityFeedItem>('activities');

      _userBox = Hive.isBoxOpen('users')
          ? Hive.box<User>('users')
          : await Hive.openBox<User>('users');

      _paperBox = Hive.isBoxOpen('papers')
          ? Hive.box<ResearchPaper>('papers')
          : await Hive.openBox<ResearchPaper>('papers');

      // Load data from boxes
      _follows = _followBox.values.toList();
      _discussions = _discussionBox.values.toList();
      _notifications = _notificationBox.values.toList();
      _activities = _activityBox.values.toList();

      // Sort by creation date
      _discussions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _isInitialized = true;
      notifyListeners();

      debugPrint('SocialService initialized successfully');
      debugPrint(
          'Loaded ${_follows.length} follows, ${_discussions.length} discussions');
    } catch (e) {
      debugPrint('Error initializing SocialService: $e');
      // Rethrow the error for handling in the constructor
      rethrow;
    }
  }

  // FOLLOW SYSTEM

  Future<bool> followUser(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) return false;
    if (!_isInitialized) {
      debugPrint(
          'Error: SocialService not initialized yet, cannot follow user');
      return false;
    }

    try {
      // Check if already following
      final existingFollow = _follows.firstWhere(
        (f) =>
            f.followerId == currentUserId &&
            f.followingId == targetUserId &&
            f.isActive,
        orElse: () => FollowRelationship(
            id: '', followerId: '', followingId: '', createdAt: DateTime.now()),
      );

      if (existingFollow.id.isNotEmpty) {
        return false; // Already following
      }

      // Create new follow relationship
      final follow = FollowRelationship(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        followerId: currentUserId,
        followingId: targetUserId,
        createdAt: DateTime.now(),
      );

      await _followBox.put(follow.id, follow);
      _follows.add(follow);

      // Update user following/followers lists
      await _updateUserFollowCounts(currentUserId, targetUserId, true);

      // Create notification
      final targetUser = _userBox.get(targetUserId);
      if (targetUser != null) {
        await _createNotification(
          targetUserId,
          currentUserId,
          _getUserName(currentUserId),
          NotificationType.follow,
          'New Follower',
          '${_getUserName(currentUserId)} started following you',
        );
      }

      // Create activity
      await _createActivity(
        currentUserId,
        ActivityType.userFollowed,
        'Started following ${_getUserName(targetUserId)}',
        'New connection made',
        targetUserId,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error following user: $e');
      return false;
    }
  }

  Future<bool> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      // Find and deactivate follow relationship
      final followIndex = _follows.indexWhere(
        (f) =>
            f.followerId == currentUserId &&
            f.followingId == targetUserId &&
            f.isActive,
      );

      if (followIndex == -1) return false;

      // Mark as inactive instead of deleting
      await _followBox.delete(_follows[followIndex].id);
      _follows.removeAt(followIndex);

      // Update user following/followers lists
      await _updateUserFollowCounts(currentUserId, targetUserId, false);

      // Create notification
      await _createNotification(
        targetUserId,
        currentUserId,
        _getUserName(currentUserId),
        NotificationType.unfollow,
        'Unfollowed',
        '${_getUserName(currentUserId)} unfollowed you',
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      return false;
    }
  }

  bool isFollowing(String currentUserId, String targetUserId) {
    // Silently return false if not initialized - this is expected during startup
    if (!_isInitialized) {
      return false;
    }

    return _follows.any(
      (f) =>
          f.followerId == currentUserId &&
          f.followingId == targetUserId &&
          f.isActive,
    );
  }

  List<String> getFollowers(String userId) {
    return _follows
        .where((f) => f.followingId == userId && f.isActive)
        .map((f) => f.followerId)
        .toList();
  }

  List<String> getFollowing(String userId) {
    return _follows
        .where((f) => f.followerId == userId && f.isActive)
        .map((f) => f.followingId)
        .toList();
  }

  int getFollowerCount(String userId) {
    return getFollowers(userId).length;
  }

  int getFollowingCount(String userId) {
    return getFollowing(userId).length;
  }

  // DISCUSSION THREADS

  Future<String> createDiscussion({
    required String title,
    required String content,
    required String authorId,
    String? paperId,
    List<String> tags = const [],
    DiscussionCategory category = DiscussionCategory.general,
  }) async {
    try {
      final discussion = DiscussionThread(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        authorId: authorId,
        authorName: _getUserName(authorId),
        paperId: paperId,
        tags: tags,
        createdAt: DateTime.now(),
        category: category,
      );

      await _discussionBox.put(discussion.id, discussion);
      _discussions.insert(0, discussion);

      // Create activity
      await _createActivity(
        authorId,
        ActivityType.discussionCreated,
        'Started a discussion: $title',
        content.length > 100 ? '${content.substring(0, 100)}...' : content,
        discussion.id,
      );

      notifyListeners();
      return discussion.id;
    } catch (e) {
      debugPrint('Error creating discussion: $e');
      return '';
    }
  }

  Future<bool> addDiscussionComment({
    required String threadId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final threadIndex = _discussions.indexWhere((d) => d.id == threadId);
      if (threadIndex == -1) return false;

      final comment = DiscussionComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        threadId: threadId,
        userId: userId,
        userName: _getUserName(userId),
        content: content,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
      );

      final thread = _discussions[threadIndex];
      final updatedComments = List<DiscussionComment>.from(thread.comments)
        ..add(comment);

      final updatedThread = thread.copyWith(
        comments: updatedComments,
        updatedAt: DateTime.now(),
      );

      await _discussionBox.put(threadId, updatedThread);
      _discussions[threadIndex] = updatedThread;

      // Notify thread author if different user
      if (thread.authorId != userId) {
        await _createNotification(
          thread.authorId,
          userId,
          _getUserName(userId),
          NotificationType.discussionComment,
          'New Comment',
          '${_getUserName(userId)} commented on your discussion "${thread.title}"',
          threadId,
        );
      }

      // Create activity
      await _createActivity(
        userId,
        ActivityType.discussionCommented,
        'Commented on "${thread.title}"',
        content.length > 100 ? '${content.substring(0, 100)}...' : content,
        threadId,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding discussion comment: $e');
      return false;
    }
  }

  Future<bool> reactToDiscussion({
    required String threadId,
    required String userId,
    required DiscussionReactionType reactionType,
  }) async {
    try {
      final threadIndex = _discussions.indexWhere((d) => d.id == threadId);
      if (threadIndex == -1) return false;

      final thread = _discussions[threadIndex];
      final reactions = Map<String, DiscussionReaction>.from(thread.reactions);

      // Toggle reaction
      if (reactions.containsKey(userId) &&
          reactions[userId]!.type == reactionType) {
        reactions.remove(userId); // Remove if same reaction
      } else {
        reactions[userId] = DiscussionReaction(
          userId: userId,
          type: reactionType,
          createdAt: DateTime.now(),
        );
      }

      final updatedThread = thread.copyWith(reactions: reactions);
      await _discussionBox.put(threadId, updatedThread);
      _discussions[threadIndex] = updatedThread;

      // Notify thread author if different user
      if (thread.authorId != userId && reactions.containsKey(userId)) {
        await _createNotification(
          thread.authorId,
          userId,
          _getUserName(userId),
          NotificationType.discussionReaction,
          'New Reaction',
          '${_getUserName(userId)} reacted to your discussion "${thread.title}"',
          threadId,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error reacting to discussion: $e');
      return false;
    }
  }

  // PAPER COMMENTS AND REACTIONS

  Future<bool> addPaperComment({
    required String paperId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    if (!_isInitialized) {
      debugPrint(
          'Error: SocialService not initialized yet, cannot add comment');
      return false;
    }

    try {
      final paper = _paperBox.get(paperId);
      if (paper == null) return false;

      final comment = PaperComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        paperId: paperId,
        userId: userId,
        userName: _getUserName(userId),
        content: content,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
      );

      final updatedComments = List<PaperComment>.from(paper.comments)
        ..add(comment);
      final updatedPaper = paper.copyWith(comments: updatedComments);

      await _paperBox.put(paperId, updatedPaper);

      // Notify paper author if different user
      if (paper.uploadedBy != userId) {
        await _createNotification(
          paper.uploadedBy,
          userId,
          _getUserName(userId),
          NotificationType.paperComment,
          'New Comment',
          '${_getUserName(userId)} commented on your paper "${paper.title}"',
          paperId,
        );
      }

      // Create activity
      await _createActivity(
        userId,
        ActivityType.paperCommented,
        'Commented on "${paper.title}"',
        content.length > 100 ? '${content.substring(0, 100)}...' : content,
        paperId,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding paper comment: $e');
      return false;
    }
  }

  Future<bool> reactToPaper({
    required String paperId,
    required String userId,
    required ReactionType reactionType,
  }) async {
    if (!_isInitialized) {
      debugPrint(
          'Error: SocialService not initialized yet, cannot react to paper');
      return false;
    }

    try {
      final paper = _paperBox.get(paperId);
      if (paper == null) return false;

      final reactions = Map<String, PaperReaction>.from(paper.reactions);

      // Toggle reaction
      if (reactions.containsKey(userId) &&
          reactions[userId]!.type == reactionType) {
        reactions.remove(userId); // Remove if same reaction
      } else {
        reactions[userId] = PaperReaction(
          userId: userId,
          type: reactionType,
          createdAt: DateTime.now(),
        );
      }

      final updatedPaper = paper.copyWith(reactions: reactions);
      await _paperBox.put(paperId, updatedPaper);

      // Notify paper author if different user
      if (paper.uploadedBy != userId && reactions.containsKey(userId)) {
        await _createNotification(
          paper.uploadedBy,
          userId,
          _getUserName(userId),
          NotificationType.paperReaction,
          'New Reaction',
          '${_getUserName(userId)} reacted to your paper "${paper.title}"',
          paperId,
        );
      }

      // Create activity
      await _createActivity(
        userId,
        ActivityType.paperReacted,
        'Reacted to "${paper.title}"',
        'Added ${reactionType.name} reaction',
        paperId,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error reacting to paper: $e');
      return false;
    }
  }

  // NOTIFICATIONS

  Future<void> _createNotification(
    String userId,
    String fromUserId,
    String fromUserName,
    NotificationType type,
    String title,
    String message, [
    String? relatedId,
  ]) async {
    try {
      final notification = SocialNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        type: type,
        title: title,
        message: message,
        relatedId: relatedId,
        createdAt: DateTime.now(),
      );

      await _notificationBox.put(notification.id, notification);
      _notifications.insert(0, notification);
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index == -1) return false;

      final notification = _notifications[index];
      final updatedNotification = notification.copyWith(isRead: true);

      await _notificationBox.put(notificationId, updatedNotification);
      _notifications[index] = updatedNotification;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  List<SocialNotification> getUserNotifications(String userId) {
    return _notifications.where((n) => n.userId == userId).toList();
  }

  int getUnreadNotificationCount(String userId) {
    return _notifications.where((n) => n.userId == userId && !n.isRead).length;
  }

  // ACTIVITY FEED

  Future<void> _createActivity(
    String userId,
    ActivityType type,
    String title,
    String description,
    String? relatedId,
  ) async {
    try {
      final activity = ActivityFeedItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        userName: _getUserName(userId),
        type: type,
        title: title,
        description: description,
        relatedId: relatedId,
        createdAt: DateTime.now(),
      );

      await _activityBox.put(activity.id, activity);
      _activities.insert(0, activity);

      // Keep only last 1000 activities
      if (_activities.length > 1000) {
        final toRemove = _activities.sublist(1000);
        for (final item in toRemove) {
          await _activityBox.delete(item.id);
        }
        _activities = _activities.sublist(0, 1000);
      }
    } catch (e) {
      debugPrint('Error creating activity: $e');
    }
  }

  List<ActivityFeedItem> getFollowingActivities(String userId) {
    final following = getFollowing(userId);
    following.add(userId); // Include own activities

    return _activities
        .where((a) => following.contains(a.userId))
        .take(50)
        .toList();
  }

  // UTILITY METHODS

  Future<void> _updateUserFollowCounts(
      String followerId, String followingId, bool isFollow) async {
    try {
      debugPrint(
          '🔄 Updating follow counts: follower=$followerId, following=$followingId, isFollow=$isFollow');

      // Update follower's following list in Hive
      final follower = _userBox.get(followerId);
      if (follower != null) {
        final following = List<String>.from(follower.following);
        if (isFollow) {
          if (!following.contains(followingId)) following.add(followingId);
        } else {
          following.remove(followingId);
        }
        final updatedFollower = follower.copyWith(following: following);
        await _userBox.put(followerId, updatedFollower);
        debugPrint(
            '✅ Updated Hive: follower now following ${following.length} users');

        // Sync to Firestore
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(followerId)
              .set({
            'following': following,
          }, SetOptions(merge: true));
          debugPrint(
              '✅ Synced follower to Firestore: ${following.length} following');
        } catch (e) {
          debugPrint('❌ Error syncing follower to Firestore: $e');
        }
      }

      // Update following's followers list in Hive
      final following = _userBox.get(followingId);
      if (following != null) {
        final followers = List<String>.from(following.followers);
        if (isFollow) {
          if (!followers.contains(followerId)) followers.add(followerId);
        } else {
          followers.remove(followerId);
        }
        final updatedFollowing = following.copyWith(followers: followers);
        await _userBox.put(followingId, updatedFollowing);
        debugPrint(
            '✅ Updated Hive: target now has ${followers.length} followers');

        // Sync to Firestore
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(followingId)
              .set({
            'followers': followers,
          }, SetOptions(merge: true));
          debugPrint(
              '✅ Synced target to Firestore: ${followers.length} followers');
        } catch (e) {
          debugPrint('❌ Error syncing following to Firestore: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating user follow counts: $e');
    }
  }

  String _getUserName(String userId) {
    final user = _userBox.get(userId);
    return user?.displayName ?? 'Unknown User';
  }

  // SEARCH AND FILTER

  List<DiscussionThread> searchDiscussions(String query) {
    if (query.isEmpty) return _discussions;

    final lowerQuery = query.toLowerCase();
    return _discussions
        .where((d) =>
            d.title.toLowerCase().contains(lowerQuery) ||
            d.content.toLowerCase().contains(lowerQuery) ||
            d.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  List<DiscussionThread> getDiscussionsByCategory(DiscussionCategory category) {
    return _discussions.where((d) => d.category == category).toList();
  }

  List<DiscussionThread> getDiscussionsByPaper(String paperId) {
    return _discussions.where((d) => d.paperId == paperId).toList();
  }

  // CLEANUP

  Future<void> clearOldData() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));

      // Clear old notifications
      final oldNotifications = _notifications
          .where((n) => n.createdAt.isBefore(cutoffDate))
          .toList();
      for (final notification in oldNotifications) {
        await _notificationBox.delete(notification.id);
        _notifications.remove(notification);
      }

      // Clear old activities
      final oldActivities =
          _activities.where((a) => a.createdAt.isBefore(cutoffDate)).toList();
      for (final activity in oldActivities) {
        await _activityBox.delete(activity.id);
        _activities.remove(activity);
      }

      notifyListeners();
      debugPrint('Cleared old social data');
    } catch (e) {
      debugPrint('Error clearing old data: $e');
    }
  }
}
