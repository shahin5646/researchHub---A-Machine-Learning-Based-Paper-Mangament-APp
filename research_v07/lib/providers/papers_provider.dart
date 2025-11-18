import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paper_models.dart';
import '../models/firebase_paper.dart';
import '../services/firebase_paper_service.dart';
import '../services/user_profile_service.dart';
import 'dart:io';

// Legacy provider for backward compatibility with Hive
final papersProvider =
    StateNotifierProvider<PapersNotifier, List<ResearchPaper>>(
  (ref) => PapersNotifier(),
);

class PapersNotifier extends StateNotifier<List<ResearchPaper>> {
  PapersNotifier() : super([]);

  void addPaper(ResearchPaper paper) {
    state = [...state, paper];
  }

  void removePaper(String id) {
    state = state.where((paper) => paper.id != id).toList();
  }

  void clear() {
    state = [];
  }
}

// New Firebase-based provider
final firebasePapersProvider =
    StreamProvider.autoDispose<List<FirebasePaper>>((ref) {
  final paperService = FirebasePaperService();
  return paperService.getPapersStream(limit: 50);
});

// Provider for uploading papers to Firebase
final paperUploadProvider = Provider<PaperUploadService>((ref) {
  return PaperUploadService();
});

class PaperUploadService {
  final FirebasePaperService _paperService = FirebasePaperService();
  final UserProfileService _profileService = UserProfileService();

  Future<String> uploadPaper({
    required String userId,
    required File pdfFile,
    File? thumbnailFile,
    required String title,
    required List<String> authors,
    required String abstract,
    required List<String> keywords,
    required String category,
    required String subject,
    required String faculty,
    String visibility = 'public',
    List<String> tags = const [],
    String? doi,
    String? journal,
    String? description,
  }) async {
    // Generate paper ID first
    final paperId = DateTime.now().millisecondsSinceEpoch.toString();

    // Upload PDF
    final pdfUrl = await _paperService.uploadPaperFile(
      file: pdfFile,
      userId: userId,
      paperId: paperId,
    );

    // Upload thumbnail if provided
    String? thumbnailUrl;
    if (thumbnailFile != null) {
      thumbnailUrl = await _paperService.uploadThumbnail(
        file: thumbnailFile,
        userId: userId,
        paperId: paperId,
      );
    }

    // Create paper
    final paper = FirebasePaper(
      id: paperId,
      title: title,
      authors: authors,
      abstract: abstract,
      keywords: keywords,
      category: category,
      subject: subject,
      faculty: faculty,
      pdfUrl: pdfUrl,
      thumbnailUrl: thumbnailUrl,
      publishedDate: DateTime.now(),
      uploadedAt: DateTime.now(),
      uploadedBy: userId,
      visibility: visibility,
      views: 0,
      downloads: 0,
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      tags: tags,
      fileSize: await pdfFile.length(),
      fileType: 'pdf',
      description: description,
    );

    final createdPaperId = await _paperService.createPaper(paper);

    // Auto-enable public profile if paper is public
    if (visibility == 'public') {
      try {
        await _profileService.enablePublicProfile(userId);
      } catch (e) {
        // Don't fail paper upload if profile update fails
        print('Failed to enable public profile: $e');
      }
    }

    return createdPaperId;
  }
}
