import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ui_integration_service.dart';
import '../models/research_paper.dart';
import '../services/pdf_viewer_service.dart';
import '../services/pdf_service.dart';
import '../services/analytics_service.dart';
import '../utils/firestore_seeder.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../screens/saved_papers_screen.dart';

class MainDashboardScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigateToTab;

  const MainDashboardScreen({super.key, this.onNavigateToTab});

  @override
  ConsumerState<MainDashboardScreen> createState() =>
      _MainDashboardScreenState();
}

class _MainDashboardScreenState extends ConsumerState<MainDashboardScreen> {
  Widget _buildSpeedDial(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppTheme.primaryBlue,
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    child: Icon(Icons.upload_file, color: AppTheme.primaryBlue),
                  ),
                  title: Text(
                    'Upload Paper',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    // Navigate to add paper screen and wait for result
                    final result =
                        await Navigator.pushNamed(context, '/add-paper');

                    // If paper was successfully added, refresh the UI
                    if (result == true && mounted) {
                      // Trigger a rebuild to refresh the paper list
                      setState(() {});

                      // Also refresh the search results if searching
                      if (_isSearching) {
                        _searchResults =
                            _uiService.performSimpleSearch(_searchQuery);
                      }
                    }
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    child:
                        Icon(Icons.library_books, color: AppTheme.primaryBlue),
                  ),
                  title: Text(
                    'My Papers',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/my-papers');
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
      child: Icon(Icons.add, color: Colors.white),
    );
  }

  final UIIntegrationService _uiService = UIIntegrationService();
  final PdfService _pdfService = PdfService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final Logger logger = Logger('MainDashboardScreen');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  List<ResearchPaper> _searchResults = [];
  bool _isSearching = false;

  // Real-time stats
  int _totalPapers = 0;
  int _totalFaculty = 0;
  String _totalViews = '0';
  int _mlCategories = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadRealTimeStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRealTimeStats() async {
    setState(() => _isLoadingStats = true);

    try {
      // Get real paper count from Firestore
      final papersSnapshot =
          await FirebaseFirestore.instance.collection('papers').get();

      final paperCount = papersSnapshot.size;

      // Get unique users who uploaded papers (check authorId first, then uploadedBy)
      final Set<String> uniqueAuthors = {};
      for (final doc in papersSnapshot.docs) {
        final data = doc.data();
        final authorId =
            data['authorId'] as String? ?? data['uploadedBy'] as String?;
        if (authorId != null && authorId.isNotEmpty) {
          uniqueAuthors.add(authorId);
        }
      }

      // Calculate total views
      int totalViews = 0;
      for (final doc in papersSnapshot.docs) {
        final data = doc.data();
        totalViews += (data['views'] ?? 0) as int;
      }

      // Get ML categorized data
      final categorizedData =
          await _pdfService.getCategorizedPapersWithUploads();

      setState(() {
        _totalPapers = paperCount;
        _totalFaculty = uniqueAuthors.length;
        _totalViews = _formatNumber(totalViews);
        _mlCategories = categorizedData.length;
        _isLoadingStats = false;
      });

      debugPrint(
          '📊 Home Stats: Papers=$paperCount (Firestore), Faculty=${uniqueAuthors.length} unique authors, Views=$totalViews, Categories=${categorizedData.length}');
    } catch (e) {
      debugPrint('Error loading stats: $e');

      // Fallback to zero if Firestore fails
      setState(() {
        _totalPapers = 0;
        _totalFaculty = 0;
        _totalViews = '0';
        _mlCategories = 0;
        _isLoadingStats = false;
      });
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K+';
    }
    return number.toString();
  }

  void _openPaper(
      BuildContext context, ResearchPaper paper, Logger logger) async {
    final pdfViewerService = PdfViewerService();
    final isAsset = paper.pdfUrl.startsWith('assets/') ||
        (!paper.pdfUrl.startsWith('http://') &&
            !paper.pdfUrl.startsWith('https://'));
    logger.info(
        'Opening paper: [200m${paper.title}, path: ${paper.pdfUrl}, isAsset: $isAsset[0m');
    await pdfViewerService.openPaperPdf(
      context,
      paper,
      isAsset: isAsset,
      userId: 'current_user',
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _isSearching = value.isNotEmpty;
      _searchResults = _uiService.performSimpleSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(),
      backgroundColor: Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      floatingActionButton: _buildModernFAB(context),
      appBar: _buildModernAppBar(context),
      body: RefreshIndicator(
        onRefresh: _loadRealTimeStats,
        color: AppTheme.primaryBlue,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: 100)),
            if (!_isSearching) ...[
              SliverToBoxAdapter(child: _buildHeroSection(context)),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: _buildQuickStatsSection()),
              SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(child: _buildQuickActionsSection(context)),
              SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                  child: _buildFeaturedResearchSection(
                      context, _uiService, logger)),
              SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                  child: _buildRecommendationsSection(_uiService, logger)),
              SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
            if (_isSearching) ...[
              SliverToBoxAdapter(child: _buildSearchBar(context)),
              SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(child: _buildSearchResults()),
            ],
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: EdgeInsets.only(left: 12, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.menu_rounded, color: AppTheme.primaryBlue, size: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menu',
        ),
      ),
      title: Text(
        'ResearchHub',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryBlue,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final auth = ref.watch(authProvider);
            final user = auth.currentUser;
            return Container(
              margin: EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: PopupMenuButton<String>(
                offset: Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await ref.read(authProvider.notifier).logout();
                  } else if (value == 'profile') {
                    // Navigate to Profile tab
                    if (widget.onNavigateToTab != null) {
                      widget.onNavigateToTab!(4); // Index 4 is Profile tab
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline,
                            color: AppTheme.primaryBlue, size: 20),
                        const SizedBox(width: 12),
                        Text('Profile', style: GoogleFonts.inter(fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Text('Logout', style: GoogleFonts.inter(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(
                      user?.displayName.isNotEmpty == true
                          ? user!.displayName[0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final auth = ref.watch(authProvider);
        final user = auth.currentUser;
        final hour = DateTime.now().hour;
        String greeting = hour < 12
            ? 'Good Morning'
            : hour < 17
                ? 'Good Afternoon'
                : 'Good Evening';

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 6),
                spreadRadius: -3,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6366F1).withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.account_balance_rounded,
                        color: Colors.white, size: 18),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Color(0xFF10B981).withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'ACTIVE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              Text(
                '$greeting,',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                user?.displayName.isNotEmpty == true
                    ? user!.displayName
                    : 'Researcher',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded,
                          color: Color(0xFF8B5CF6), size: 14),
                      SizedBox(width: 7),
                      Text(
                        'Explore Research Excellence',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8B5CF6).withOpacity(0.4),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      children: [
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildActionTile(
                          icon: Icons.upload_file_rounded,
                          title: 'Upload Paper',
                          subtitle: 'Share your research',
                          color: Color(0xFF6366F1),
                          onTap: () async {
                            Navigator.pop(context);
                            final result = await Navigator.pushNamed(
                                context, '/add-paper');
                            if (result == true && mounted) {
                              setState(() {});
                              if (_isSearching) {
                                _searchResults = _uiService
                                    .performSimpleSearch(_searchQuery);
                              }
                            }
                          },
                        ),
                        SizedBox(height: 12),
                        _buildActionTile(
                          icon: Icons.library_books_rounded,
                          title: 'My Papers',
                          subtitle: 'View your publications',
                          color: Color(0xFF8B5CF6),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/my-papers');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context: context,
                  icon: Icons.explore_outlined,
                  label: 'Explore',
                  gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  onTap: () {
                    // Navigate to Explore tab (index 2)
                    widget.onNavigateToTab?.call(2);
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context: context,
                  icon: Icons.bookmark_border_rounded,
                  label: 'Saved',
                  gradientColors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedPapersScreen(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context: context,
                  icon: Icons.trending_up_rounded,
                  label: 'Trending',
                  gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
                  onTap: () {
                    Navigator.pushNamed(context, '/trending');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.5),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              SizedBox(height: 11),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 2),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Color(0xFF8B5CF6), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search papers, authors, topics...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.darkSlate,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: Color(0xFF8B5CF6),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_isSearching)
            IconButton(
              icon:
                  Icon(Icons.close_rounded, color: Color(0xFF8B5CF6), size: 18),
              padding: EdgeInsets.all(4),
              constraints: BoxConstraints(),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _isSearching = false;
                  _searchResults = [];
                });
              },
              tooltip: 'Clear',
            ),
          if (!_isSearching)
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Color(0xFF8B5CF6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(7),
              ),
              child:
                  Icon(Icons.tune_rounded, color: Color(0xFF8B5CF6), size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          if (_searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('No results found.',
                  style: GoogleFonts.inter(fontSize: 15)),
            ),
          if (_searchResults.isNotEmpty)
            SizedBox(
              height: 400,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _searchResults.length.clamp(0, 10),
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.withOpacity(0.1),
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final paper = _searchResults[index];
                  return _buildFeaturedResearchItem(context, paper, logger);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Overview',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: Color(0xFF1E293B),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981).withOpacity(0.5),
                            blurRadius: 3,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Live',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _isLoadingStats
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B5CF6),
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 125,
                      child: ListView(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        children: [
                          _buildModernStatCard(
                            label: 'Research Papers',
                            value: _totalPapers.toString(),
                            icon: Icons.description_rounded,
                            gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          SizedBox(width: 12),
                          _buildModernStatCard(
                            label: 'Faculty Members',
                            value: _totalFaculty.toString(),
                            icon: Icons.groups_rounded,
                            gradient: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          SizedBox(width: 12),
                          _buildModernStatCard(
                            label: 'Total Views',
                            value: _totalViews,
                            icon: Icons.visibility_rounded,
                            gradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                          ),
                          SizedBox(width: 12),
                          _buildModernStatCard(
                            label: 'Categories',
                            value: _mlCategories.toString(),
                            icon: Icons.category_rounded,
                            gradient: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                          ),
                        ],
                      ),
                    ),
                    if (_totalPapers == 0 && !_isLoadingStats)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildLoadDataButton(),
                      ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildLoadDataButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () async {
          final userAsync = ref.read(currentUserProvider);
          final user = userAsync.value;
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please log in first'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
            return;
          }

          setState(() => _isLoadingStats = true);

          try {
            final seeder = FirestoreSeeder();

            // Clear existing papers first
            await seeder.clearAllPapers();

            // Show progress message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('🌱 Loading 60 papers from 11 faculty members...'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF6366F1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }

            // Wait a moment for clear to complete
            await Future.delayed(Duration(milliseconds: 500));

            // Load fresh papers
            await seeder.seedSamplePapers(user.id);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '✅ Successfully loaded 60 faculty papers from 11 faculty members!'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }

            // Reload stats
            await _loadRealTimeStats();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error loading papers: $e'),
                backgroundColor: Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            setState(() => _isLoadingStats = false);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_download_rounded,
                    color: Color(0xFF8B5CF6), size: 20),
                SizedBox(width: 10),
                Text(
                  'Load Faculty Papers',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatCard({
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      width: 120,
      child: Container(
        padding: EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.2),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 15),
              ),
              SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.7,
                  height: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedResearchSection(
      BuildContext context, UIIntegrationService uiService, Logger logger) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.star_rounded,
                    color: AppTheme.primaryBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Featured Research',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkSlate,
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Add navigation logic here
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  backgroundColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<ResearchPaper>>(
            future: uiService.getTrendingPapers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildFeaturedResearchShimmer();
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      'Error loading featured research: [200m${snapshot.error}[0m'),
                );
              }
              final papers = snapshot.data ?? [];
              if (papers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child:
                      Center(child: Text('No featured research available yet')),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: papers.length.clamp(0, 5),
                separatorBuilder: (context, index) => Column(
                  children: [
                    SizedBox(height: 4),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.withOpacity(0.1),
                      indent: 16,
                      endIndent: 16,
                    ),
                    SizedBox(height: 4),
                  ],
                ),
                itemBuilder: (context, index) {
                  final paper = papers[index];
                  return _buildFeaturedResearchItem(context, paper, logger);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedResearchShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 4),
                Container(
                    height: 16,
                    width: 200,
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4))),
                    Container(
                        height: 12,
                        width: 40,
                        decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedResearchItem(
      BuildContext context, ResearchPaper paper, Logger logger) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPaper(context, paper, logger),
        hoverColor: Colors.grey.withOpacity(0.05),
        splashColor: AppTheme.primaryBlue.withOpacity(0.05),
        highlightColor: AppTheme.primaryBlue.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description_rounded,
                    color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paper.title,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: AppTheme.darkSlate),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 14, color: const Color(0xFF6B7280)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            paper.author,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w400),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFD1D5DB),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 1,
                                    offset: const Offset(0, 1))
                              ]),
                          child: Text(
                            paper.year,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF4B5563),
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppTheme.primaryBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(
      UIIntegrationService uiService, Logger logger) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.lightGray,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.psychology_outlined,
                    color: AppTheme.primaryBlue,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Recommendations',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCustomRecommendationList(uiService, logger),
        ],
      ),
    );
  }

  Widget _buildCustomRecommendationList(
      UIIntegrationService uiService, Logger logger) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppTheme.primaryBlue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Recommended for You',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // Add navigation logic here
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppTheme.primaryBlue,
                      backgroundColor: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See All',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<ResearchPaper>>(
            future: uiService.getPersonalizedRecommendations('current_user'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildRecommendationShimmer();
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      'Error loading recommendations: [200m${snapshot.error}[0m'),
                );
              }
              final papers = snapshot.data ?? [];
              if (papers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No recommendations available yet'),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: papers.length.clamp(0, 5),
                separatorBuilder: (context, index) => Column(
                  children: [
                    SizedBox(height: 4),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.withOpacity(0.1),
                      indent: 16,
                      endIndent: 16,
                    ),
                    SizedBox(height: 4),
                  ],
                ),
                itemBuilder: (context, index) {
                  final paper = papers[index];
                  return RecommendationListItem(
                    paper: paper,
                    logger: logger,
                    openPaperCallback: _openPaper,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 16,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 12,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
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

class RecommendationListItem extends StatefulWidget {
  final ResearchPaper paper;
  final Logger logger;
  final Function(BuildContext, ResearchPaper, Logger) openPaperCallback;

  const RecommendationListItem({
    Key? key,
    required this.paper,
    required this.logger,
    required this.openPaperCallback,
  }) : super(key: key);

  @override
  _RecommendationListItemState createState() => _RecommendationListItemState();
}

class _RecommendationListItemState extends State<RecommendationListItem> {
  bool _isExpanded = false;
  bool _isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    final paper = widget.paper;
    final logger = widget.logger;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
          HapticFeedback.selectionClick();
        },
        onLongPress: () => widget.openPaperCallback(context, paper, logger),
        hoverColor: Colors.grey.withOpacity(0.05),
        splashColor: AppTheme.primaryBlue.withOpacity(0.05),
        highlightColor: AppTheme.primaryBlue.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      paper.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AppTheme.darkSlate,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 18,
                      color: _isBookmarked
                          ? AppTheme.primaryBlue
                          : const Color(0xFF9CA3AF),
                    ),
                    constraints:
                        const BoxConstraints(minHeight: 20, minWidth: 20),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _isBookmarked = !_isBookmarked;
                      });
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isBookmarked
                              ? 'Added to your bookmarks'
                              : 'Removed from your bookmarks'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 14, color: const Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      paper.author,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 1,
                            offset: const Offset(0, 1))
                      ],
                    ),
                    child: Text(
                      paper.year,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isExpanded && paper.abstract.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.lightGray, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abstract',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        paper.abstract,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.5,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => widget.openPaperCallback(
                                context, paper, logger),
                            icon: const Icon(Icons.article_outlined, size: 16),
                            label: const Text('Read Full Paper'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (!_isExpanded) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tap to see abstract',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.mediumGray.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more,
                      size: 14,
                      color: AppTheme.mediumGray.withOpacity(0.7),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
