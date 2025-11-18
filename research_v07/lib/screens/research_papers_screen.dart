import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pdf_service.dart';
import 'unified_pdf_viewer.dart';
import '../theme/app_theme.dart';
import 'faculty_profile_screen.dart';
import '../data/faculty_data.dart';
import '../widgets/bookmark_button.dart';

class ResearchPapersScreen extends StatefulWidget {
  final String professorName;

  const ResearchPapersScreen({
    super.key,
    required this.professorName,
  });

  @override
  State<ResearchPapersScreen> createState() => _ResearchPapersScreenState();
}

class _ResearchPapersScreenState extends State<ResearchPapersScreen>
    with TickerProviderStateMixin {
  final _pdfService = PdfService();
  final _logger = Logger('ResearchPapersScreen');
  final _searchController = TextEditingController();

  List<File> _papers = [];
  List<Map<String, String>> _webPapers = [];
  List<dynamic> _filteredPapers = [];

  bool _isLoading = true;
  bool _showSearch = false;
  String _sortBy = 'title'; // 'title', 'year', 'citations', 'recent'
  String _filterYear = 'all';
  String _searchQuery = '';

  late AnimationController _searchAnimationController;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadPapers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPapers() async {
    setState(() => _isLoading = true);
    try {
      _logger.info('===== STARTING TO LOAD PAPERS =====');
      _logger.info('Professor name: ${widget.professorName}');
      _logger.info('Platform: ${kIsWeb ? "Web" : "Native"}');

      if (kIsWeb) {
        _webPapers = _pdfService.getWebPapers(widget.professorName);
        _filteredPapers = List.from(_webPapers);
        _logger.info('Web papers loaded: ${_webPapers.length}');
        _logger.info('Filtered papers after copy: ${_filteredPapers.length}');
      } else {
        _papers = await _pdfService.getProfessorPapers(widget.professorName);
        _filteredPapers = List.from(_papers);
        _logger.info('Native papers loaded: ${_papers.length}');
        _logger.info('Filtered papers after copy: ${_filteredPapers.length}');
        if (_papers.isNotEmpty) {
          _logger.info('First paper path: ${_papers.first.path}');
        }
      }

      _applySortAndFilter();
      _logger.info('After sort/filter: ${_filteredPapers.length} papers');
      _logger.info('===== PAPERS LOADING COMPLETE =====');

      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      _logger.severe('Error loading papers: $e');
      _logger.severe('Stack trace: $stackTrace');
      setState(() {
        _papers = [];
        _webPapers = [];
        _filteredPapers = [];
        _isLoading = false;
      });
    }
  }

  void _applySortAndFilter() {
    final papers = kIsWeb ? _webPapers : _papers;
    _filteredPapers = List.from(papers);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredPapers = _filteredPapers.where((paper) {
        if (kIsWeb) {
          final title = (paper['title'] ?? '').toLowerCase();
          return title.contains(_searchQuery.toLowerCase());
        } else {
          final title =
              path.basenameWithoutExtension((paper as File).path).toLowerCase();
          return title.contains(_searchQuery.toLowerCase());
        }
      }).toList();
    }

    // Apply year filter
    if (_filterYear != 'all') {
      // Implement year filtering logic here
    }

    // Apply sorting
    switch (_sortBy) {
      case 'title':
        if (kIsWeb) {
          _filteredPapers
              .sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
        } else {
          _filteredPapers.sort((a, b) => path
              .basenameWithoutExtension((a as File).path)
              .compareTo(path.basenameWithoutExtension((b as File).path)));
        }
        break;
      case 'year':
        // Add year sorting logic
        break;
      case 'citations':
        // Add citation sorting logic
        break;
      case 'recent':
        // Add recent sorting logic
        break;
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applySortAndFilter();
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _performSearch('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildModernSliverAppBar(isDarkMode),
          ],
          body: Column(
            children: [
              // Search and filter section
              _buildSearchAndFilterSection(isDarkMode),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredPapers.isEmpty
                        ? _buildEmptyState(isDarkMode)
                        : _buildModernPapersList(isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSliverAppBar(bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 160, // Reduced height to fix overflow issues
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Faculty',
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: null,
        background: Container(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? AppTheme.subtleDarkBackgroundGradient
                : AppTheme.subtleBackgroundGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Clear Title Hierarchy
                Text(
                  'Research Papers',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),

                // Professor Name
                GestureDetector(
                  onTap: () {
                    final faculty = facultyMembers.firstWhere(
                      (f) =>
                          f.name.contains(widget.professorName) ||
                          widget.professorName.contains(f.name),
                      orElse: () => facultyMembers.first,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FacultyProfileScreen(faculty: faculty),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'by ${widget.professorName}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Paper Count Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlue.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_filteredPapers.length} Papers',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Search Button
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(
            _showSearch ? Icons.close : Icons.search,
            size: 22,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          tooltip: _showSearch ? 'Close Search' : 'Search Papers',
        ),

        // Filter Button
        IconButton(
          onPressed: () => _showAdvancedFilters(context, isDarkMode),
          icon: Icon(
            Icons.filter_list,
            size: 22,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          tooltip: 'Filter Papers',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchAndFilterSection(bool isDarkMode) {
    return Container(
      height: _showSearch ? 120 : 50,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Bar
          if (_showSearch)
            Container(
              height: 70,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF374151)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _performSearch,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search papers...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDarkMode
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF64748B),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: isDarkMode
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF64748B),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                            icon: Icon(
                              Icons.clear,
                              size: 16,
                              color: isDarkMode
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF64748B),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),

          // Filter Bar
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Filter Options
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSimpleFilterChip(
                          label: 'Sort: ${_getSortLabel()}',
                          icon: Icons.sort,
                          onPressed: () =>
                              _showSortOptions(context, isDarkMode),
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(width: 8),
                        _buildSimpleFilterChip(
                          label: _filterYear == 'all'
                              ? 'All Years'
                              : 'Year: $_filterYear',
                          icon: Icons.calendar_today,
                          onPressed: () => _showYearFilter(context, isDarkMode),
                          isDarkMode: isDarkMode,
                          isActive: _filterYear != 'all',
                        ),
                        const SizedBox(width: 8),
                        _buildSimpleFilterChip(
                          label: 'Type',
                          icon: Icons.category,
                          onPressed: () => _showTypeFilter(context, isDarkMode),
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  ),
                ),

                // Clear Filters Button
                if (_searchQuery.isNotEmpty || _filterYear != 'all')
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.clear_all,
                            size: 14,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDarkMode,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : isDarkMode
                  ? const Color(0xFF374151)
                  : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryBlue.withOpacity(0.3)
                : isDarkMode
                    ? const Color(0xFF4B5563)
                    : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? AppTheme.primaryBlue
                  : isDarkMode
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? AppTheme.primaryBlue
                    : isDarkMode
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'title':
        return 'Title';
      case 'year':
        return 'Year';
      case 'citations':
        return 'Citations';
      case 'recent':
        return 'Recent';
      default:
        return 'Title';
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _filterYear = 'all';
      _searchController.clear();
      _applySortAndFilter();
    });
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading research papers...'),
        ],
      ),
    );
  }

  Widget _buildModernPapersList(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredPapers.length,
      itemBuilder: (context, index) {
        final paper = _filteredPapers[index];

        if (kIsWeb) {
          final paperMap = paper as Map<String, dynamic>;
          final title = paperMap['title'] ?? '';
          final path = paperMap['path'] ?? '';

          final formattedTitle = _formatTitle(title);
          return _buildModernPaperCard(
            title: formattedTitle,
            author: widget.professorName,
            year: _extractYearFromTitle(title),
            pages: _generateRandomPages(),
            citations: _generateRandomCitations(),
            onTap: () => _openWebPdf(path),
            isDarkMode: isDarkMode,
            paperId: path,
          );
        } else {
          final file = paper as File;
          final title = path.basenameWithoutExtension(file.path);
          final formattedTitle = _formatTitle(title);

          return _buildModernPaperCard(
            title: formattedTitle,
            author: widget.professorName,
            year: _extractYearFromTitle(title),
            pages: _generateRandomPages(),
            citations: _generateRandomCitations(),
            onTap: () => _openPdf(file),
            isDarkMode: isDarkMode,
            paperId: file.path,
          );
        }
      },
    );
  }

  String _formatTitle(String title) {
    // List of words that should remain lowercase (unless at the beginning)
    final lowercaseWords = {
      'a',
      'an',
      'and',
      'as',
      'at',
      'but',
      'by',
      'for',
      'in',
      'nor',
      'of',
      'on',
      'or',
      'so',
      'the',
      'to',
      'up',
      'yet',
      'with',
      'from',
      'into',
      'onto',
      'per',
      'than',
      'upon',
      'via'
    };

    return title
        .replaceAll('_', ' ')
        .replaceAll('.pdf', '')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) {
      final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      if (cleanWord.isEmpty) return word;

      // Always capitalize first word
      if (word == title.split(' ').where((w) => w.isNotEmpty).first) {
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      }

      // Keep lowercase words lowercase, capitalize others
      if (lowercaseWords.contains(cleanWord)) {
        return word.toLowerCase();
      } else {
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      }
    }).join(' ');
  }

  String _extractYearFromTitle(String title) {
    final yearRegex = RegExp(r'\b(19|20)\d{2}\b');
    final match = yearRegex.firstMatch(title);
    return match?.group(0) ?? '2023';
  }

  int _generateRandomPages() {
    return 8 + (DateTime.now().millisecond % 20); // 8-28 pages
  }

  int _generateRandomCitations() {
    return DateTime.now().millisecond % 50; // 0-49 citations
  }

  Widget _buildModernPaperCard({
    required String title,
    required String author,
    required String year,
    required int pages,
    required int citations,
    required VoidCallback onTap,
    required bool isDarkMode,
    required String paperId, // Add paper ID for bookmarking
  }) {
    // Generate keywords for the paper
    final keywords = _generateSampleKeywords(title);

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
                // Header Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PDF icon
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

                    // Title and author
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              height: 1.4,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: isDarkMode
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  author,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Bookmark button
                    BookmarkButton(
                      paperId: paperId,
                      paperTitle: title,
                      paperAuthor: author,
                      year: year,
                      iconSize: 20,
                      inactiveColor: isDarkMode
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),

                    // Menu button
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: isDarkMode
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(Icons.bookmark_border),
                                  title: Text('Bookmark'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _toggleBookmark(title);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.share),
                                  title: Text('Share'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _sharePaper(title, author);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.download),
                                  title: Text('Download'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _downloadPaper(title);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Keywords
                if (keywords.isNotEmpty)
                  SizedBox(
                    height: 28,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: keywords.take(3).length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppTheme.primaryBlue.withOpacity(0.1)
                                : AppTheme.primaryBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            keywords[index],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),

                // Bottom row with metadata and view button - responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 340;

                    Widget yearChip = Container(
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
                    );

                    Widget pagesChip = Container(
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
                    );

                    Widget viewButton = ElevatedButton.icon(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 36),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: Text(
                        'View',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              yearChip,
                              const SizedBox(width: 8),
                              pagesChip,
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(height: 36, child: viewButton),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        yearChip,
                        const SizedBox(width: 8),
                        pagesChip,
                        const Spacer(),
                        viewButton,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _generateSampleKeywords(String title) {
    final allKeywords = [
      'Machine Learning',
      'Data Science',
      'Artificial Intelligence',
      'Deep Learning',
      'Neural Networks',
      'Computer Vision',
      'Natural Language Processing',
      'Optimization',
      'Algorithms',
      'Software Engineering',
      'Database Systems',
      'Cloud Computing',
      'Cybersecurity',
      'IoT',
      'Blockchain',
      'Healthcare Technology',
      'Education Technology'
    ];

    // Select 3-5 random keywords
    final selectedKeywords = <String>[];
    final random = DateTime.now().millisecond;
    for (int i = 0; i < 4; i++) {
      selectedKeywords.add(allKeywords[(random + i) % allKeywords.length]);
    }
    return selectedKeywords;
  }

  void _toggleBookmark(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paper bookmarked: $title'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _sharePaper(String title, String author) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: $title by $author'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  void _downloadPaper(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading: $title'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF374151).withOpacity(0.5)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.folder_open_outlined,
              size: 60,
              color: isDarkMode
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No research papers found',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'No papers available for ${widget.professorName}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDarkMode
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF9CA3AF),
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  // Advanced Filter Methods
  void _showAdvancedFilters(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Advanced Filters',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Coming Soon: Advanced filtering options including author, journal, keywords, and publication type.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTypeFilter(BuildContext context, bool isDarkMode) {
    final types = ['All', 'Conference', 'Journal', 'Book Chapter', 'Thesis'];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Filter by Publication Type',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(),
            ...types.map((type) => ListTile(
                  leading: Icon(
                    type == 'Conference'
                        ? Icons.groups_outlined
                        : type == 'Journal'
                            ? Icons.library_books_outlined
                            : type == 'Book Chapter'
                                ? Icons.menu_book_outlined
                                : type == 'Thesis'
                                    ? Icons.school_outlined
                                    : Icons.article_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                  title: Text(type),
                  onTap: () => Navigator.pop(context),
                )),
          ],
        ),
      ),
    );
  }

  void _openPdf(File file) {
    final title = _formatTitle(path.basenameWithoutExtension(file.path));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedPdfViewer(
          pdfPath: file.path,
          title: title,
          author: widget.professorName,
          isAsset: false, // file.path is already a prepared local file
        ),
      ),
    );
  }

  void _openWebPdf(String pdfPath) {
    _logger.info('Opening web PDF: $pdfPath');
    final title = _formatTitle(pdfPath.split('/').last.replaceAll('.pdf', ''));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedPdfViewer(
          pdfPath: pdfPath,
          title: title,
          author: widget.professorName,
          isAsset: true,
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Sort Papers',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.sort_by_alpha,
                  color: _sortBy == 'title' ? AppTheme.primaryBlue : null),
              title: Text('Title (A-Z)'),
              selected: _sortBy == 'title',
              onTap: () {
                setState(() {
                  _sortBy = 'title';
                  _applySortAndFilter();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today,
                  color: _sortBy == 'year' ? AppTheme.primaryBlue : null),
              title: Text('Year (Newest)'),
              selected: _sortBy == 'year',
              onTap: () {
                setState(() {
                  _sortBy = 'year';
                  _applySortAndFilter();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.format_quote,
                  color: _sortBy == 'citations' ? AppTheme.primaryBlue : null),
              title: Text('Citations (Most)'),
              selected: _sortBy == 'citations',
              onTap: () {
                setState(() {
                  _sortBy = 'citations';
                  _applySortAndFilter();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.access_time,
                  color: _sortBy == 'recent' ? AppTheme.primaryBlue : null),
              title: Text('Recently Added'),
              selected: _sortBy == 'recent',
              onTap: () {
                setState(() {
                  _sortBy = 'recent';
                  _applySortAndFilter();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showYearFilter(BuildContext context, bool isDarkMode) {
    final years = ['all', '2024', '2023', '2022', '2021', '2020'];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Filter by Year',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(),
            ...years.map((year) => ListTile(
                  leading: Icon(
                    year == 'all' ? Icons.all_inclusive : Icons.calendar_today,
                    color: _filterYear == year ? AppTheme.primaryBlue : null,
                  ),
                  title: Text(year == 'all' ? 'All Years' : year),
                  selected: _filterYear == year,
                  onTap: () {
                    setState(() {
                      _filterYear = year;
                      _applySortAndFilter();
                    });
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
