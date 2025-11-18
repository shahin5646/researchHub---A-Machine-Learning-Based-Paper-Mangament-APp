import 'package:hive/hive.dart';

part 'research_paper.g.dart';

@HiveType(typeId: 0)
class ResearchPaper {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String author;
  @HiveField(3)
  final String journalName;
  @HiveField(4)
  final String year;
  @HiveField(5)
  final String pdfUrl;
  @HiveField(6)
  final String doi;
  @HiveField(7)
  final List<String> keywords;
  @HiveField(8)
  final String abstract; // Keep this required
  @HiveField(9)
  final int citations;
  @HiveField(10)
  final String? authorImagePath;
  @HiveField(11)
  final int? views;
  @HiveField(12)
  final int? downloads;
  @HiveField(13)
  final String? category;
  @HiveField(14)
  final DateTime? publishDate;
  @HiveField(15)
  final bool? isAsset;

  ResearchPaper({
    required this.id,
    required this.title,
    required this.author,
    required this.journalName,
    required this.year,
    required this.pdfUrl,
    required this.doi,
    required this.keywords,
    required this.abstract, // This parameter is required
    this.citations = 0,
    this.authorImagePath,
    this.views,
    this.downloads,
    this.category,
    this.publishDate,
    this.isAsset = false,
  });

  // Add factory method to create from JSON
  factory ResearchPaper.fromJson(Map<String, dynamic> json) {
    return ResearchPaper(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      journalName: json['journalName'] as String,
      year: json['year'] as String,
      pdfUrl: json['pdfUrl'] as String,
      doi: json['doi'] as String,
      keywords: List<String>.from(json['keywords'] ?? []),
      abstract: json['abstract'] as String, // Required field
      citations: json['citations'] as int? ?? 0,
      authorImagePath: json['authorImagePath'] as String?,
      views: json['views'] as int?,
      downloads: json['downloads'] as int?,
      category: json['category'] as String?,
      publishDate: json['publishDate'] != null
          ? DateTime.parse(json['publishDate'])
          : null,
      isAsset: json['isAsset'] as bool? ?? false,
    );
  }

  // Add method to convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'journalName': journalName,
      'year': year,
      'pdfUrl': pdfUrl,
      'doi': doi,
      'keywords': keywords,
      'abstract': abstract, // Include abstract in JSON
      'citations': citations,
      'authorImagePath': authorImagePath,
      'views': views,
      'downloads': downloads,
      'category': category,
      'publishDate': publishDate?.toIso8601String(),
      'isAsset': isAsset,
    };
  }

  // Add copyWith method for easier updates
  ResearchPaper copyWith({
    String? id,
    String? title,
    String? author,
    String? journalName,
    String? year,
    String? pdfUrl,
    String? doi,
    List<String>? keywords,
    String? abstract,
    int? citations,
    String? authorImagePath,
    int? views,
    int? downloads,
    String? category,
    DateTime? publishDate,
    bool? isAsset,
  }) {
    return ResearchPaper(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      journalName: journalName ?? this.journalName,
      year: year ?? this.year,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      doi: doi ?? this.doi,
      keywords: keywords ?? this.keywords,
      abstract: abstract ?? this.abstract,
      citations: citations ?? this.citations,
      authorImagePath: authorImagePath ?? this.authorImagePath,
      views: views ?? this.views,
      downloads: downloads ?? this.downloads,
      category: category ?? this.category,
      publishDate: publishDate ?? this.publishDate,
      isAsset: isAsset ?? this.isAsset,
    );
  }
}
