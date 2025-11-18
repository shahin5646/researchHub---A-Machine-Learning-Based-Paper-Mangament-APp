import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/research_project.dart';
import '../models/task.dart';
import '../models/activity_log.dart';
import 'modern_project_details_screen.dart';

class ModernResearchProjectsScreen extends StatefulWidget {
  const ModernResearchProjectsScreen({Key? key}) : super(key: key);

  @override
  State<ModernResearchProjectsScreen> createState() =>
      _ModernResearchProjectsScreenState();
}

class _ModernResearchProjectsScreenState
    extends State<ModernResearchProjectsScreen> with TickerProviderStateMixin {
  // Controllers and Animation
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Data Storage
  Box<ResearchProject>? projectsBox;
  Box<Task>? tasksBox;
  Box<ActivityLog>? activityLogBox;
  late DateTime _initTime;
  List<ResearchProject> _fallbackProjects = [];

  // UI State
  String _searchQuery = '';
  String _sortBy = 'recent';
  String _selectedCategory = 'all';
  bool _isGridView = false;

  // 2025 Minimal Design Categories - Clean & Professional
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'label': 'All',
      'icon': Icons.apps_rounded,
      'color': const Color(0xFF0F172A),
    },
    {
      'id': 'active',
      'label': 'Active',
      'icon': Icons.play_circle_outline_rounded,
      'color': const Color(0xFF059669),
    },
    {
      'id': 'pending',
      'label': 'Pending',
      'icon': Icons.schedule_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': 'completed',
      'label': 'Done',
      'icon': Icons.check_circle_outline_rounded,
      'color': const Color(0xFF3B82F6),
    },
    {
      'id': 'collaborative',
      'label': 'Team',
      'icon': Icons.people_outline_rounded,
      'color': const Color(0xFF8B5CF6),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initTime = DateTime.now();
    _initializeAnimations();
    _openHiveBoxes();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _openHiveBoxes() async {
    try {
      debugPrint('Opening Hive boxes...');

      projectsBox = await Hive.openBox<ResearchProject>('projects');
      debugPrint('Projects box opened successfully');

      tasksBox = await Hive.openBox<Task>('tasks');
      debugPrint('Tasks box opened successfully');

      activityLogBox = await Hive.openBox<ActivityLog>('activity_logs');
      debugPrint('Activity log box opened successfully');

      // Start with empty projects box - no sample data
      debugPrint(
          'Projects box initialized with ${projectsBox!.length} projects');

      debugPrint('All boxes initialized successfully');
      setState(() {});
    } catch (e) {
      debugPrint('Error opening Hive boxes: $e');
      debugPrint('Stack trace: ${StackTrace.current}');

      // Create empty fallback data if Hive fails
      _createFallbackData();
      setState(() {});
    }
  }

  void _createFallbackData() {
    debugPrint('Creating empty fallback data...');
    _fallbackProjects = [];
    debugPrint(
        'Fallback data created with ${_fallbackProjects.length} projects');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if initialization is taking too long
    final now = DateTime.now();
    final isTimeout = now.difference(_initTime).inSeconds > 5;

    // Show loading only for a short time, then show content with available data
    if (projectsBox == null && _fallbackProjects.isEmpty && !isTimeout) {
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading projects...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Get projects from either Hive or fallback data
    List<ResearchProject> projects = [];
    try {
      if (projectsBox != null && projectsBox!.isNotEmpty) {
        projects = projectsBox!.values.toList();
        debugPrint('Using Hive data: ${projects.length} projects');
      } else {
        projects = _fallbackProjects;
        debugPrint('Using fallback data: ${projects.length} projects');
      }
    } catch (e) {
      debugPrint('Error getting projects, using fallback: $e');
      projects = _fallbackProjects;
    }

    final filteredProjects = _getFilteredProjects(projects);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(),
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  // Modern Header with Search
                  SliverToBoxAdapter(
                    child: _buildModernHeader(),
                  ),

                  // Add spacing after header
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),

                  // Statistics Dashboard
                  SliverToBoxAdapter(
                    child: _buildStatisticsDashboard(projects),
                  ),

                  // Add spacing after statistics
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 16),
                  ),

                  // Filter Categories
                  SliverToBoxAdapter(
                    child: _buildFilterCategories(),
                  ),

                  // Add spacing after categories
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),

                  // Sort and View Toggle
                  SliverToBoxAdapter(
                    child: _buildSortAndViewControls(),
                  ),

                  // Add spacing before projects list
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),

                  // Projects List/Grid
                  _buildProjectsSliverDisplay(filteredProjects),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: projects.isEmpty ? null : _buildModernFAB(),
    );
  }

  BoxDecoration _buildGradientBackground() {
    // 2025 Minimal: Clean white background with subtle gradient
    return const BoxDecoration(
      color: Color(0xFFFAFAFA),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    // 2025 Minimal: Clean, flat app bar with subtle border
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 22),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded,
              color: Color(0xFF64748B), size: 22),
          onPressed: () => _showOptionsMenu(),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 20,
        isSmallScreen ? 16 : 20,
        isSmallScreen ? 16 : 20,
        12,
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2025 Minimal: Clean title section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projects',
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 24 : 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage your research',
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 13 : 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Clean view toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggleButton(false, Icons.view_list_rounded),
                    _buildViewToggleButton(true, Icons.grid_view_rounded),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 14 : 16),

          // Clean Search Bar
          _buildModernSearchBar(),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(bool isGrid, IconData icon) {
    final isSelected = _isGridView == isGrid;
    return GestureDetector(
      onTap: () => setState(() => _isGridView = isGrid),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildModernSearchBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    // 2025 Minimal: Clean search with subtle border
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: isSmallScreen ? 'Search...' : 'Search projects...',
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: const Color(0xFF64748B),
            size: isSmallScreen ? 20 : 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: const Color(0xFF94A3B8),
                    size: isSmallScreen ? 18 : 20,
                  ),
                  onPressed: () => setState(() => _searchQuery = ''),
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  constraints: const BoxConstraints(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 14 : 16,
            vertical: isSmallScreen ? 12 : 14,
          ),
        ),
        style: GoogleFonts.inter(
          fontSize: isSmallScreen ? 14 : 15,
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildStatisticsDashboard(List<ResearchProject> projects) {
    final stats = _calculateStats(projects);

    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _buildStatCard(stat);
        },
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    // 2025 Minimal: Clean stat cards with subtle styling
    return Container(
      width: 140,
      height: 105, // Increased from 100 to prevent overflow
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          // Icon at the top
          Container(
            padding: const EdgeInsets.all(6), // Reduced to 6
            decoration: BoxDecoration(
              color: stat['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              stat['icon'],
              color: stat['color'],
              size: 18,
            ),
          ),

          const SizedBox(height: 6), // Reduced spacing

          // Value and label at the bottom
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Prevent overflow
            children: [
              Text(
                stat['value'].toString(),
                style: GoogleFonts.inter(
                  fontSize: 22, // Reduced from 24
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2), // Reduced spacing
              Text(
                stat['label'],
                style: GoogleFonts.inter(
                  fontSize: 11, // Reduced from 12
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                  letterSpacing: -0.1,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCategories() {
    // 2025 Minimal: Clean chip-style filters
    return Container(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'];

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'],
                    size: 16,
                    color: isSelected ? Colors.white : category['color'],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category['label'],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          isSelected ? Colors.white : const Color(0xFF475569),
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortAndViewControls() {
    // 2025 Minimal: Clean sort buttons
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Sort:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 12),
            _buildSortButton('recent', 'Recent'),
            const SizedBox(width: 6),
            _buildSortButton('name', 'Name'),
            const SizedBox(width: 6),
            _buildSortButton('progress', 'Progress'),
            const SizedBox(width: 6),
            _buildSortButton('deadline', 'Deadline'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton(String sortType, String label) {
    final isSelected = _sortBy == sortType;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = sortType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color:
                isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsSliverDisplay(List<ResearchProject> projects) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final horizontalPadding = isSmallScreen ? 16.0 : 24.0;

    if (projects.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    if (_isGridView) {
      return SliverPadding(
        padding:
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isSmallScreen ? 1 : 2,
            childAspectRatio: isSmallScreen ? 1.2 : 0.85,
            crossAxisSpacing: isSmallScreen ? 12 : 16,
            mainAxisSpacing: isSmallScreen ? 12 : 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildModernProjectGridCard(projects[index]),
            childCount: projects.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildModernProjectCard(projects[index], index),
          childCount: projects.length,
        ),
      ),
    );
  }

  Widget _buildModernProjectCard(ResearchProject project, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final cardPadding = isSmallScreen ? 16.0 : 20.0;

    // 2025 Minimal: Clean card design
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProjectDetails(project),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and menu
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildStatusBadge(project.status),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    _buildProjectMenu(project),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 10 : 12),

                // Description
                Text(
                  project.description,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: isSmallScreen ? 12 : 14),

                // Progress bar
                _buildProgressIndicator(project),

                SizedBox(height: isSmallScreen ? 12 : 14),

                // Footer with team and date
                Row(
                  children: [
                    // Team avatars
                    Flexible(
                      child: _buildTeamAvatars(project.teamMembers),
                    ),
                    const SizedBox(width: 8),
                    // Deadline
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 10,
                        vertical: isSmallScreen ? 4 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: isSmallScreen ? 11 : 12,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDeadline(project.endDate),
                            style: GoogleFonts.inter(
                              fontSize: isSmallScreen ? 11 : 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildModernProjectGridCard(ResearchProject project) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProjectDetails(project),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(child: _buildStatusBadge(project.status)),
                  _buildProjectMenu(project),
                ],
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                project.title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Description
              Expanded(
                child: Text(
                  project.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 16),

              // Progress
              _buildProgressIndicator(project),

              const SizedBox(height: 16),

              // Footer
              Row(
                children: [
                  _buildTeamAvatars(project.teamMembers, maxShow: 2),
                  const Spacer(),
                  Text(
                    '${project.progress.toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(project.status),
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

  Widget _buildStatusBadge(String status) {
    // 2025 Minimal: Clean minimal badge
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ResearchProject project) {
    // 2025 Minimal: Clean progress bar
    final color = _getStatusColor(project.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                letterSpacing: -0.1,
              ),
            ),
            Text(
              '${project.progress.toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: project.progress / 100,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamAvatars(List<String> teamMembers, {int maxShow = 3}) {
    if (teamMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        ...teamMembers.take(maxShow).map((member) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getAvatarColor(member),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                _getInitials(member),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }).toList(),
        if (teamMembers.length > maxShow)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF64748B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '+${teamMembers.length - maxShow}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProjectMenu(ResearchProject project) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: const Color(0xFF64748B),
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _handleMenuAction(value, project),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded,
                  size: 18, color: const Color(0xFF64748B)),
              const SizedBox(width: 12),
              Text('Edit Project'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy_rounded,
                  size: 18, color: const Color(0xFF64748B)),
              const SizedBox(width: 12),
              Text('Duplicate'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive_rounded,
                  size: 18, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              Text('Archive'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded,
                  size: 18, color: const Color(0xFFEF4444)),
              const SizedBox(width: 12),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    // 2025 Minimal: Clean empty state
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Projects Yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first research project',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w400,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showProjectCreationModal(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFAB() {
    // 2025 Minimal: Clean FAB
    return FloatingActionButton.extended(
      onPressed: () => _showProjectCreationModal(),
      backgroundColor: const Color(0xFF0F172A),
      elevation: 2,
      icon: const Icon(Icons.add, color: Colors.white, size: 22),
      label: Text(
        'New Project',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.2,
          fontSize: 14,
        ),
      ),
    );
  }

  // Helper Methods
  List<ResearchProject> _getFilteredProjects(List<ResearchProject> projects) {
    var filtered = projects.where((project) {
      // Category filter
      bool matchesCategory = _selectedCategory == 'all' ||
          (project.status.toLowerCase() == _selectedCategory);

      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          project.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          project.teamMembers.any((member) =>
              member.toLowerCase().contains(_searchQuery.toLowerCase()));

      return matchesCategory && matchesSearch;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'progress':
        filtered.sort((a, b) => b.progress.compareTo(a.progress));
        break;
      case 'deadline':
        filtered.sort((a, b) => a.endDate.compareTo(b.endDate));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) {
          final aDate = a.lastUpdated ?? DateTime.now();
          final bDate = b.lastUpdated ?? DateTime.now();
          return bDate.compareTo(aDate);
        });
        break;
    }

    return filtered;
  }

  List<Map<String, dynamic>> _calculateStats(List<ResearchProject> projects) {
    final totalProjects = projects.length;
    final activeProjects = projects.where((p) => p.status == 'Active').length;
    final completedProjects =
        projects.where((p) => p.status == 'Completed').length;
    final avgProgress = projects.isEmpty
        ? 0
        : (projects.map((p) => p.progress).reduce((a, b) => a + b) /
                projects.length *
                100)
            .round();

    return [
      {
        'label': 'Total',
        'value': totalProjects,
        'icon': Icons.folder_rounded,
        'color': const Color(0xFF6366F1),
        'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      },
      {
        'label': 'Active',
        'value': activeProjects,
        'icon': Icons.rocket_launch_rounded,
        'color': const Color(0xFF10B981),
        'gradient': [const Color(0xFF10B981), const Color(0xFF059669)],
      },
      {
        'label': 'Completed',
        'value': completedProjects,
        'icon': Icons.celebration_rounded,
        'color': const Color(0xFF3B82F6),
        'gradient': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      },
      {
        'label': 'Avg Progress',
        'value': '${avgProgress}%',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFFEC4899),
        'gradient': [const Color(0xFFEC4899), const Color(0xFFDB2777)],
      },
    ];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF3B82F6);
      case 'on hold':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
    ];
    return colors[name.hashCode % colors.length];
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDeadline(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference < 7) {
      return 'Due in $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Action Methods
  void _openProjectDetails(ResearchProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernProjectDetailsScreen(project: project),
      ),
    );
  }

  void _showProjectCreationModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModernProjectCreationModal(
        onProjectCreated: (project) {
          try {
            if (projectsBox != null) {
              projectsBox!.add(project);
            } else {
              // Add to fallback data if Hive is not available
              _fallbackProjects.add(project);
            }
          } catch (e) {
            debugPrint('Error saving project, adding to fallback: $e');
            _fallbackProjects.add(project);
          }
          setState(() {});
          Navigator.pop(context);
          _showSuccessSnackbar('Project created successfully!');
        },
      ),
    );
  }

  void _showOptionsMenu() {
    // Show options menu
  }

  void _handleMenuAction(String action, ResearchProject project) {
    switch (action) {
      case 'edit':
        _editProject(project);
        break;
      case 'duplicate':
        _duplicateProject(project);
        break;
      case 'archive':
        _archiveProject(project);
        break;
      case 'delete':
        _deleteProject(project);
        break;
    }
  }

  void _editProject(ResearchProject project) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ModernProjectCreationModal(
        isEditing: true,
        existingProject: project,
        onProjectCreated: (updatedProject) {
          try {
            if (projectsBox != null) {
              // Update the existing project in Hive
              final index = projectsBox!.values
                  .toList()
                  .indexWhere((p) => p.id == project.id);
              if (index != -1) {
                projectsBox!.putAt(index, updatedProject);
              }
            } else {
              // Update in fallback data
              final index =
                  _fallbackProjects.indexWhere((p) => p.id == project.id);
              if (index != -1) {
                _fallbackProjects[index] = updatedProject;
              }
            }
          } catch (e) {
            debugPrint('Error updating project, updating in fallback: $e');
            final index =
                _fallbackProjects.indexWhere((p) => p.id == project.id);
            if (index != -1) {
              _fallbackProjects[index] = updatedProject;
            }
          }
          setState(() {});
          Navigator.pop(context);
          _showSuccessSnackbar('Project updated successfully!');
        },
      ),
    );
  }

  void _duplicateProject(ResearchProject project) {
    final duplicatedProject = ResearchProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${project.title} (Copy)',
      description: project.description,
      status: 'Active',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 30)),
      progress: 0.0,
      teamMembers: project.teamMembers,
      tags: project.tags,
      fundingSource: project.fundingSource,
      budget: project.budget,
      publications: [],
      documents: [],
      lastUpdated: DateTime.now(),
    );

    try {
      if (projectsBox != null) {
        projectsBox!.add(duplicatedProject);
      } else {
        _fallbackProjects.add(duplicatedProject);
      }
    } catch (e) {
      debugPrint('Error saving duplicated project, adding to fallback: $e');
      _fallbackProjects.add(duplicatedProject);
    }
    setState(() {});
    _showSuccessSnackbar('Project duplicated successfully!');
  }

  void _archiveProject(ResearchProject project) {
    project.status = 'Archived';
    project.lastUpdated = DateTime.now();

    try {
      if (projectsBox != null) {
        project.save();
      }
      // For fallback data, the object is already updated in memory
    } catch (e) {
      debugPrint('Error saving archived project: $e');
      // Object is still updated in memory for fallback data
    }

    setState(() {});
    _showSuccessSnackbar('Project archived successfully!');
  }

  void _deleteProject(ResearchProject project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Project'),
        content: Text(
            'Are you sure you want to delete "${project.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                if (projectsBox != null) {
                  project.delete();
                } else {
                  // Remove from fallback data
                  _fallbackProjects.removeWhere((p) => p.id == project.id);
                }
              } catch (e) {
                debugPrint(
                    'Error deleting from Hive, removing from fallback: $e');
                _fallbackProjects.removeWhere((p) => p.id == project.id);
              }
              setState(() {});
              Navigator.pop(context);
              _showSuccessSnackbar('Project deleted successfully!');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Modern Project Creation Modal
class ModernProjectCreationModal extends StatefulWidget {
  final Function(ResearchProject) onProjectCreated;
  final bool isEditing;
  final ResearchProject? existingProject;

  const ModernProjectCreationModal({
    Key? key,
    required this.onProjectCreated,
    this.isEditing = false,
    this.existingProject,
  }) : super(key: key);

  @override
  State<ModernProjectCreationModal> createState() =>
      _ModernProjectCreationModalState();
}

class _ModernProjectCreationModalState
    extends State<ModernProjectCreationModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _objectivesController = TextEditingController();

  String _selectedCategory = 'Research';
  String _selectedStatus = 'Active';
  String _selectedPriority = 'Medium';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 30));
  double _progress = 0.0;
  List<String> _teamMembers = [];
  List<String> _tags = [];

  final List<String> _categories = [
    'Research',
    'Development',
    'Analysis',
    'Review',
    'Thesis',
    'Publication'
  ];

  final List<String> _statuses = ['Active', 'Pending', 'On Hold', 'Completed'];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingProject != null) {
      final project = widget.existingProject!;
      _titleController.text = project.title;
      _descriptionController.text = project.description;
      _selectedStatus = project.status;
      _startDate = project.startDate;
      _endDate = project.endDate;
      _progress = project.progress;
      _teamMembers = List<String>.from(project.teamMembers);
      _tags = List<String>.from(project.tags);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final isKeyboardVisible = keyboardHeight > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16, // Fixed padding, keyboard handled by maxHeight
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: screenHeight - keyboardHeight - 32,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header - Reduced padding when keyboard is visible
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical:
                    isKeyboardVisible ? 12 : 16, // Reduce when keyboard visible
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), // Light gray bg
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_note_outlined, // Minimal outlined icon
                      color: const Color(0xFF0F172A),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isEditing
                              ? 'Edit Project'
                              : 'Create New Project',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600, // Reduced from bold
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          widget.isEditing
                              ? 'Update your project details'
                              : 'Fill in your project details',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: const Color(0xFF64748B),
                      size: 20,
                    ),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            // Form Content - Reduced padding when keyboard is visible
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isKeyboardVisible
                      ? 12
                      : 16, // Reduce when keyboard visible
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      _buildFormField(
                        label: 'Project Title',
                        controller: _titleController,
                        validator: (value) =>
                            value?.isEmpty == true ? 'Title is required' : null,
                        icon: Icons.title,
                      ),
                      SizedBox(height: 14),

                      // Description
                      _buildFormField(
                        label: 'Description',
                        controller: _descriptionController,
                        maxLines: 2,
                        icon: Icons.description,
                      ),
                      SizedBox(height: 14),

                      // Category and Status Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Category',
                              value: _selectedCategory,
                              items: _categories,
                              onChanged: (value) =>
                                  setState(() => _selectedCategory = value!),
                              icon: Icons.category,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Status',
                              value: _selectedStatus,
                              items: _statuses,
                              onChanged: (value) =>
                                  setState(() => _selectedStatus = value!),
                              icon: Icons.assignment_turned_in,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),

                      // Priority and Progress Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Priority',
                              value: _selectedPriority,
                              items: _priorities,
                              onChanged: (value) =>
                                  setState(() => _selectedPriority = value!),
                              icon: Icons.priority_high,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progress',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF0F172A),
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    Text(
                                      '${(_progress * 100).toInt()}%',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbColor:
                                        const Color(0xFF0F172A), // Dark thumb
                                    activeTrackColor: const Color(0xFF0F172A),
                                    inactiveTrackColor: const Color(0xFFE2E8F0),
                                    trackHeight: 4, // Thinner track
                                    thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: 6), // Smaller thumb
                                    overlayShape: RoundSliderOverlayShape(
                                        overlayRadius: 12),
                                  ),
                                  child: Slider(
                                    value: _progress,
                                    onChanged: (value) =>
                                        setState(() => _progress = value),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),

                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'Start Date',
                              date: _startDate,
                              onChanged: (date) =>
                                  setState(() => _startDate = date),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildDateField(
                              label: 'End Date',
                              date: _endDate,
                              onChanged: (date) =>
                                  setState(() => _endDate = date),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions - Reduced padding when keyboard is visible
            Container(
              padding: EdgeInsets.all(
                  isKeyboardVisible ? 14 : 20), // Reduce when keyboard visible
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: isKeyboardVisible
                                ? 12
                                : 14), // Reduce when keyboard visible
                        side: BorderSide(color: const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500, // Reduced from w600
                          color: const Color(0xFF64748B),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12), // Reduced from 16
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createProject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: EdgeInsets.symmetric(
                            vertical: isKeyboardVisible
                                ? 12
                                : 14), // Reduce when keyboard visible
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.isEditing ? 'Update Project' : 'Create Project',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
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
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13, // Reduced from 14
            fontWeight: FontWeight.w500, // Reduced from w600
            color: const Color(0xFF0F172A),
            letterSpacing: -0.1,
          ),
        ),
        SizedBox(height: 6), // Reduced from 8
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.1,
          ),
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF64748B), size: 18)
                : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), // Reduced from 12
              borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: const Color(0xFF0F172A), width: 1.5), // Dark focus
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC), // Very subtle bg
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.1,
          ),
        ),
        SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true, // Prevents overflow
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.1,
          ),
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF64748B), size: 18)
                : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: const Color(0xFF0F172A), width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis, // Handle long text
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required Function(DateTime) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.1,
          ),
        ),
        SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now().subtract(Duration(days: 365)),
              lastDate: DateTime.now().add(Duration(days: 365 * 5)),
            );
            if (picked != null) onChanged(picked);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFF8FAFC),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined, // Outlined version
                  color: const Color(0xFF64748B),
                  size: 18,
                ),
                SizedBox(width: 10),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _createProject() {
    if (_formKey.currentState?.validate() == true) {
      final project = ResearchProject(
        id: widget.isEditing
            ? widget.existingProject!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        progress: _progress,
        teamMembers: _teamMembers,
        tags: _tags,
        fundingSource:
            widget.isEditing ? widget.existingProject!.fundingSource : '',
        budget: widget.isEditing ? widget.existingProject!.budget : 0.0,
        publications:
            widget.isEditing ? widget.existingProject!.publications : [],
        documents: widget.isEditing ? widget.existingProject!.documents : [],
        lastUpdated: DateTime.now(),
      );

      widget.onProjectCreated(project);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _objectivesController.dispose();
    super.dispose();
  }
}
