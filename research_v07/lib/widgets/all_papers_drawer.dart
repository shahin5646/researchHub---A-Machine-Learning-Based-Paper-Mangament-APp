import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pdf_service.dart';
import '../screens/unified_pdf_viewer.dart';
import '../screens/research_papers_screen.dart';

class AllPapersDrawer extends StatefulWidget {
  const AllPapersDrawer({super.key});

  @override
  State<AllPapersDrawer> createState() => _AllPapersDrawerState();
}

class _AllPapersDrawerState extends State<AllPapersDrawer>
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

        debugPrint('✅ All Papers Drawer Loaded (Including User Uploads):');
        debugPrint('   Total Papers: ${_allPapers.length}');
        debugPrint('   Categories: ${_categorizedPapers.keys.length}');
        _categorizedPapers.forEach((category, papers) {
          debugPrint('   📂 $category: ${papers.length} papers');
        });
      });
    } catch (e) {
      debugPrint('❌ Error loading papers in drawer: $e');
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
              paper['author']!.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      width: MediaQuery.of(context).size.width * 0.85,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildDrawerHeader(isDarkMode),
            _buildSearchSection(isDarkMode),
            _buildViewToggle(isDarkMode),
            Expanded(
              child: _buildContent(isDarkMode),
            ),
            _buildDrawerFooter(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(bool isDarkMode) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                  const Color(0xFFEC4899)
                ]
              : [
                  const Color(0xFF3B82F6),
                  const Color(0xFF8B5CF6),
                  const Color(0xFFEC4899)
                ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.library_books_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'All Research Papers',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_allPapers.length} papers • ${_categorizedPapers.keys.length} categories',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? LinearGradient(
                colors: [
                  const Color(0xFF1E293B).withOpacity(0.8),
                  const Color(0xFF334155).withOpacity(0.8),
                ],
              )
            : LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF3B82F6).withOpacity(0.2)
              : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterPapers,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Search papers by title or author...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? LinearGradient(
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF334155),
                ],
              )
            : LinearGradient(
                colors: [
                  const Color(0xFFF1F5F9),
                  const Color(0xFFE2E8F0),
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildToggleButton(
              'category', 'Categories', Icons.category_rounded, isDarkMode),
          _buildToggleButton(
              'author', 'Authors', Icons.person_rounded, isDarkMode),
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
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
    if (_filteredPapers.isEmpty) {
      return _buildEmptyState(
          isDarkMode, 'No papers found matching your search');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_filteredPapers.length} results found',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Analyzing papers with ML...',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 6),
                Text(
                  'K-Means Clustering Active',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_categorizedPapers.isEmpty) {
      return _buildEmptyState(isDarkMode, 'No papers available yet');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
    // Group papers by author
    final authorPapers = <String, List<Map<String, String>>>{};
    for (final paper in _allPapers) {
      final author = paper['author']!;
      authorPapers.putIfAbsent(author, () => []).add(paper);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: authorPapers.keys.length,
      itemBuilder: (context, index) {
        final author = authorPapers.keys.elementAt(index);
        final papers = authorPapers[author]!;

        return _buildAuthorSection(author, papers, isDarkMode);
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
    final categoryColor = _getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF334155),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  categoryColor.withOpacity(0.02),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  categoryColor.withOpacity(0.8),
                  categoryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: Colors.white,
              size: 26,
            ),
          ),
          title: Text(
            category,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: categoryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$count ${count == 1 ? 'paper' : 'papers'}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.auto_awesome,
                size: 12,
                color: categoryColor.withOpacity(0.6),
              ),
            ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
          child: Text(
            author
                .split(' ')
                .map((word) => word.isNotEmpty ? word[0] : '')
                .take(2)
                .join()
                .toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3B82F6),
            ),
          ),
        ),
        title: Text(
          author,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          '${papers.length} ${papers.length == 1 ? 'paper' : 'papers'}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ResearchPapersScreen(professorName: author),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: papers
            .take(3)
            .map((paper) => _buildPaperListItem(paper, isDarkMode))
            .toList(),
      ),
    );
  }

  Widget _buildTrendingPaperItem(
      dynamic trendingPaper, int rank, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: rank <= 3
                  ? [Colors.amber, Colors.orange]
                  : [Colors.blue, Colors.indigo],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Text(
          trendingPaper.title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trendingPaper.author,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.visibility, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${trendingPaper.viewCount} views',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.download, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${trendingPaper.downloadCount} downloads',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _openPaper(
            trendingPaper.title, trendingPaper.author, trendingPaper.path),
      ),
    );
  }

  Widget _buildPaperListItem(Map<String, String> paper, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E293B).withOpacity(0.6)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              _openPaper(paper['title']!, paper['author']!, paper['path']!),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.8),
                        const Color(0xFF8B5CF6).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.description_rounded,
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
                        paper['title']!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              paper['author']!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.1),
                    const Color(0xFF8B5CF6).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.library_books_outlined,
                size: 64,
                color: isDarkMode
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Papers will appear here once loaded',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to all papers view
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.library_books, size: 16),
              label: Text(
                'Browse All Papers',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final categoryLower = category.toLowerCase();

    // ML-discovered categories - intelligent color mapping
    if (categoryLower.contains('machine') ||
        categoryLower.contains('learning') ||
        categoryLower.contains('ai') ||
        categoryLower.contains('neural')) {
      return const Color(0xFF8B5CF6); // Purple for AI/ML
    }
    if (categoryLower.contains('computer') ||
        categoryLower.contains('software') ||
        categoryLower.contains('algorithm') ||
        categoryLower.contains('code')) {
      return const Color(0xFF3B82F6); // Blue for CS
    }
    if (categoryLower.contains('medical') ||
        categoryLower.contains('health') ||
        categoryLower.contains('disease') ||
        categoryLower.contains('clinical') ||
        categoryLower.contains('patient') ||
        categoryLower.contains('diagnosis')) {
      return const Color(0xFFEF4444); // Red for Medical
    }
    if (categoryLower.contains('engineer') ||
        categoryLower.contains('iot') ||
        categoryLower.contains('robot') ||
        categoryLower.contains('automation') ||
        categoryLower.contains('sensor')) {
      return const Color(0xFF10B981); // Green for Engineering
    }
    if (categoryLower.contains('plant') ||
        categoryLower.contains('crop') ||
        categoryLower.contains('bio') ||
        categoryLower.contains('agriculture') ||
        categoryLower.contains('gene')) {
      return const Color(0xFFF59E0B); // Amber for Biotech
    }
    if (categoryLower.contains('business') ||
        categoryLower.contains('econom') ||
        categoryLower.contains('bank') ||
        categoryLower.contains('commerce') ||
        categoryLower.contains('financ')) {
      return const Color(0xFF06B6D4); // Cyan for Business
    }
    if (categoryLower.contains('educat') ||
        categoryLower.contains('teach') ||
        categoryLower.contains('learn') ||
        categoryLower.contains('student')) {
      return const Color(0xFFF97316); // Orange for Education
    }
    if (categoryLower.contains('math') ||
        categoryLower.contains('statistic') ||
        categoryLower.contains('calculus')) {
      return const Color(0xFF6366F1); // Indigo for Math
    }
    if (categoryLower.contains('data') ||
        categoryLower.contains('analytics') ||
        categoryLower.contains('visualization')) {
      return const Color(0xFFA855F7); // Purple for Data Science
    }
    if (categoryLower.contains('network') ||
        categoryLower.contains('security') ||
        categoryLower.contains('cyber')) {
      return const Color(0xFF14B8A6); // Teal for Networks
    }

    // Fallback: Generate color from category hash for consistent colors
    final hash = category.hashCode;
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.55).toColor();
  }

  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();

    // ML-discovered categories - intelligent icon mapping
    if (categoryLower.contains('machine') ||
        categoryLower.contains('learning') ||
        categoryLower.contains('ai') ||
        categoryLower.contains('neural')) {
      return Icons.psychology_rounded;
    }
    if (categoryLower.contains('computer') ||
        categoryLower.contains('software') ||
        categoryLower.contains('algorithm')) {
      return Icons.computer_rounded;
    }
    if (categoryLower.contains('medical') ||
        categoryLower.contains('health') ||
        categoryLower.contains('disease') ||
        categoryLower.contains('clinical')) {
      return Icons.medical_services_rounded;
    }
    if (categoryLower.contains('engineer') ||
        categoryLower.contains('iot') ||
        categoryLower.contains('robot')) {
      return Icons.precision_manufacturing_rounded;
    }
    if (categoryLower.contains('plant') ||
        categoryLower.contains('crop') ||
        categoryLower.contains('bio') ||
        categoryLower.contains('agriculture')) {
      return Icons.eco_rounded;
    }
    if (categoryLower.contains('business') ||
        categoryLower.contains('econom') ||
        categoryLower.contains('bank') ||
        categoryLower.contains('commerce')) {
      return Icons.business_center_rounded;
    }
    if (categoryLower.contains('educat') ||
        categoryLower.contains('teach') ||
        categoryLower.contains('student')) {
      return Icons.school_rounded;
    }
    if (categoryLower.contains('math') || categoryLower.contains('statistic')) {
      return Icons.calculate_rounded;
    }
    if (categoryLower.contains('data') || categoryLower.contains('analytics')) {
      return Icons.analytics_rounded;
    }
    if (categoryLower.contains('network') ||
        categoryLower.contains('security')) {
      return Icons.security_rounded;
    }
    if (categoryLower.contains('cloud') ||
        categoryLower.contains('distributed')) {
      return Icons.cloud_rounded;
    }

    return Icons.auto_awesome_rounded; // Default for ML-discovered categories
  }

  void _openPaper(String title, String author, String path) async {
    Navigator.pop(context); // Close drawer

    try {
      // Track paper view
      await _pdfService.trackPaperView(title, author, path);

      // Navigate to PDF viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnifiedPdfViewer(
            pdfPath: path,
            title: title,
            author: author,
            isAsset: true,
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
