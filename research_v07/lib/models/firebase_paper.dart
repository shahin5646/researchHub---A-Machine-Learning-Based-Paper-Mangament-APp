import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase-compatible Research Paper model
class FirebasePaper {
  final String id;
  final String title;
  final List<String> authors;
  final String? abstract;
  final List<String> keywords;
  final String category;
  final String? subject;
  final String? faculty;

  // Firebase Storage URLs instead of local paths
  final String? pdfUrl;
  final String? thumbnailUrl;

  final DateTime publishedDate;
  final DateTime uploadedAt;
  final String uploadedBy; // User ID
  final String visibility; // 'public', 'private', 'institution'

  // Engagement metrics
  final int views;
  final int downloads;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;

  // Metadata
  final List<String> tags;
  final String? doi;
  final String? journal;
  final String? volume;
  final String? issue;
  final String? pages;

  // File info
  final int fileSize; // In bytes
  final String fileType; // 'pdf', 'doc', etc.

  // Social features
  final String? description; // Post description
  final DateTime? lastUpdated;

  FirebasePaper({
    required this.id,
    required this.title,
    required this.authors,
    this.abstract,
    this.keywords = const [],
    required this.category,
    this.subject,
    this.faculty,
    this.pdfUrl,
    this.thumbnailUrl,
    required this.publishedDate,
    required this.uploadedAt,
    required this.uploadedBy,
    this.visibility = 'public',
    this.views = 0,
    this.downloads = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.tags = const [],
    this.doi,
    this.journal,
    this.volume,
    this.issue,
    this.pages,
    this.fileSize = 0,
    this.fileType = 'pdf',
    this.description,
    this.lastUpdated,
  });

  // Create from Firestore document
  factory FirebasePaper.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safely parse timestamps
    DateTime publishedDate;
    try {
      publishedDate = data['publishedDate'] != null
          ? (data['publishedDate'] as Timestamp).toDate()
          : DateTime.now().subtract(const Duration(days: 365));
    } catch (e) {
      publishedDate = DateTime.now().subtract(const Duration(days: 365));
    }

    DateTime uploadedAt;
    try {
      uploadedAt = data['uploadedAt'] != null
          ? (data['uploadedAt'] as Timestamp).toDate()
          : data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now();
    } catch (e) {
      uploadedAt = DateTime.now();
    }

    return FirebasePaper(
      id: doc.id,
      title: data['title'] ?? '',
      authors: List<String>.from(data['authors'] ?? []),
      abstract: data['abstract'],
      keywords: List<String>.from(data['keywords'] ?? []),
      category: data['category'] ?? 'General',
      subject: data['subject'],
      faculty: data['faculty'],
      pdfUrl: data['pdfUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      publishedDate: publishedDate,
      uploadedAt: uploadedAt,
      uploadedBy: data['uploadedBy'] ?? '',
      visibility: data['visibility'] ?? 'public',
      views: data['views'] ?? 0,
      downloads: data['downloads'] ?? 0,
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      doi: data['doi'],
      journal: data['journal'],
      volume: data['volume'],
      issue: data['issue'],
      pages: data['pages'],
      fileSize: data['fileSize'] ?? 0,
      fileType: data['fileType'] ?? 'pdf',
      description: data['description'],
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'authors': authors,
      'abstract': abstract,
      'keywords': keywords,
      'category': category,
      'subject': subject,
      'faculty': faculty,
      'pdfUrl': pdfUrl,
      'thumbnailUrl': thumbnailUrl,
      'publishedDate': Timestamp.fromDate(publishedDate),
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': uploadedBy,
      'visibility': visibility,
      'views': views,
      'downloads': downloads,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'tags': tags,
      'doi': doi,
      'journal': journal,
      'volume': volume,
      'issue': issue,
      'pages': pages,
      'fileSize': fileSize,
      'fileType': fileType,
      'description': description,
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : FieldValue.serverTimestamp(),
    };
  }

  // Copy with method
  FirebasePaper copyWith({
    String? id,
    String? title,
    List<String>? authors,
    String? abstract,
    List<String>? keywords,
    String? category,
    String? subject,
    String? faculty,
    String? pdfUrl,
    String? thumbnailUrl,
    DateTime? publishedDate,
    DateTime? uploadedAt,
    String? uploadedBy,
    String? visibility,
    int? views,
    int? downloads,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    List<String>? tags,
    String? doi,
    String? journal,
    String? volume,
    String? issue,
    String? pages,
    int? fileSize,
    String? fileType,
    String? description,
    DateTime? lastUpdated,
  }) {
    return FirebasePaper(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      abstract: abstract ?? this.abstract,
      keywords: keywords ?? this.keywords,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      faculty: faculty ?? this.faculty,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      publishedDate: publishedDate ?? this.publishedDate,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      visibility: visibility ?? this.visibility,
      views: views ?? this.views,
      downloads: downloads ?? this.downloads,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      tags: tags ?? this.tags,
      doi: doi ?? this.doi,
      journal: journal ?? this.journal,
      volume: volume ?? this.volume,
      issue: issue ?? this.issue,
      pages: pages ?? this.pages,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      description: description ?? this.description,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Comment model for Firestore
class PaperComment {
  final String id;
  final String paperId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final DateTime timestamp;
  final int likes;
  final List<String> likedBy;
  final String? parentCommentId; // For nested replies

  PaperComment({
    required this.id,
    required this.paperId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.likedBy = const [],
    this.parentCommentId,
  });

  factory PaperComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaperComment(
      id: doc.id,
      paperId: data['paperId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      parentCommentId: data['parentCommentId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'paperId': paperId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'likedBy': likedBy,
      'parentCommentId': parentCommentId,
    };
  }
}

/// Reaction model for Firestore
class PaperReaction {
  final String userId;
  final String type; // 'like', 'love', 'insightful', 'bookmark'
  final DateTime timestamp;

  PaperReaction({
    required this.userId,
    required this.type,
    required this.timestamp,
  });

  factory PaperReaction.fromFirestore(Map<String, dynamic> data) {
    return PaperReaction(
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'like',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
