import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../data/research_papers_data.dart';
import '../models/research_paper.dart';
import '../common_widgets/featured_paper_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F1419) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(isDarkMode),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<BookmarkProvider>(
          builder: (context, bookmarkProvider, child) {
            final bookmarkedPaperIds = bookmarkProvider.bookmarkedPapers;
            final bookmarkedPapers = allResearchPapers
                .where((paper) => bookmarkedPaperIds.contains(paper.id))
                .toList();

            if (bookmarkedPapers.isEmpty) {
              return _buildEmptyState(isDarkMode);
            }

            return _buildBookmarkedPapersList(bookmarkedPapers, isDarkMode);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bookmarked Papers',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          Consumer<BookmarkProvider>(
            builder: (context, bookmarkProvider, child) {
              final count = bookmarkProvider.bookmarkCount;
              return Text(
                '$count ${count == 1 ? 'Paper' : 'Papers'} Saved',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        Consumer<BookmarkProvider>(
          builder: (context, bookmarkProvider, child) {
            if (bookmarkProvider.bookmarkCount > 0) {
              return PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _showClearAllDialog(context, bookmarkProvider);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.clear_all_rounded,
                          size: 20,
                          color: Colors.red[600],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Clear All',
                          style: GoogleFonts.inter(
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBookmarkedPapersList(
      List<ResearchPaper> papers, bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: papers.length,
      itemBuilder: (context, index) {
        final paper = papers[index];
        final colors = [
          const Color(0xFF2196F3),
          const Color(0xFF9C27B0),
          const Color(0xFF4CAF50),
          const Color(0xFFFF9800),
          const Color(0xFFF44336),
          const Color(0xFF00BCD4),
        ];
        final color = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FeaturedPaperCard(
            paper: paper,
            color: color,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[800]?.withOpacity(0.3)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.bookmark_border_rounded,
              size: 64,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No bookmarked papers yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring and bookmark interesting\nresearch papers to save them here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore_rounded),
            label: Text(
              'Explore Papers',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(
      BuildContext context, BookmarkProvider bookmarkProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Bookmarks?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will remove all bookmarked papers. This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              bookmarkProvider.clearAllBookmarks();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'All bookmarks cleared',
                    style: GoogleFonts.inter(),
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
