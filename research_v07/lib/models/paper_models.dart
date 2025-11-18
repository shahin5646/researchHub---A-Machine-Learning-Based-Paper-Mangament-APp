import 'package:hive/hive.dart';
import 'dart:typed_data';
part 'paper_models.g.dart';

@HiveType(typeId: 20)
class ResearchPaper extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final List<String> authors;
  @HiveField(3)
  final String? abstract;
  @HiveField(4)
  final List<String> keywords;
  @HiveField(5)
  final String category;
  @HiveField(6)
  final String? subject;
  @HiveField(7)
  final String? faculty;
  @HiveField(8)
  final String filePath; // Local file path or asset path
  @HiveField(9)
  final String? thumbnailPath;
  @HiveField(10)
  final DateTime publishedDate;
  @HiveField(11)
  final DateTime uploadedAt;
  @HiveField(12)
  final String uploadedBy; // User ID
  @HiveField(13)
  final PaperVisibility visibility;
  @HiveField(14)
  final int views;
  @HiveField(15)
  final int downloads;
  @HiveField(16)
  final double averageRating;
  @HiveField(17)
  final int ratingsCount;
  @HiveField(18)
  final List<String> tags;
  @HiveField(19)
  final String? doi;
  @HiveField(20)
  final String? journal;
  @HiveField(21)
  final String? volume;
  @HiveField(22)
  final String? issue;
  @HiveField(23)
  final String? pages;
  @HiveField(24)
  final List<PaperComment> comments;
  @HiveField(25)
  final Map<String, PaperReaction> reactions;
  @HiveField(26)
  final bool isBookmarked;
  @HiveField(27)
  final bool isDownloaded;
  @HiveField(28)
  final int fileSize; // In bytes
  @HiveField(29)
  final String fileType; // pdf, doc, etc.
  @HiveField(30)
  final String? description; // LinkedIn-style post description
  @HiveField(31)
  final Uint8List? fileBytes; // File bytes for web platform

  ResearchPaper({
    required this.id,
    required this.title,
    required this.authors,
    this.abstract,
    this.keywords = const [],
    required this.category,
    this.subject,
    this.faculty,
    required this.filePath,
    this.thumbnailPath,
    required this.publishedDate,
    required this.uploadedAt,
    required this.uploadedBy,
    this.visibility = PaperVisibility.public,
    this.views = 0,
    this.downloads = 0,
    this.averageRating = 0.0,
    this.ratingsCount = 0,
    this.tags = const [],
    this.doi,
    this.journal,
    this.volume,
    this.issue,
    this.pages,
    this.comments = const [],
    this.reactions = const {},
    this.isBookmarked = false,
    this.isDownloaded = false,
    this.fileSize = 0,
    this.fileType = 'pdf',
    this.description,
    this.fileBytes,
  });

  ResearchPaper copyWith({
    String? id,
    String? title,
    List<String>? authors,
    String? abstract,
    List<String>? keywords,
    String? category,
    String? subject,
    String? faculty,
    String? filePath,
    String? thumbnailPath,
    DateTime? publishedDate,
    DateTime? uploadedAt,
    String? uploadedBy,
    PaperVisibility? visibility,
    int? views,
    int? downloads,
    double? averageRating,
    int? ratingsCount,
    List<String>? tags,
    String? doi,
    String? journal,
    String? volume,
    String? issue,
    String? pages,
    List<PaperComment>? comments,
    Map<String, PaperReaction>? reactions,
    bool? isBookmarked,
    bool? isDownloaded,
    int? fileSize,
    String? fileType,
    String? description,
    Uint8List? fileBytes,
  }) {
    return ResearchPaper(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      abstract: abstract ?? this.abstract,
      keywords: keywords ?? this.keywords,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      faculty: faculty ?? this.faculty,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      publishedDate: publishedDate ?? this.publishedDate,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      visibility: visibility ?? this.visibility,
      views: views ?? this.views,
      downloads: downloads ?? this.downloads,
      averageRating: averageRating ?? this.averageRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      tags: tags ?? this.tags,
      doi: doi ?? this.doi,
      journal: journal ?? this.journal,
      volume: volume ?? this.volume,
      issue: issue ?? this.issue,
      pages: pages ?? this.pages,
      comments: comments ?? this.comments,
      reactions: reactions ?? this.reactions,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      description: description ?? this.description,
      fileBytes: fileBytes ?? this.fileBytes,
    );
  }
}

@HiveType(typeId: 21)
enum PaperVisibility {
  @HiveField(0)
  public,
  @HiveField(1)
  private,
  @HiveField(2)
  restricted, // Only for specific roles
}

@HiveType(typeId: 22)
class PaperComment extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String paperId;
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
  final List<String> likes;
  @HiveField(8)
  final String? parentCommentId; // For replies

  PaperComment({
    required this.id,
    required this.paperId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.likes = const [],
    this.parentCommentId,
  });
}

@HiveType(typeId: 23)
class PaperReaction extends HiveObject {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final ReactionType type;
  @HiveField(2)
  final DateTime createdAt;

  PaperReaction({
    required this.userId,
    required this.type,
    required this.createdAt,
  });
}

@HiveType(typeId: 24)
enum ReactionType {
  @HiveField(0)
  like,
  @HiveField(1)
  love,
  @HiveField(2)
  insightful,
  @HiveField(3)
  helpful,
  @HiveField(4)
  bookmark,
}

@HiveType(typeId: 25)
class PaperCategory extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String icon;
  @HiveField(4)
  final String color;
  @HiveField(5)
  final List<String> subcategories;
  @HiveField(6)
  final bool isActive;

  PaperCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.subcategories = const [],
    this.isActive = true,
  });
}
