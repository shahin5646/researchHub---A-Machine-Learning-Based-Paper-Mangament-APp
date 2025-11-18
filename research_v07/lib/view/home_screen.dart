import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_drawer.dart';
import '../common_widgets/featured_paper_card.dart';
import '../data/faculty_data.dart';
import '../screens/category_screen.dart';
import '../screens/faculty_profile_screen.dart';
import '../services/pdf_service.dart';
import 'faculty_list_screen.dart';
import '../common_widgets/logo_ui.dart';
import '../common_widgets/safe_image.dart';
import '../screens/category_papers_screen.dart';
import '../services/search_service.dart';
import '../models/research_paper.dart';
import 'dart:async';
import '../models/faculty.dart';
import '../screens/explore_nav.dart'; // Add this import
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart'; // Add this import
import '../services/pdf_viewer_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PdfService _pdfService = PdfService();
  List<TrendingPaper> _trendingPapers = [];

  bool _isSearching = false;
  bool _showSuggestions = false;
  final List<String> _recentSearches = [];

  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  List<ResearchPaper> _searchResults = [];
  List<Faculty> _facultyResults = [];
  Timer? _debounceTimer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTrendingPapers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTrendingPapers() async {
    await _pdfService.loadTrendingPapers();
    setState(() {
      _trendingPapers = _pdfService.getTrendingPapers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor:
              isDark ? AppTheme.backgroundColor(context) : Colors.grey[50],
          drawer: const AppDrawer(),
          appBar: _buildAppBar(isDark),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(isDark),
                _buildTrendingPapers(isDark),
                _buildQuickCategories(isDark),
                _buildFacultyHighlights(isDark),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(isDark),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? AppTheme.surfaceColor(context) : Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: ResearchHubLogo(fontSize: 24, showTagline: false, isDark: isDark),
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceColor(context) : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey[200]!,
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black12 : Colors.grey[200]!,
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search papers, faculty, topics...',
                      hintStyle: GoogleFonts.poppins(
                        color: isDark ? Colors.white60 : Colors.grey[500],
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: _handleSearch,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSearching
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                          onPressed: _clearSearch,
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                          onPressed: () => _showFilterOptions(context),
                        ),
                ),
              ],
            ),
          ),

          // Filter Chips
          if (_showSuggestions) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', isSelected: true),
                  _buildFilterChip('Papers'),
                  _buildFilterChip('Faculty'),
                  _buildFilterChip('Most Cited'),
                  _buildFilterChip('Recent'),
                ],
              ),
            ),
          ],

          // Search Suggestions
          if (_showSuggestions) _buildSearchSuggestions(),
        ],
      ),
    );
  }

  void _handleSearch(String value) {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    setState(() {
      _isSearching = value.isNotEmpty;
      _showSuggestions = value.isNotEmpty;
    });

    // Debounce the search to avoid too many updates
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.isEmpty) {
        setState(() {
          _searchResults = [];
          _facultyResults = [];
        });
        return;
      }

      final results = _searchService.searchAll(value);
      setState(() {
        _searchResults = results['papers'];
        _facultyResults = results['faculty'];

        // Add to recent searches if not already present
        if (!_recentSearches.contains(value) && value.length > 2) {
          _recentSearches.insert(0, value);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        }
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _showSuggestions = false;
      _searchResults = [];
      _facultyResults = [];
    });
  }

  Widget _buildSearchSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Research Papers',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    _searchResults.length > 3 ? 3 : _searchResults.length,
                itemBuilder: (context, index) {
                  final paper = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: Text(
                      paper.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    subtitle: Text(
                      paper.author,
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    onTap: () => _openPaper(paper),
                  );
                },
              ),
            ],
            if (_facultyResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Faculty Members',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    _facultyResults.length > 3 ? 3 : _facultyResults.length,
                itemBuilder: (context, index) {
                  final faculty = _facultyResults[index];
                  return ListTile(
                    leading: SafeCircleAvatar(imagePath: faculty.imageUrl),
                    title: Text(
                      faculty.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    subtitle: Text(
                      faculty.designation,
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    onTap: () => _openFacultyProfile(faculty),
                  );
                },
              ),
            ],
            if (_recentSearches.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Searches',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: _clearRecentSearches,
                      child: Text(
                        'Clear',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: _recentSearches
                    .map(
                      (search) => ActionChip(
                        label: Text(
                          search,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        onPressed: () => _handleSearchSelect(search),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openPaper(ResearchPaper paper) async {
    // Use the PDF viewer service for consistent PDF viewing experience
    final pdfViewerService = PdfViewerService();

    // Determine if the path is an asset or not based on the path format
    final isAsset = paper.pdfUrl.startsWith('assets/') ||
        !paper.pdfUrl.startsWith('http://') &&
            !paper.pdfUrl.startsWith('https://');

    await pdfViewerService.openPaperPdf(
      context,
      paper,
      isAsset: isAsset,
      userId: 'current_user',
    );
  }

  void _openFacultyProfile(Faculty faculty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FacultyProfileScreen(faculty: faculty),
      ),
    );
  }

  void _clearRecentSearches() {
    setState(() => _recentSearches.clear());
  }

  void _handleSearchSelect(String search) {
    _searchController.text = search;
    _handleSearch(search);
  }

  Widget _buildTrendingPapers(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending Papers',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Last 7 Days',
                  style: GoogleFonts.poppins(
                    color: Colors.indigo,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Featured paper for Noori sir
                FeaturedPaperCard(
                  color: Colors.indigo,
                  title:
                      'A cloud based four-tier architecture for early detection of heart disease with machine learning',
                  author: 'Professor Dr. Sheak Rashed Haider Noori',
                  views: '1,378',
                  downloads: '256',
                  onTap: () {
                    // Handle paper tap
                  },
                ),
                const SizedBox(width: 16),
                FeaturedPaperCard(
                  color: Colors.purple,
                  title:
                      'Machine Learning-based Approach for Early Detection of Heart Disease Risk Prediction',
                  author: 'Professor Dr. Sheak Rashed Haider Noori',
                  views: '892',
                  downloads: '145',
                  onTap: () {
                    // Handle paper tap
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCategories(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryButton(
                Icons.computer,
                'Computer\nScience',
                Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryPapersScreen(
                        category: 'Computer Science',
                      ),
                    ),
                  );
                },
              ),
              _buildCategoryButton(
                Icons.psychology,
                'AI & ML',
                Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryPapersScreen(
                        category: 'Machine Learning',
                      ),
                    ),
                  );
                },
              ),
              _buildCategoryButton(
                Icons.biotech,
                'BioTech',
                Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CategoryPapersScreen(category: 'Biotechnology'),
                    ),
                  );
                },
              ),
              _buildCategoryButton(
                Icons.more_horiz,
                'More',
                Colors.grey,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyHighlights(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Faculty Highlights',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FacultyListScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.poppins(
                        color: Colors.indigo,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.indigo,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                final faculty = facultyMembers[index];
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(begin: 1.0, end: 1.0),
                  builder: (context, value, child) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        double scale = 1.0;
                        return GestureDetector(
                          onTapDown: (_) => setState(() => scale = 0.95),
                          onTapUp: (_) {
                            setState(() => scale = 1.0);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FacultyProfileScreen(faculty: faculty),
                              ),
                            );
                          },
                          onTapCancel: () => setState(() => scale = 1.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            transform: Matrix4.identity()..scale(scale),
                            child: Container(
                              width: 160,
                              margin: EdgeInsets.only(
                                right: index == 2 ? 0 : 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey[200]!,
                                    blurRadius: scale == 1.0 ? 8 : 4,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      SafeCircleAvatar(
                                        radius: 40,
                                        imagePath: faculty.imageUrl,
                                      ),
                                      if (faculty.isOnline)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          faculty.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          faculty.designation,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceColor(context) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey[200]!,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ExploreScreen()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppTheme.surfaceColor(context) : Colors.white,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.indigo,
        checkmarkColor: Colors.white,
        onSelected: (bool selected) {
          // Handle filter selection
          _applyFilter(label);
        },
      ),
    );
  }

  void _applyFilter(String filter) {
    setState(() {
      // Implement filter logic based on selection
      switch (filter) {
        case 'All':
          // Show all results
          break;
        case 'Papers':
          // Filter only papers
          _searchResults = _searchResults.where((paper) => true).toList();
          break;
        case 'Faculty':
          // Filter only faculty
          _facultyResults = _facultyResults.where((faculty) => true).toList();
          break;
        case 'Most Cited':
          // Sort by citations
          _searchResults.sort((a, b) => b.citations.compareTo(a.citations));
          break;
        case 'Recent':
          // Sort by date
          _searchResults.sort((a, b) => b.year.compareTo(a.year));
          break;
      }
    });
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter Results',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Date Range Filter
              Text(
                'Date Range',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildYearFilterChip('Last Year'),
                  _buildYearFilterChip('Last 3 Years'),
                  _buildYearFilterChip('All Time'),
                ],
              ),

              const SizedBox(height: 24),

              // Content Type Filter
              Text(
                'Content Type',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildTypeFilterChip('Research Papers'),
                  _buildTypeFilterChip('Journal Articles'),
                  _buildTypeFilterChip('Conference Papers'),
                  _buildTypeFilterChip('Thesis'),
                ],
              ),

              const SizedBox(height: 24),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Apply filters and close sheet
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: false, // Manage selection state
        onSelected: (bool selected) {
          // Handle year filter selection
        },
      ),
    );
  }

  Widget _buildTypeFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: false, // Manage selection state
      onSelected: (bool selected) {
        // Handle content type filter selection
      },
    );
  }
}
