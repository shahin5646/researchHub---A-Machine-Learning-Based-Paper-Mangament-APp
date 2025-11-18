import 'package:flutter/material.dart';
import '../models/research_paper.dart';
import '../screens/unified_pdf_viewer.dart';
import 'ui_integration_service.dart';

/// A service to open PDF documents from anywhere in the app
class PdfViewerService {
  static final PdfViewerService _instance = PdfViewerService._internal();
  factory PdfViewerService() => _instance;
  PdfViewerService._internal();

  final UIIntegrationService _uiService = UIIntegrationService();

  /// Opens a PDF document from a ResearchPaper model
  Future<void> openPaperPdf(
    BuildContext context,
    ResearchPaper paper, {
    bool isAsset = true,
    String? userId = 'current_user',
  }) async {
    // Track the view
    await _uiService.trackPaperView(paper.id, userId ?? 'current_user');

    // Open the PDF viewer
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnifiedPdfViewer(
            pdfPath: paper.pdfUrl,
            title: paper.title,
            author: paper.author,
            isAsset: isAsset,
          ),
        ),
      );
    }
  }

  /// Opens a PDF document from a direct path
  Future<void> openPdfFromPath(
    BuildContext context, {
    required String path,
    required String title,
    String author = 'Unknown',
    bool isAsset = true,
  }) async {
    // Open the PDF viewer
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnifiedPdfViewer(
            pdfPath: path,
            title: title,
            author: author,
            isAsset: isAsset,
          ),
        ),
      );
    }
  }

  /// Opens a PDF document in a dialog (useful for quick previews)
  Future<void> openPdfInDialog(
    BuildContext context, {
    required String path,
    required String title,
    String author = 'Unknown',
    bool isAsset = true,
  }) async {
    // Show dialog with PDF preview
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.8,
              child: UnifiedPdfViewer(
                pdfPath: path,
                title: title,
                author: author,
                isAsset: isAsset,
              ),
            ),
          ),
        ),
      );
    }
  }

  /// Opens a PDF document in a bottom sheet (useful for mobile)
  Future<void> openPdfInBottomSheet(
    BuildContext context, {
    required String path,
    required String title,
    String author = 'Unknown',
    bool isAsset = true,
  }) async {
    // Show bottom sheet with PDF preview
    if (context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Expanded(
                  child: UnifiedPdfViewer(
                    pdfPath: path,
                    title: title,
                    author: author,
                    isAsset: isAsset,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
