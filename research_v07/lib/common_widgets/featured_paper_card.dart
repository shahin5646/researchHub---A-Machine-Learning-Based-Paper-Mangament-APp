import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../screens/unified_pdf_viewer.dart';
import '../providers/bookmark_provider.dart';
import '../models/research_paper.dart';
import 'safe_image.dart';

class FeaturedPaperCard extends StatelessWidget {
  final String? title;
  final String? author;
  final String? views;
  final String? downloads;
  final Color color;
  final VoidCallback? onTap;
  final ResearchPaper? paper; // New parameter for full paper data
  final String? paperId; // For bookmark identification

  const FeaturedPaperCard({
    super.key,
    this.title,
    this.author,
    this.views,
    this.downloads,
    required this.color,
    this.onTap,
    this.paper,
    this.paperId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use paper data if available, otherwise use legacy parameters
    final displayTitle = paper?.title ?? title ?? 'Unknown Title';
    final displayAuthor = paper?.author ?? author ?? 'Unknown Author';
    final displayViews = paper?.views?.toString() ?? views ?? '0';
    final displayDownloads = paper?.downloads?.toString() ?? downloads ?? '0';
    final displayAuthorImage =
        paper?.authorImagePath ?? 'assets/images/faculty/noori_siRk.jpg';
    final displayPaperId = paper?.id ?? paperId ?? 'unknown';

    return Card(
      elevation: 0.8,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap ?? () => _handlePaperTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 300,
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with badge and bookmark
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Trending Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Trending',
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  // Bookmark button
                  Consumer<BookmarkProvider>(
                    builder: (context, bookmarkProvider, child) {
                      final isBookmarked =
                          bookmarkProvider.isBookmarked(displayPaperId);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _toggleBookmark(context, displayPaperId),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                key: ValueKey(isBookmarked),
                                color: isBookmarked ? color : Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              Expanded(
                child: Text(
                  displayTitle,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).textTheme.titleMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Author and Stats
              Row(
                children: [
                  // Author Image
                  SafeCircleAvatar(
                    radius: 20,
                    imagePath: displayAuthorImage,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 12),

                  // Author Name and Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayAuthor,
                          style: GoogleFonts.inter(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStat(Icons.remove_red_eye, displayViews),
                            const SizedBox(width: 16),
                            _buildStat(Icons.download, displayDownloads),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePaperTap(BuildContext context) {
    if (paper != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnifiedPdfViewer(
            pdfPath: paper!.pdfUrl,
            title: paper!.title,
            author: paper!.author,
            isAsset: paper!.isAsset ?? false,
          ),
        ),
      );
    }
  }

  void _toggleBookmark(BuildContext context, String paperId) {
    final bookmarkProvider =
        Provider.of<BookmarkProvider>(context, listen: false);
    bookmarkProvider.toggleBookmark(paperId);

    // Show feedback
    final isBookmarked = bookmarkProvider.isBookmarked(paperId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBookmarked ? 'Paper bookmarked!' : 'Bookmark removed',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.6),
              size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class Paper {
  final String title;
  final String author;
  final int viewCount;
  final int downloadCount;
  final String path;

  Paper({
    required this.title,
    required this.author,
    required this.viewCount,
    required this.downloadCount,
    required this.path,
  });
}

class PaperListScreen extends StatelessWidget {
  final List<Paper> papers;

  PaperListScreen({super.key, required this.papers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Papers'),
      ),
      body: ListView.builder(
        itemCount: papers.length,
        itemBuilder: (context, index) {
          final paper = papers[index];
          return FeaturedPaperCard(
            color: Colors.primaries[index % Colors.primaries.length],
            title: paper.title,
            author: paper.author,
            views: '${paper.viewCount}',
            downloads: '${paper.downloadCount}',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UnifiedPdfViewer(
                    pdfPath: paper.path,
                    title: paper.title,
                    author: paper.author,
                    isAsset: paper.path.startsWith('assets/'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
