// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paper_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResearchPaperAdapter extends TypeAdapter<ResearchPaper> {
  @override
  final int typeId = 20;

  @override
  ResearchPaper read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResearchPaper(
      id: fields[0] as String,
      title: fields[1] as String,
      authors: (fields[2] as List).cast<String>(),
      abstract: fields[3] as String?,
      keywords: (fields[4] as List).cast<String>(),
      category: fields[5] as String,
      subject: fields[6] as String?,
      faculty: fields[7] as String?,
      filePath: fields[8] as String,
      thumbnailPath: fields[9] as String?,
      publishedDate: fields[10] as DateTime,
      uploadedAt: fields[11] as DateTime,
      uploadedBy: fields[12] as String,
      visibility: fields[13] as PaperVisibility,
      views: fields[14] as int,
      downloads: fields[15] as int,
      averageRating: fields[16] as double,
      ratingsCount: fields[17] as int,
      tags: (fields[18] as List).cast<String>(),
      doi: fields[19] as String?,
      journal: fields[20] as String?,
      volume: fields[21] as String?,
      issue: fields[22] as String?,
      pages: fields[23] as String?,
      comments: (fields[24] as List).cast<PaperComment>(),
      reactions: (fields[25] as Map).cast<String, PaperReaction>(),
      isBookmarked: fields[26] as bool,
      isDownloaded: fields[27] as bool,
      fileSize: fields[28] as int,
      fileType: fields[29] as String,
      description: fields[30] as String?,
      fileBytes: fields[31] as Uint8List?,
    );
  }

  @override
  void write(BinaryWriter writer, ResearchPaper obj) {
    writer
      ..writeByte(32)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.authors)
      ..writeByte(3)
      ..write(obj.abstract)
      ..writeByte(4)
      ..write(obj.keywords)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.subject)
      ..writeByte(7)
      ..write(obj.faculty)
      ..writeByte(8)
      ..write(obj.filePath)
      ..writeByte(9)
      ..write(obj.thumbnailPath)
      ..writeByte(10)
      ..write(obj.publishedDate)
      ..writeByte(11)
      ..write(obj.uploadedAt)
      ..writeByte(12)
      ..write(obj.uploadedBy)
      ..writeByte(13)
      ..write(obj.visibility)
      ..writeByte(14)
      ..write(obj.views)
      ..writeByte(15)
      ..write(obj.downloads)
      ..writeByte(16)
      ..write(obj.averageRating)
      ..writeByte(17)
      ..write(obj.ratingsCount)
      ..writeByte(18)
      ..write(obj.tags)
      ..writeByte(19)
      ..write(obj.doi)
      ..writeByte(20)
      ..write(obj.journal)
      ..writeByte(21)
      ..write(obj.volume)
      ..writeByte(22)
      ..write(obj.issue)
      ..writeByte(23)
      ..write(obj.pages)
      ..writeByte(24)
      ..write(obj.comments)
      ..writeByte(25)
      ..write(obj.reactions)
      ..writeByte(26)
      ..write(obj.isBookmarked)
      ..writeByte(27)
      ..write(obj.isDownloaded)
      ..writeByte(28)
      ..write(obj.fileSize)
      ..writeByte(29)
      ..write(obj.fileType)
      ..writeByte(30)
      ..write(obj.description)
      ..writeByte(31)
      ..write(obj.fileBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResearchPaperAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaperCommentAdapter extends TypeAdapter<PaperComment> {
  @override
  final int typeId = 22;

  @override
  PaperComment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaperComment(
      id: fields[0] as String,
      paperId: fields[1] as String,
      userId: fields[2] as String,
      userName: fields[3] as String,
      content: fields[4] as String,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime?,
      likes: (fields[7] as List).cast<String>(),
      parentCommentId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PaperComment obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.paperId)
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
      ..write(obj.likes)
      ..writeByte(8)
      ..write(obj.parentCommentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaperCommentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaperReactionAdapter extends TypeAdapter<PaperReaction> {
  @override
  final int typeId = 23;

  @override
  PaperReaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaperReaction(
      userId: fields[0] as String,
      type: fields[1] as ReactionType,
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PaperReaction obj) {
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
      other is PaperReactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaperCategoryAdapter extends TypeAdapter<PaperCategory> {
  @override
  final int typeId = 25;

  @override
  PaperCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaperCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      icon: fields[3] as String,
      color: fields[4] as String,
      subcategories: (fields[5] as List).cast<String>(),
      isActive: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PaperCategory obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.subcategories)
      ..writeByte(6)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaperCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaperVisibilityAdapter extends TypeAdapter<PaperVisibility> {
  @override
  final int typeId = 21;

  @override
  PaperVisibility read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaperVisibility.public;
      case 1:
        return PaperVisibility.private;
      case 2:
        return PaperVisibility.restricted;
      default:
        return PaperVisibility.public;
    }
  }

  @override
  void write(BinaryWriter writer, PaperVisibility obj) {
    switch (obj) {
      case PaperVisibility.public:
        writer.writeByte(0);
        break;
      case PaperVisibility.private:
        writer.writeByte(1);
        break;
      case PaperVisibility.restricted:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaperVisibilityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReactionTypeAdapter extends TypeAdapter<ReactionType> {
  @override
  final int typeId = 24;

  @override
  ReactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReactionType.like;
      case 1:
        return ReactionType.love;
      case 2:
        return ReactionType.insightful;
      case 3:
        return ReactionType.helpful;
      case 4:
        return ReactionType.bookmark;
      default:
        return ReactionType.like;
    }
  }

  @override
  void write(BinaryWriter writer, ReactionType obj) {
    switch (obj) {
      case ReactionType.like:
        writer.writeByte(0);
        break;
      case ReactionType.love:
        writer.writeByte(1);
        break;
      case ReactionType.insightful:
        writer.writeByte(2);
        break;
      case ReactionType.helpful:
        writer.writeByte(3);
        break;
      case ReactionType.bookmark:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
