import 'dart:io';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import '../models/paper_models.dart';
import '../models/firebase_paper.dart';
import 'firebase_paper_service.dart';
import 'comment_service.dart';

/// Migration progress callback
typedef ProgressCallback = void Function(int current, int total, String status);

/// Service to migrate papers from Hive to Firestore
class PaperMigrationService {
  final FirebasePaperService _firebasePaperService = FirebasePaperService();
  final CommentService _commentService = CommentService();
  final Logger _logger = Logger('PaperMigrationService');

  /// Migrate all papers from Hive to Firestore
  ///
  /// [userId] - The ID of the user who owns the papers
  /// [onProgress] - Optional callback for migration progress updates
  /// Returns: Number of papers successfully migrated
  Future<int> migrateAllPapers({
    required String userId,
    ProgressCallback? onProgress,
  }) async {
    int successCount = 0;

    try {
      _logger.info('Starting paper migration for user: $userId');

      // Open Hive box
      final box = await Hive.openBox<ResearchPaper>('papers');
      final papers = box.values.toList();
      final totalPapers = papers.length;

      _logger.info('Found $totalPapers papers to migrate');

      if (totalPapers == 0) {
        _logger.info('No papers to migrate');
        return 0;
      }

      // Migrate each paper
      for (int i = 0; i < papers.length; i++) {
        final hivePaper = papers[i];

        try {
          onProgress?.call(i + 1, totalPapers, 'Migrating: ${hivePaper.title}');

          await _migrateSinglePaper(hivePaper, userId);
          successCount++;

          _logger
              .info('Migrated paper ${i + 1}/$totalPapers: ${hivePaper.title}');
        } catch (e) {
          _logger
              .severe('Failed to migrate paper: ${hivePaper.title}, Error: $e');
          onProgress?.call(i + 1, totalPapers, 'Failed: ${hivePaper.title}');
        }
      }

      _logger.info(
          'Migration completed: $successCount/$totalPapers papers migrated successfully');

      return successCount;
    } catch (e) {
      _logger.severe('Migration failed: $e');
      rethrow;
    }
  }

  /// Migrate a single paper from Hive to Firestore
  Future<String?> _migrateSinglePaper(
      ResearchPaper hivePaper, String userId) async {
    try {
      String? pdfUrl;
      String? thumbnailUrl;

      // Generate paper ID first
      final paperId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload PDF to Firebase Storage if local file exists
      if (hivePaper.filePath.isNotEmpty) {
        final pdfFile = File(hivePaper.filePath);
        if (await pdfFile.exists()) {
          _logger.info('Uploading PDF: ${hivePaper.filePath}');
          pdfUrl = await _firebasePaperService.uploadPaperFile(
            file: pdfFile,
            userId: userId,
            paperId: paperId,
          );
        } else {
          _logger.warning('PDF file not found: ${hivePaper.filePath}');
        }
      }

      // Upload thumbnail to Firebase Storage if local file exists
      if (hivePaper.thumbnailPath != null &&
          hivePaper.thumbnailPath!.isNotEmpty) {
        final thumbnailFile = File(hivePaper.thumbnailPath!);
        if (await thumbnailFile.exists()) {
          _logger.info('Uploading thumbnail: ${hivePaper.thumbnailPath}');
          thumbnailUrl = await _firebasePaperService.uploadThumbnail(
            file: thumbnailFile,
            userId: userId,
            paperId: paperId,
          );
        } else {
          _logger
              .warning('Thumbnail file not found: ${hivePaper.thumbnailPath}');
        }
      }

      // Create FirebasePaper from Hive data
      final firebasePaper = FirebasePaper(
        id: paperId,
        title: hivePaper.title,
        authors: hivePaper.authors,
        abstract: hivePaper.abstract,
        keywords: hivePaper.keywords,
        category: hivePaper.category,
        subject: hivePaper.subject,
        faculty: hivePaper.faculty,
        pdfUrl: pdfUrl ?? '',
        thumbnailUrl: thumbnailUrl,
        publishedDate: hivePaper.publishedDate,
        uploadedAt: hivePaper.uploadedAt,
        uploadedBy: userId,
        visibility: 'public', // Default visibility
        views: hivePaper.views,
        downloads: hivePaper.downloads,
        likesCount: 0, // Reset reactions for Firebase
        commentsCount: hivePaper.comments.length,
        sharesCount: 0,
        tags: hivePaper.tags,
        journal: hivePaper.journal,
        fileSize: hivePaper.fileSize,
        fileType: 'pdf',
        description: hivePaper.description,
      );

      // Save to Firestore
      final createdPaperId =
          await _firebasePaperService.createPaper(firebasePaper);
      _logger.info('Paper created in Firestore with ID: $createdPaperId');

      // Migrate comments if any
      if (hivePaper.comments.isNotEmpty) {
        await _migrateComments(createdPaperId, hivePaper.comments, userId);
      }

      return createdPaperId;
    } catch (e) {
      _logger.severe('Error migrating paper: ${hivePaper.title}, Error: $e');
      rethrow;
    }
  }

  /// Migrate comments for a paper
  Future<void> _migrateComments(
    String paperId,
    List<dynamic> hiveComments,
    String userId,
  ) async {
    try {
      _logger.info(
          'Migrating ${hiveComments.length} comments for paper: $paperId');

      for (var comment in hiveComments) {
        // Extract comment data
        String content = '';

        if (comment is Map) {
          content = comment['content']?.toString() ?? '';
        } else if (comment is String) {
          content = comment;
        }

        if (content.isNotEmpty) {
          // Create comment using CommentService
          try {
            await _commentService.addComment(
              paperId: paperId,
              userId: userId,
              userName: 'Migrated User',
              content: content,
            );
          } catch (e) {
            _logger.warning('Error migrating individual comment: $e');
          }
        }
      }

      _logger.info('Comments migrated successfully');
    } catch (e) {
      _logger.warning('Error migrating comments: $e');
    }
  }

  /// Verify migration by comparing counts
  Future<Map<String, int>> verifyMigration(String userId) async {
    try {
      // Count papers in Hive
      final hiveBox = await Hive.openBox<ResearchPaper>('papers');
      final hiveCount = hiveBox.length;

      // Count papers in Firestore
      final firestorePapers = await _firebasePaperService.getUserPapers(userId);
      final firestoreCount = firestorePapers.length;

      _logger.info('Verification: Hive=$hiveCount, Firestore=$firestoreCount');

      return {
        'hive': hiveCount,
        'firestore': firestoreCount,
        'missing': hiveCount - firestoreCount,
      };
    } catch (e) {
      _logger.severe('Error verifying migration: $e');
      return {'hive': 0, 'firestore': 0, 'missing': 0};
    }
  }

  /// Clean up Hive data after successful migration
  /// USE WITH CAUTION - This will delete all local papers
  Future<void> cleanupHiveData() async {
    try {
      _logger.warning('Cleaning up Hive data - THIS WILL DELETE LOCAL PAPERS');

      final box = await Hive.openBox<ResearchPaper>('papers');
      await box.clear();

      _logger.info('Hive data cleaned up successfully');
    } catch (e) {
      _logger.severe('Error cleaning up Hive data: $e');
      rethrow;
    }
  }

  /// Rollback migration - delete all Firestore papers for user
  /// USE WITH EXTREME CAUTION - This will delete all cloud papers
  Future<void> rollbackMigration(String userId) async {
    try {
      _logger.warning(
          'Rolling back migration - THIS WILL DELETE FIRESTORE PAPERS');

      final papers = await _firebasePaperService.getUserPapers(userId);

      for (var paper in papers) {
        await _firebasePaperService.deletePaper(paper.id, userId);
      }

      _logger.info('Migration rolled back successfully');
    } catch (e) {
      _logger.severe('Error rolling back migration: $e');
      rethrow;
    }
  }
}
