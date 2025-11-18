import 'package:hive/hive.dart';

part 'social_models.g.dart';

// Follow relationship model
@HiveType(typeId: 40)
class FollowRelationship extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String followerId; // User who is following
  @HiveField(2)
  final String followingId; // User being followed
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  final bool isActive;

  FollowRelationship({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory FollowRelationship.fromJson(Map<String, dynamic> json) {
    return FollowRelationship(
      id: json['id'],
      followerId: json['followerId'],
      followingId: json['followingId'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
    );
  }
}

// Discussion thread model
@HiveType(typeId: 41)
class DiscussionThread extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String content;
  @HiveField(3)
  final String authorId;
  @HiveField(4)
  final String authorName;
  @HiveField(5)
  final String? paperId; // Optional - can be general discussion
  @HiveField(6)
  final List<String> tags;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final DateTime? updatedAt;
  @HiveField(9)
  final List<DiscussionComment> comments;
  @HiveField(10)
  final Map<String, DiscussionReaction> reactions;
  @HiveField(11)
  final int viewCount;
  @HiveField(12)
  final bool isPinned;
  @HiveField(13)
  final bool isLocked;
  @HiveField(14)
  final DiscussionCategory category;

  DiscussionThread({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.paperId,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.comments = const [],
    this.reactions = const {},
    this.viewCount = 0,
    this.isPinned = false,
    this.isLocked = false,
    required this.category,
  });

  DiscussionThread copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? paperId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<DiscussionComment>? comments,
    Map<String, DiscussionReaction>? reactions,
    int? viewCount,
    bool? isPinned,
    bool? isLocked,
    DiscussionCategory? category,
  }) {
    return DiscussionThread(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      paperId: paperId ?? this.paperId,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      comments: comments ?? this.comments,
      reactions: reactions ?? this.reactions,
      viewCount: viewCount ?? this.viewCount,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      category: category ?? this.category,
    );
  }
}

@HiveType(typeId: 42)
enum DiscussionCategory {
  @HiveField(0)
  general,
  @HiveField(1)
  research,
  @HiveField(2)
  methodology,
  @HiveField(3)
  collaboration,
  @HiveField(4)
  feedback,
  @HiveField(5)
  announcement,
}

@HiveType(typeId: 43)
class DiscussionComment extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String threadId;
  @HiveField(2)
  final String userId;
  @HiveField(3)
  final String userName;
  @HiveField(4)
  final String content;
  @HiveField(5)
  final DateTime createdAt;
  @HiveField(6)
  final DateTime? updatedAt;
  @HiveField(7)
  final String? parentCommentId; // For nested replies
  @HiveField(8)
  final List<String> likes;
  @HiveField(9)
  final bool isEdited;
  @HiveField(10)
  final bool isDeleted;

  DiscussionComment({
    required this.id,
    required this.threadId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.parentCommentId,
    this.likes = const [],
    this.isEdited = false,
    this.isDeleted = false,
  });

  DiscussionComment copyWith({
    String? id,
    String? threadId,
    String? userId,
    String? userName,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentCommentId,
    List<String>? likes,
    bool? isEdited,
    bool? isDeleted,
  }) {
    return DiscussionComment(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      likes: likes ?? this.likes,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

@HiveType(typeId: 44)
class DiscussionReaction extends HiveObject {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final DiscussionReactionType type;
  @HiveField(2)
  final DateTime createdAt;

  DiscussionReaction({
    required this.userId,
    required this.type,
    required this.createdAt,
  });
}

@HiveType(typeId: 45)
enum DiscussionReactionType {
  @HiveField(0)
  like,
  @HiveField(1)
  insightful,
  @HiveField(2)
  helpful,
  @HiveField(3)
  agree,
  @HiveField(4)
  disagree,
}

// Notification model for social features
@HiveType(typeId: 46)
class SocialNotification extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId; // Recipient
  @HiveField(2)
  final String fromUserId; // Sender
  @HiveField(3)
  final String fromUserName;
  @HiveField(4)
  final NotificationType type;
  @HiveField(5)
  final String title;
  @HiveField(6)
  final String message;
  @HiveField(7)
  final String? relatedId; // Paper ID, Thread ID, etc.
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final bool isRead;
  @HiveField(10)
  final Map<String, dynamic> data; // Additional context

  SocialNotification({
    required this.id,
    required this.userId,
    required this.fromUserId,
    required this.fromUserName,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    required this.createdAt,
    this.isRead = false,
    this.data = const {},
  });

  SocialNotification copyWith({
    String? id,
    String? userId,
    String? fromUserId,
    String? fromUserName,
    NotificationType? type,
    String? title,
    String? message,
    String? relatedId,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return SocialNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

@HiveType(typeId: 47)
enum NotificationType {
  @HiveField(0)
  follow,
  @HiveField(1)
  unfollow,
  @HiveField(2)
  paperComment,
  @HiveField(3)
  paperReaction,
  @HiveField(4)
  discussionComment,
  @HiveField(5)
  discussionReaction,
  @HiveField(6)
  mention,
  @HiveField(7)
  newPaper,
}

// User activity feed item
@HiveType(typeId: 48)
class ActivityFeedItem extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String userName;
  @HiveField(3)
  final ActivityType type;
  @HiveField(4)
  final String title;
  @HiveField(5)
  final String description;
  @HiveField(6)
  final String? relatedId; // Paper ID, Discussion ID, etc.
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final Map<String, dynamic> metadata;

  ActivityFeedItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.title,
    required this.description,
    this.relatedId,
    required this.createdAt,
    this.metadata = const {},
  });
}

@HiveType(typeId: 49)
enum ActivityType {
  @HiveField(0)
  paperUploaded,
  @HiveField(1)
  paperCommented,
  @HiveField(2)
  paperReacted,
  @HiveField(3)
  discussionCreated,
  @HiveField(4)
  discussionCommented,
  @HiveField(5)
  userFollowed,
  @HiveField(6)
  paperBookmarked,
}
