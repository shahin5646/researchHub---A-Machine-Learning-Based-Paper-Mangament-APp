import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as classic_provider;
import '../../theme/app_theme.dart';
import '../../models/paper_models.dart';
import '../../services/paper_service.dart';
import '../unified_pdf_viewer.dart';

class MyPapersScreen extends ConsumerWidget {
  const MyPapersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return classic_provider.Consumer<PaperService>(
      builder: (context, paperService, child) {
        final papers = paperService.papers;
        debugPrint('MyPapersScreen - Papers count: ${papers.length}');

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // Minimal 68px AppBar
                Container(
                  height: 68,
                  color: bgColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Bordered back button
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.arrow_back,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title
                      Expanded(
                        child: Text(
                          'My Papers',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: papers.isEmpty
                      ? _buildEmptyState(context, isDark)
                      : CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final paper = papers[index];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: _buildPaperCard(
                                          context, paper, isDark),
                                    );
                                  },
                                  childCount: papers.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          Text(
            'No Papers Yet',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first research paper to get started',
            style: GoogleFonts.inter(
              fontSize: 16,
              letterSpacing: -0.3,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaperCard(
      BuildContext context, ResearchPaper paper, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and visibility status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  paper.title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: titleColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getVisibilityColor(paper.visibility),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  paper.visibility.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Authors
          Text(
            paper.authors.join(', '),
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF3B82F6),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Abstract
          Text(
            paper.abstract ?? 'No abstract available',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textColor,
              letterSpacing: -0.2,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Stats
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatChip(Icons.visibility_rounded, paper.views.toString(),
                  'Views', isDark),
              _buildStatChip(Icons.download_rounded, paper.downloads.toString(),
                  'Downloads', isDark),
              _buildStatChip(Icons.star_rounded,
                  paper.averageRating.toStringAsFixed(1), 'Rating', isDark),
            ],
          ),
          const SizedBox(height: 18),

          // Action buttons - Professional Layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _viewPaper(context, paper),
                      borderRadius: BorderRadius.circular(10),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility_rounded,
                                size: 18, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 6),
                            Text(
                              'View',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _changeVisibility(context, paper),
                      borderRadius: BorderRadius.circular(10),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.security,
                                size: 18, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 6),
                            Text(
                              'Privacy',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFFEF4444), width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _deletePaper(context, paper),
                      borderRadius: BorderRadius.circular(10),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.delete_rounded,
                                size: 18, color: Color(0xFFEF4444)),
                            const SizedBox(width: 6),
                            Text(
                              'Delete',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      IconData icon, String value, String label, bool isDark) {
    final iconColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: iconColor,
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Color _getVisibilityColor(PaperVisibility visibility) {
    switch (visibility) {
      case PaperVisibility.public:
        return Colors.green;
      case PaperVisibility.private:
        return Colors.orange;
      case PaperVisibility.restricted:
        return Colors.red;
    }
  }

  void _viewPaper(BuildContext context, ResearchPaper paper) {
    debugPrint('Viewing paper: ${paper.title}');

    // Navigate to unified PDF viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedPdfViewer(
          pdfPath: paper.filePath,
          title: paper.title,
          author: paper.authors.isNotEmpty ? paper.authors.first : 'Unknown',
          isAsset: paper.filePath.startsWith('assets/'),
        ),
      ),
    );
  }

  void _changeVisibility(BuildContext context, ResearchPaper paper) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Visibility',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select visibility for "${paper.title}"',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 16),
            ...PaperVisibility.values.map(
              (visibility) => ListTile(
                leading: Icon(
                  paper.visibility == visibility
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _getVisibilityColor(visibility),
                ),
                title: Text(
                  visibility.name.toUpperCase(),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _getVisibilityDescription(visibility),
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _updateVisibility(context, paper, visibility);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  String _getVisibilityDescription(PaperVisibility visibility) {
    switch (visibility) {
      case PaperVisibility.public:
        return 'Visible to everyone';
      case PaperVisibility.private:
        return 'Only visible to you';
      case PaperVisibility.restricted:
        return 'Visible to specific roles only';
    }
  }

  void _updateVisibility(BuildContext context, ResearchPaper paper,
      PaperVisibility newVisibility) async {
    try {
      final paperService =
          classic_provider.Provider.of<PaperService>(context, listen: false);
      // Create updated paper with new visibility
      final updatedPaper = paper.copyWith(visibility: newVisibility);
      await paperService.updatePaper(updatedPaper);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visibility updated to ${newVisibility.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating visibility: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deletePaper(BuildContext context, ResearchPaper paper) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Paper',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${paper.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeletePaper(context, paper);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePaper(BuildContext context, ResearchPaper paper) async {
    try {
      final paperService =
          classic_provider.Provider.of<PaperService>(context, listen: false);
      await paperService.deletePaper(paper.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paper deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting paper: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
