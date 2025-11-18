import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pdf_service.dart';
import 'unified_pdf_viewer.dart';
import '../theme/app_theme.dart';
import '../widgets/bookmark_button.dart';

class CategoryPapersScreen extends StatefulWidget {
  final String category;
  final PdfService _pdfService = PdfService();

  CategoryPapersScreen({super.key, required this.category});

  @override
  State<CategoryPapersScreen> createState() => _CategoryPapersScreenState();
}

class _CategoryPapersScreenState extends State<CategoryPapersScreen> {
  late List<Map<String, String>> _papers;
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPapers();
  }

  void _loadPapers() {
    setState(() {
      _papers = widget._pdfService.getPapersByCategory(widget.category);
      _isLoading = false;
    });
  }

  List<Map<String, String>> get _filteredPapers {
    if (_searchQuery.isEmpty) return _papers;
    return _papers
        .where((paper) => (paper['title'] ?? '')
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (q) => setState(() => _searchQuery = q),
              decoration: InputDecoration(
                hintText: 'Search papers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredPapers.isEmpty
                    ? Center(
                        child: Text(
                          'No papers found in this category',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredPapers.length,
                        itemBuilder: (context, index) {
                          final paper = _filteredPapers[index];
                          return _buildModernPaperCard(
                            paperId: paper['path'] ?? '',
                            title: paper['title'] ?? '',
                            author: paper['author'] ?? '',
                            year: paper['year'] ?? '',
                            pages: 12,
                            citations: 5,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UnifiedPdfViewer(
                                    pdfPath: paper['path'] ?? '',
                                    title: paper['title'] ?? '',
                                    author: paper['author'] ?? '',
                                  ),
                                ),
                              );
                            },
                            isDarkMode: isDarkMode,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPaperCard({
    required String paperId,
    required String title,
    required String author,
    required String year,
    required int pages,
    required int citations,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppTheme.primaryBlue.withOpacity(0.1),
          highlightColor: AppTheme.primaryBlue.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF374151)
                    : const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue,
                            AppTheme.primaryBlue.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.article_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by $author',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    BookmarkButton(
                      paperId: paperId,
                      paperTitle: title,
                      paperAuthor: author,
                      year: year,
                      category: widget.category,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: isDarkMode
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF374151).withOpacity(0.3)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 12,
                            color: isDarkMode
                                ? const Color(0xFFD1D5DB)
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            year,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDarkMode
                                  ? const Color(0xFFD1D5DB)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF374151).withOpacity(0.3)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 12,
                            color: isDarkMode
                                ? const Color(0xFFD1D5DB)
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$pages pp',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDarkMode
                                  ? const Color(0xFFD1D5DB)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(Icons.visibility_outlined, size: 16),
                      label: Text(
                        'View',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
