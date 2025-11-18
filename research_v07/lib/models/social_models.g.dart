// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FollowRelationshipAdapter extends TypeAdapter<FollowRelationship> {
  @override
  final int typeId = 40;

  @override
  FollowRelationship read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FollowRelationship(
      id: fields[0] as String,
      followerId: fields[1] as String,
      followingId: fields[2] as String,
      createdAt: fields[3] as DateTime,
      isActive: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FollowRelationship obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.followerId)
      ..writeByte(2)
      ..write(obj.followingId)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowRelationshipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiscussionThreadAdapter extends TypeAdapter<DiscussionThread> {
  @override
  final int typeId = 41;

  @override
  DiscussionThread read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiscussionThread(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      authorId: fields[3] as String,
      authorName: fields[4] as String,
      paperId: fields[5] as String?,
      tags: (fields[6] as List).cast<String>(),
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime?,
      comments: (fields[9] as List).cast<DiscussionComment>(),
      reactions: (fields[10] as Map).cast<String, DiscussionReaction>(),
      viewCount: fields[11] as int,
      isPinned: fields[12] as bool,
      isLocked: fields[13] as bool,
      category: fields[14] as DiscussionCategory,
    );
  }

  @override
  void write(BinaryWriter writer, DiscussionThread obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.authorId)
      ..writeByte(4)
      ..write(obj.authorName)
      ..writeByte(5)
      ..write(obj.paperId)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.comments)
      ..writeByte(10)
      ..write(obj.reactions)
      ..writeByte(11)
      ..write(obj.viewCount)
      ..writeByte(12)
      ..write(obj.isPinned)
      ..writeByte(13)
      ..write(obj.isLocked)
      ..writeByte(14)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscussionThreadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiscussionCommentAdapter extends TypeAdapter<DiscussionComment> {
  @override
  final int typeId = 43;

  @override
  DiscussionComment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiscussionComment(
      id: fields[0] as String,
      threadId: fields[1] as String,
      userId: fields[2] as String,
      userName: fields[3] as String,
      content: fields[4] as String,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime?,
      parentCommentId: fields[7] as String?,
      likes: (fields[8] as List).cast<String>(),
      isEdited: fields[9] as bool,
      isDeleted: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DiscussionComment obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.threadId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.userName)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.parentCommentId)
      ..writeByte(8)
      ..write(obj.likes)
      ..writeByte(9)
      ..write(obj.isEdited)
      ..writeByte(10)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscussionCommentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiscussionReactionAdapter extends TypeAdapter<DiscussionReaction> {
  @override
  final int typeId = 44;

  @override
  DiscussionReaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiscussionReaction(
      userId: fields[0] as String,
      type: fields[1] as DiscussionReactionType,
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DiscussionReaction obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscussionReactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SocialNotificationAdapter extends TypeAdapter<SocialNotification> {
  @override
  final int typeId = 46;

  @override
  SocialNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SocialNotification(
      id: fields[0] as String,
      userId: fields[1] as String,
      fromUserId: fields[2] as String,
      fromUserName: fields[3] as String,
      type: fields[4] as NotificationType,
      title: fields[5] as String,
      message: fields[6] as String,
      relatedId: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      isRead: fields[9] as bool,
      data: (fields[10] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SocialNotification obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.fromUserId)
      ..writeByte(3)
      ..write(obj.fromUserName)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.message)
      ..writeByte(7)
      ..write(obj.relatedId)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isRead)
      ..writeByte(10)
      ..write(obj.data);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityFeedItemAdapter extends TypeAdapter<ActivityFeedItem> {
  @override
  final int typeId = 48;

  @override
  ActivityFeedItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityFeedItem(
      id: fields[0] as String,
      userId: fields[1] as String,
      userName: fields[2] as String,
      type: fields[3] as ActivityType,
      title: fields[4] as String,
      description: fields[5] as String,
      relatedId: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      metadata: (fields[8] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ActivityFeedItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.relatedId)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityFeedItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiscussionCategoryAdapter extends TypeAdapter<DiscussionCategory> {
  @override
  final int typeId = 42;

  @override
  DiscussionCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DiscussionCategory.general;
      case 1:
        return DiscussionCategory.research;
      case 2:
        return DiscussionCategory.methodology;
      case 3:
        return DiscussionCategory.collaboration;
      case 4:
        return DiscussionCategory.feedback;
      case 5:
        return DiscussionCategory.announcement;
      default:
        return DiscussionCategory.general;
    }
  }

  @override
  void write(BinaryWriter writer, DiscussionCategory obj) {
    switch (obj) {
      case DiscussionCategory.general:
        writer.writeByte(0);
        break;
      case DiscussionCategory.research:
        writer.writeByte(1);
        break;
      case DiscussionCategory.methodology:
        writer.writeByte(2);
        break;
      case DiscussionCategory.collaboration:
        writer.writeByte(3);
        break;
      case DiscussionCategory.feedback:
        writer.writeByte(4);
        break;
      case DiscussionCategory.announcement:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscussionCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiscussionReactionTypeAdapter
    extends TypeAdapter<DiscussionReactionType> {
  @override
  final int typeId = 45;

  @override
  DiscussionReactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DiscussionReactionType.like;
      case 1:
        return DiscussionReactionType.insightful;
      case 2:
        return DiscussionReactionType.helpful;
      case 3:
        return DiscussionReactionType.agree;
      case 4:
        return DiscussionReactionType.disagree;
      default:
        return DiscussionReactionType.like;
    }
  }

  @override
  void write(BinaryWriter writer, DiscussionReactionType obj) {
    switch (obj) {
      case DiscussionReactionType.like:
        writer.writeByte(0);
        break;
      case DiscussionReactionType.insightful:
        writer.writeByte(1);
        break;
      case DiscussionReactionType.helpful:
        writer.writeByte(2);
        break;
      case DiscussionReactionType.agree:
        writer.writeByte(3);
        break;
      case DiscussionReactionType.disagree:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscussionReactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final int typeId = 47;

  @override
  NotificationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationType.follow;
      case 1:
        return NotificationType.unfollow;
      case 2:
        return NotificationType.paperComment;
      case 3:
        return NotificationType.paperReaction;
      case 4:
        return NotificationType.discussionComment;
      case 5:
        return NotificationType.discussionReaction;
      case 6:
        return NotificationType.mention;
      case 7:
        return NotificationType.newPaper;
      default:
        return NotificationType.follow;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    switch (obj) {
      case NotificationType.follow:
        writer.writeByte(0);
        break;
      case NotificationType.unfollow:
        writer.writeByte(1);
        break;
      case NotificationType.paperComment:
        writer.writeByte(2);
        break;
      case NotificationType.paperReaction:
        writer.writeByte(3);
        break;
      case NotificationType.discussionComment:
        writer.writeByte(4);
        break;
      case NotificationType.discussionReaction:
        writer.writeByte(5);
        break;
      case NotificationType.mention:
        writer.writeByte(6);
        break;
      case NotificationType.newPaper:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityTypeAdapter extends TypeAdapter<ActivityType> {
  @override
  final int typeId = 49;

  @override
  ActivityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityType.paperUploaded;
      case 1:
        return ActivityType.paperCommented;
      case 2:
        return ActivityType.paperReacted;
      case 3:
        return ActivityType.discussionCreated;
      case 4:
        return ActivityType.discussionCommented;
      case 5:
        return ActivityType.userFollowed;
      case 6:
        return ActivityType.paperBookmarked;
      default:
        return ActivityType.paperUploaded;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityType obj) {
    switch (obj) {
      case ActivityType.paperUploaded:
        writer.writeByte(0);
        break;
      case ActivityType.paperCommented:
        writer.writeByte(1);
        break;
      case ActivityType.paperReacted:
        writer.writeByte(2);
        break;
      case ActivityType.discussionCreated:
        writer.writeByte(3);
        break;
      case ActivityType.discussionCommented:
        writer.writeByte(4);
        break;
      case ActivityType.userFollowed:
        writer.writeByte(5);
        break;
      case ActivityType.paperBookmarked:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
