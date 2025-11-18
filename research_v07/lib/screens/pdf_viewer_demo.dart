import 'package:flutter/material.dart';
import '../screens/unified_pdf_viewer.dart';

/// Simple demonstration of how to use the UnifiedPdfViewer
/// This shows how to open PDFs with the new pdfrx-based viewer
class PdfViewerDemo extends StatelessWidget {
  const PdfViewerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer Demo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Unified PDF Viewer Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This demonstrates the new unified PDF viewer using pdfrx. '
              'It provides consistent cross-platform PDF viewing with features like:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const BulletPoint(
                text: 'Cross-platform compatibility (Web, Mobile, Desktop)'),
            const BulletPoint(text: 'Zoom controls and pan gestures'),
            const BulletPoint(text: 'Page navigation with thumbnails'),
            const BulletPoint(text: 'Search functionality (UI ready)'),
            const BulletPoint(text: 'Download and share capabilities'),
            const BulletPoint(text: 'Dark/light theme support'),
            const BulletPoint(text: 'Responsive design'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openSamplePdf(context),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Open Sample PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openAssetPdf(context),
              icon: const Icon(Icons.folder_open),
              label: const Text('Open Asset PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Features',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Unified API for all platforms\n'
                    '• Smooth scrolling and zooming\n'
                    '• Page thumbnails and outline\n'
                    '• Text selection and search\n'
                    '• Customizable toolbar\n'
                    '• Memory efficient rendering',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSamplePdf(BuildContext context) {
    // This would open a sample PDF - for demo purposes
    // In a real app, you'd have an actual PDF path
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UnifiedPdfViewer(
          pdfPath: 'assets/papers/sample.pdf', // This would be a real path
          title: 'Sample Research Paper',
          author: 'Dr. Sample Author',
          isAsset: true,
        ),
      ),
    );
  }

  void _openAssetPdf(BuildContext context) {
    // Example of opening an actual asset PDF from the papers directory
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UnifiedPdfViewer(
          pdfPath:
              'assets/papers/DrImran_Mahmud/A_Novel_Front_Door_Security_FDS_Algorithm_Using_GoogleNet-BiLSTM_Hybridization.pdf',
          title:
              'A Novel Front Door Security (FDS) Algorithm Using GoogleNet-BiLSTM Hybridization',
          author: 'Dr. Imran Mahmud',
          isAsset: true,
        ),
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
