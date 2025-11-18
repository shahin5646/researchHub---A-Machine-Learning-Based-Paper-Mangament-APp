import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_drawer.dart';
import '../data/faculty_data.dart';
import '../screens/faculty_profile_screen.dart';
import '../services/ui_integration_service.dart';
import '../services/ml_categorization_service.dart';
import '../services/analytics_service.dart';
import 'faculty_list_screen.dart';
import '../common_widgets/logo_ui.dart';
import '../models/research_paper.dart';
import 'dart:async';
import '../models/faculty.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/pdf_viewer_service.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with SingleTickerProviderStateMixin {
  final UIIntegrationService _uiService = UIIntegrationService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;
  List<ResearchPaper> _searchResults = [];
  List<String> _searchSuggestions = [];
  bool _isSearching = false;
  bool _showSearchOverlay = false;
  Timer? _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _uiService.initializeServices();
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        setState(() {
          _isSearching = true;
          _showSearchOverlay = true;
        });
        _performSearch(query);
      } else {
        setState(() {
          _showSearchOverlay = false;
          _searchResults.clear();
          _searchSuggestions.clear();
        });
      }
    });
  }

  void _performSearch(String query) async {
    try {
      final results = _uiService.performSimpleSearch(query);
      final suggestions = _uiService.getSearchSuggestions(query);

      // Track the search
      await _uiService.trackSearch(query, 'current_user', results.length);

      setState(() {
        _searchResults = results;
        _searchSuggestions = suggestions;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      debugPrint('Search error: $e');
    }
  }

  void _applySuggestion(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showSearchOverlay = false;
      _searchResults.clear();
      _searchSuggestions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor(context),
          drawer:
              AppDrawer(onThemeToggle: (isDark) => themeProvider.toggleTheme()),
          body: Stack(
            children: [
              NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    _buildSliverAppBar(context),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHomeTab(),
                    _buildDiscoverTab(),
                    _buildAnalyticsTab(),
                    _buildRecommendationsTab(),
                  ],
                ),
              ),
              if (_showSearchOverlay) _buildSearchOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                const ResearchHubLogo(fontSize: 28, showTagline: false),
                const SizedBox(height: 20),
                _buildSearchBar(),
              ],
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: const [
          Tab(text: 'Home', icon: Icon(Icons.home, size: 20)),
          Tab(text: 'Discover', icon: Icon(Icons.explore, size: 20)),
          Tab(text: 'Analytics', icon: Icon(Icons.analytics, size: 20)),
          Tab(text: 'For You', icon: Icon(Icons.recommend, size: 20)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search research papers, authors, topics...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 200,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: AppTheme.backgroundColor(context),
        child: Column(
          children: [
            // Search Results Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Search Results (${_searchResults.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const Spacer(),
                  if (_isSearching)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            // Search Suggestions
            if (_searchSuggestions.isNotEmpty && _searchResults.isEmpty)
              Container(
                height: 120,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggestions',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.secondaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _searchSuggestions
                          .take(5)
                          .map(
                            (suggestion) => ActionChip(
                              label: Text(suggestion),
                              onPressed: () => _applySuggestion(suggestion),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            // Search Results
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppTheme.secondaryTextColor(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Start typing to search...'
                                : 'No results found',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppTheme.secondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final paper = _searchResults[index];
                        return _buildSearchResultCard(paper);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(ResearchPaper paper) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.description,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          paper.title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              paper.author,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.secondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.date_range,
                    size: 14, color: AppTheme.secondaryTextColor(context)),
                const SizedBox(width: 4),
                Text(
                  paper.year,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor(context),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.format_quote,
                    size: 14, color: AppTheme.secondaryTextColor(context)),
                const SizedBox(width: 4),
                Text(
                  '${paper.citations} citations',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.secondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openPaper(paper),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildQuickStatsSection(),
          const SizedBox(height: 24),
          _buildTrendingTopicsSection(),
          const SizedBox(height: 24),
          _buildFeaturedPapersSection(),
          const SizedBox(height: 24),
          _buildFacultyHighlightsSection(),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoriesSection(),
          const SizedBox(height: 24),
          _buildResearchClustersSection(),
          const SizedBox(height: 24),
          _buildTopAuthorsSection(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _uiService.buildAnalyticsWidget(days: 30),
          const SizedBox(height: 24),
          _buildUsageInsightsSection(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _uiService.buildRecommendationWidget(
            userId: 'current_user',
            onPaperTap: _openPaper,
          ),
          const SizedBox(height: 24),
          _buildSimilarPapersSection(),
          const SizedBox(height: 24),
          _buildTrendingPapersSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Research Hub',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover, explore, and collaborate on cutting-edge research',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.secondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'Papers',
                    '${facultyResearchPapers.values.expand((papers) => papers).length}',
                    Icons.description)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    'Faculty', '${facultyMembers.length}', Icons.people)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard('Topics',
                    '${_uiService.getTrendingTopics().length}', Icons.topic)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.secondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingTopicsSection() {
    return _uiService.buildTrendingTopicsWidget(
      onTopicTap: (topic) {
        _searchController.text = topic;
        _performSearch(topic);
      },
    );
  }

  Widget _buildFeaturedPapersSection() {
    final allPapers = <ResearchPaper>[];
    facultyResearchPapers.forEach((_, papers) => allPapers.addAll(papers));
    final featuredPapers = allPapers.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Research',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...featuredPapers.map((paper) => _buildFeaturedPaperCard(paper)),
      ],
    );
  }

  Widget _buildFeaturedPaperCard(ResearchPaper paper) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.star,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          paper.title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          paper.author,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.secondaryTextColor(context),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openPaper(paper),
      ),
    );
  }

  Widget _buildFacultyHighlightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Faculty Highlights',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FacultyListScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: facultyMembers.take(5).length,
            itemBuilder: (context, index) {
              final faculty = facultyMembers[index];
              return _buildFacultyCard(faculty);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFacultyCard(Faculty faculty) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FacultyProfileScreen(faculty: faculty),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage(faculty.imageUrl),
                ),
                const SizedBox(height: 8),
                Text(
                  faculty.name.split(' ').last,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  faculty.department,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.secondaryTextColor(context),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = _uiService.getTopicDistribution();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Research Categories',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length.clamp(0, 6),
          itemBuilder: (context, index) {
            final entry = categories.entries.elementAt(index);
            return _buildCategoryCard(entry.key, entry.value);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String category, double percentage) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _searchController.text = category;
          _performSearch(category);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.category,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResearchClustersSection() {
    return FutureBuilder<List<PaperCluster>>(
      future: _uiService.getResearchClusters(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final clusters = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Research Clusters',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            ...clusters.take(3).map((cluster) => _buildClusterCard(cluster)),
          ],
        );
      },
    );
  }

  Widget _buildClusterCard(PaperCluster cluster) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.hub,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cluster ${cluster.centroid.hashCode % 100}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${cluster.papers.length} papers',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.secondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            // Show sample paper titles from the cluster instead of centroid
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cluster.papers
                  .take(2)
                  .map(
                    (paper) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${paper.title}',
                        style: GoogleFonts.poppins(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAuthorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Researchers',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 16),
        ...facultyMembers.take(3).map((faculty) => _buildAuthorCard(faculty)),
      ],
    );
  }

  Widget _buildAuthorCard(Faculty faculty) {
    final paperCount = facultyResearchPapers[faculty.name]?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: AssetImage(faculty.imageUrl),
        ),
        title: Text(
          faculty.name,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              faculty.designation,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.secondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$paperCount publications',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.secondaryTextColor(context),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FacultyProfileScreen(faculty: faculty),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageInsightsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Insights',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInsightItem('Views Today', '156', Icons.visibility),
                _buildInsightItem('Downloads', '42', Icons.download),
                _buildInsightItem('Searches', '89', Icons.search),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.secondaryTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarPapersSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You Might Also Like',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Based on your interests and reading history',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.secondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingPapersSection() {
    return FutureBuilder<List<TrendingPaper>>(
      future: _uiService.getTrendingPapersAnalytics(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final trendingPapers = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trending Now',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 16),
            ...trendingPapers
                .map((trending) => _buildTrendingPaperCard(trending.paper)),
          ],
        );
      },
    );
  }

  Widget _buildTrendingPaperCard(ResearchPaper paper) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.trending_up,
            color: Colors.orange,
          ),
        ),
        title: Text(
          paper.title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          paper.author,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.secondaryTextColor(context),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openPaper(paper),
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
}
