import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pdf_service.dart';
import '../screens/unified_pdf_viewer.dart';
import '../widgets/bookmark_button.dart';

class AllPapersScreen extends StatefulWidget {
  const AllPapersScreen({super.key});

  @override
  State<AllPapersScreen> createState() => _AllPapersScreenState();
}

class _AllPapersScreenState extends State<AllPapersScreen>
    with TickerProviderStateMixin {
  final PdfService _pdfService = PdfService();
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _selectedView = 'category'; // 'category', 'author', 'trending'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  Map<String, List<Map<String, String>>> _categorizedPapers = {};
  Map<String, int> _categoryCounts = {};
  List<Map<String, String>> _allPapers = [];
  List<Map<String, String>> _filteredPapers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _loadAllPapers();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadAllPapers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all papers including user uploads from Firebase
      final allPapersFromService =
          await _pdfService.getAllPapersIncludingUserUploads();

      // Get categorized papers with user uploads
      final categorizedWithUploads =
          await _pdfService.getCategorizedPapersWithUploads();

      setState(() {
        _categorizedPapers = categorizedWithUploads;

        // Calculate category counts
        _categoryCounts = {};
        _categorizedPapers.forEach((category, papers) {
          _categoryCounts[category] = papers.length;
        });

        // Store all papers
        _allPapers = allPapersFromService;

        // Sort by year (most recent first) and then by title
        _allPapers.sort((a, b) {
          final yearA = int.tryParse(a['year'] ?? '0') ?? 0;
          final yearB = int.tryParse(b['year'] ?? '0') ?? 0;
          if (yearA != yearB) {
            return yearB.compareTo(yearA); // Descending by year
          }
          return (a['title'] ?? '').compareTo(b['title'] ?? '');
        });

        _filteredPapers = List.from(_allPapers);
        _isLoading = false;

        debugPrint('✅ All Papers Loaded (Including User Uploads):');
        debugPrint('   Total Papers: ${_allPapers.length}');
        debugPrint('   Categories: ${_categorizedPapers.keys.length}');
        _categorizedPapers.forEach((category, papers) {
          debugPrint('   📂 $category: ${papers.length} papers');
        });
      });
    } catch (e) {
      debugPrint('❌ Error loading papers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPapers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPapers = List.from(_allPapers);
      } else {
        _filteredPapers = _allPapers.where((paper) {
          return paper['title']!.toLowerCase().contains(query.toLowerCase()) ||
              paper['author']!.toLowerCase().contains(query.toLowerCase()) ||
              paper['category']!.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bgColor =
        isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal 68px AppBar
            _buildMinimalAppBar(isDarkMode),
            // Search Section
            _buildSearchSection(isDarkMode),
            // View Toggle
            _buildViewToggle(isDarkMode),
            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalAppBar(bool isDarkMode) {
    final bgColor =
        isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor =
        isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
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
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.arrow_back,
                color: const Color(0xFF3B82F6),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          // Title and count
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Research Papers',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_allPapers.length} research papers • ${_categorizedPapers.keys.length} categories',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    color: subtitleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(bool isDarkMode) {
    final bgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final hintColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterPapers,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: 'Search papers...',
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
            color: hintColor,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: hintColor,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: hintColor,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterPapers('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle(bool isDarkMode) {
    final bgColor =
        isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleButton(
              'category', 'All Papers', Icons.article_rounded, isDarkMode),
          _buildToggleButton(
              'author', 'By Author', Icons.person_rounded, isDarkMode),
          _buildToggleButton(
              'trending', 'Trending', Icons.trending_up_rounded, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
      String value, String label, IconData icon, bool isDarkMode) {
    final isSelected = _selectedView == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isSelected
                        ? Colors.white
                        : (isDarkMode
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDarkMode) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults(isDarkMode);
    }

    switch (_selectedView) {
      case 'category':
        return _buildCategoryView(isDarkMode);
      case 'author':
        return _buildAuthorView(isDarkMode);
      case 'trending':
        return _buildTrendingView(isDarkMode);
      default:
        return _buildCategoryView(isDarkMode);
    }
  }

  Widget _buildSearchResults(bool isDarkMode) {
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);

    if (_filteredPapers.isEmpty) {
      return _buildEmptyState(
          isDarkMode, 'No papers found matching your search');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Search Results (${_filteredPapers.length})',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: titleColor,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _filteredPapers.length,
            itemBuilder: (context, index) {
              final paper = _filteredPapers[index];
              return _buildPaperListItem(paper, isDarkMode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryView(bool isDarkMode) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading papers with ML categorization...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_categorizedPapers.isEmpty) {
      return _buildEmptyState(isDarkMode, 'No research papers available');
    }

    // Show categorized papers in expandable sections
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _categorizedPapers.keys.length,
      itemBuilder: (context, index) {
        final category = _categorizedPapers.keys.elementAt(index);
        final papers = _categorizedPapers[category]!;
        final count = _categoryCounts[category] ?? papers.length;

        return _buildCategorySection(category, papers, count, isDarkMode);
      },
    );
  }

  Widget _buildAuthorView(bool isDarkMode) {
    if (_allPapers.isEmpty) {
      return _buildEmptyState(isDarkMode, 'No research papers available');
    }

    // Sort papers by author for better organization
    final sortedPapers = List<Map<String, String>>.from(_allPapers);
    sortedPapers
        .sort((a, b) => (a['author'] ?? '').compareTo(b['author'] ?? ''));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedPapers.length,
      itemBuilder: (context, index) {
        final paper = sortedPapers[index];
        return _buildPaperListItem(paper, isDarkMode);
      },
    );
  }

  Widget _buildTrendingView(bool isDarkMode) {
    final trendingPapers = _pdfService.getTrendingPapers(limit: 20);

    if (trendingPapers.isEmpty) {
      return _buildEmptyState(isDarkMode, 'No trending papers available yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: trendingPapers.length,
      itemBuilder: (context, index) {
        final paper = trendingPapers[index];
        return _buildTrendingPaperItem(paper, index + 1, isDarkMode);
      },
    );
  }

  Widget _buildCategorySection(String category,
      List<Map<String, String>> papers, int count, bool isDarkMode) {
    final cardBg = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: _getCategoryColor(category),
              size: 22,
            ),
          ),
          title: Text(
            category,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: titleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '$count ${count == 1 ? 'paper' : 'papers'}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              color: subtitleColor,
            ),
          ),
          children: papers
              .map((paper) => _buildPaperListItem(paper, isDarkMode))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAuthorSection(
      String author, List<Map<String, String>> papers, bool isDarkMode) {
    final cardBg = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_rounded,
              color: const Color(0xFF3B82F6),
              size: 22,
            ),
          ),
          title: Text(
            author,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: titleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${papers.length} ${papers.length == 1 ? 'paper' : 'papers'}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              color: subtitleColor,
            ),
          ),
          children: papers
              .map((paper) => _buildPaperListItem(paper, isDarkMode))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTrendingPaperItem(
      dynamic trendingPaper, int rank, bool isDarkMode) {
    final cardBg = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPaper(
            trendingPaper['title'] ?? '',
            trendingPaper['author'] ?? '',
            trendingPaper['path'] ?? '',
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trendingPaper['title'] ?? 'Unknown Title',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: titleColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: 14,
                            color: const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${trendingPaper['views'] ?? 0} views',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: subtitleColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaperListItem(Map<String, String> paper, bool isDarkMode) {
    final cardBg = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPaper(
            paper['title'] ?? '',
            paper['author'] ?? '',
            paper['path'] ?? '',
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(paper['category'] ?? '')
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: _getCategoryColor(paper['category'] ?? ''),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paper['title'] ?? 'Unknown Title',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: titleColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              paper['author'] ?? 'Unknown Author',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                                color: const Color(0xFF3B82F6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (paper['category'] != null &&
                              paper['category']!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(paper['category']!)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  paper['category']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                    color:
                                        _getCategoryColor(paper['category']!),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Bookmark button
                BookmarkButton(
                  paperId: paper['path'] ?? '', // Using path as unique ID
                  paperTitle: paper['title'] ?? 'Unknown Title',
                  paperAuthor: paper['author'] ?? 'Unknown Author',
                  year: paper['year'],
                  category: paper['category'],
                  iconSize: 20,
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: subtitleColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode, String message) {
    final iconColor =
        isDarkMode ? const Color(0xFF64748B) : const Color(0xFFCBD5E1);
    final textColor =
        isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Computer Science': const Color(0xFF3B82F6),
      'Machine Learning': const Color(0xFF8B5CF6),
      'Medical Science': const Color(0xFFEF4444),
      'Engineering': const Color(0xFF10B981),
      'Biotechnology': const Color(0xFFF59E0B),
      'Mathematics': const Color(0xFF6366F1),
    };
    return colors[category] ?? const Color(0xFF6B7280);
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'Computer Science': Icons.computer_rounded,
      'Machine Learning': Icons.psychology_rounded,
      'Medical Science': Icons.medical_services_rounded,
      'Engineering': Icons.engineering_rounded,
      'Biotechnology': Icons.biotech_rounded,
      'Mathematics': Icons.functions_rounded,
    };
    return icons[category] ?? Icons.article_rounded;
  }

  void _openPaper(String title, String author, String path) async {
    try {
      // Navigate to unified PDF viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnifiedPdfViewer(
            pdfPath: path,
            title: title,
            author: author,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening paper: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
