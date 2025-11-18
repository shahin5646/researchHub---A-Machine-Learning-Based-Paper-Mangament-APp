import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../data/faculty_data.dart';
import '../models/research_paper.dart';
import '../services/pdf_service.dart';
import '../services/analytics_service.dart' as analytics;
import 'research_papers_screen.dart';
import 'faculty_members_screen.dart';
import 'category_screen.dart';
import 'category_papers_screen.dart';

// Data Models
class RecentActivity {
  final String title;
  final String description;
  final DateTime time;
  final ActivityType type;

  RecentActivity({
    required this.title,
    required this.description,
    required this.time,
    required this.type,
  });
}

enum ActivityType {
  newPaper,
  citation,
  collaboration,
  update,
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  late AnimationController _filterController;

  // Services
  final PdfService _pdfService = PdfService();
  final analytics.AnalyticsService _analyticsService =
      analytics.AnalyticsService();

  // State variables
  bool _showFilters = false;
  bool _isLoading = true;

  // Real-time data
  Map<String, List<Map<String, dynamic>>> _mlCategories = {};
  List<RecentActivity> _recentActivities = [];
  int _totalPapers = 0;
  int _totalCitations = 0;
  int _activeProjects = 0;
  int _collaborations = 0;

  @override
  void initState() {
    super.initState();
    _filterController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _loadRealTimeData();
  }

  Future<void> _loadRealTimeData() async {
    setState(() => _isLoading = true);

    try {
      // Load ML categories (same as category_screen.dart and app drawer)
      final categorizedData =
          await _pdfService.getCategorizedPapersWithUploads();

      // Get real paper count and citations from Firestore
      final papersSnapshot =
          await FirebaseFirestore.instance.collection('papers').get();

      final paperCount = papersSnapshot.size;

      // Get unique authors (faculty count) - check authorId first
      final Set<String> uniqueAuthors = {};
      int totalCitations = 0;

      for (final doc in papersSnapshot.docs) {
        final data = doc.data();
        final authorId =
            data['authorId'] as String? ?? data['uploadedBy'] as String?;
        if (authorId != null && authorId.isNotEmpty) {
          uniqueAuthors.add(authorId);
        }
        // Sum citations from Firestore
        totalCitations += (data['citations'] ?? 0) as int;
      }

      // Get recent tracked activities from analytics service
      final allEvents = _analyticsService.getAllEvents();
      final recentEvents = allEvents
          .where((event) => event.timestamp
              .isAfter(DateTime.now().subtract(Duration(days: 7))))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Convert analytics events to RecentActivity objects
      final activities = recentEvents.take(5).map((event) {
        ActivityType type = ActivityType.update;
        String title = 'Activity';
        String description = '';

        if (event.eventType == analytics.AnalyticsEventType.view) {
          type = ActivityType.newPaper;
          title = 'Paper Viewed';
          description = event.paperId;
        } else if (event.eventType == analytics.AnalyticsEventType.download) {
          type = ActivityType.citation;
          title = 'Paper Downloaded';
          description = event.paperId;
        } else if (event.eventType == analytics.AnalyticsEventType.search) {
          type = ActivityType.collaboration;
          title = 'Search Performed';
          description =
              event.metadata['query']?.toString() ?? 'Research search';
        }

        return RecentActivity(
          title: title,
          description: description,
          time: event.timestamp,
          type: type,
        );
      }).toList();

      // Count active projects (faculty with recent papers in Firestore)
      int activeProjects = uniqueAuthors.length;

      setState(() {
        _mlCategories = categorizedData;
        _totalPapers = paperCount; // Use real Firestore count
        _totalCitations = totalCitations; // Use real Firestore citations
        _activeProjects = activeProjects;
        _collaborations =
            uniqueAuthors.length; // Use unique faculty from Firestore
        _recentActivities =
            activities.isNotEmpty ? activities : _createDefaultActivities();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading real-time data: $e');
      setState(() {
        _recentActivities = _createDefaultActivities();
        _isLoading = false;
      });
    }
  }

  List<RecentActivity> _createDefaultActivities() {
    // Fallback to show recent papers if no tracked activities yet
    final allPapers = <ResearchPaper>[];
    facultyResearchPapers.forEach((key, papers) {
      allPapers.addAll(papers);
    });

    return allPapers.take(3).map((paper) {
      return RecentActivity(
        title: 'Recent Paper',
        description: paper.title,
        time: DateTime.now().subtract(Duration(days: 1)),
        type: ActivityType.newPaper,
      );
    }).toList();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primaryBlue,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildMinimalAppBar(isDarkMode),
              _buildProgressMetrics(isDarkMode),
              SliverToBoxAdapter(child: SizedBox(height: 20)),
              _buildQuickActions(isDarkMode),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
              _buildRecentActivity(isDarkMode),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
              _buildFacultySection(isDarkMode),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
              _buildCategoriesSection(isDarkMode),
              SliverToBoxAdapter(child: SizedBox(height: 24 + bottomPadding)),
            ],
          ),
        ),
      ),
    );
  }

  // 2025 Minimal App Bar - Ultra Clean Design
  Widget _buildMinimalAppBar(bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Explore Research',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.8,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Discover insights, track progress, and connect',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDarkMode
                            ? const Color(0xFF64748B)
                            : const Color(0xFF64748B),
                        letterSpacing: -0.1,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Search Icon Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showSearchDialog(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDarkMode
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: isDarkMode
                          ? const Color(0xFF64748B)
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter Icon Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleFilters,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDarkMode
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _showFilters ? Icons.close_rounded : Icons.tune_rounded,
                      color: isDarkMode
                          ? const Color(0xFF64748B)
                          : const Color(0xFF64748B),
                      size: 20,
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

  // 2025 Minimal Progress Metrics - Flat Design
  Widget _buildProgressMetrics(bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Research Progress (2024)',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildMinimalProgressIndicator('Total Papers', _totalPapers,
                _totalPapers + 50, Icons.description_outlined),
            const SizedBox(height: 16),
            _buildMinimalProgressIndicator('Citations', _totalCitations,
                _totalCitations + 500, Icons.format_quote_outlined),
            const SizedBox(height: 16),
            _buildMinimalProgressIndicator('Active Projects', _activeProjects,
                _activeProjects + 5, Icons.folder_outlined),
            const SizedBox(height: 16),
            _buildMinimalProgressIndicator('Collaborations', _collaborations,
                _collaborations + 10, Icons.people_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalProgressIndicator(
      String label, int current, int total, IconData icon) {
    final progress = current / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$current/$total',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2025 Minimal Quick Actions - Flat Design
  Widget _buildQuickActions(bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMinimalActionButton(
                    'New Submission',
                    Icons.add_circle_outline_rounded,
                    const Color(0xFF3B82F6),
                    () => _showNewSubmissionDialog(),
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalActionButton(
                    'Join Project',
                    Icons.people_outline_rounded,
                    const Color(0xFF10B981),
                    () => _showJoinProjectDialog(),
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalActionButton(
                    'Analytics',
                    Icons.bar_chart_rounded,
                    const Color(0xFFF59E0B),
                    () => Navigator.pushNamed(context, '/analytics'),
                    isDarkMode,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalActionButton(String label, IconData icon, Color color,
      VoidCallback onTap, bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2025 Minimal Recent Activity - Flat Design
  Widget _buildRecentActivity(bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Activity',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showAllActivity(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        'View All',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_recentActivities.take(3).map(
                (activity) => _buildMinimalActivityCard(activity, isDarkMode))),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalActivityCard(RecentActivity activity, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: _getActivityColor(activity.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDarkMode
                        ? const Color(0xFF64748B)
                        : const Color(0xFF64748B),
                    letterSpacing: -0.2,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(activity.time),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDarkMode
                        ? const Color(0xFF475569)
                        : const Color(0xFF94A3B8),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2025 Minimal Faculty Section - Flat Design
  Widget _buildFacultySection(bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Faculty Highlights',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FacultyMembersScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        'View All',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: facultyMembers.take(5).length,
                itemBuilder: (context, index) {
                  final faculty = facultyMembers[index];
                  return _buildMinimalFacultyCard(faculty, isDarkMode);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalFacultyCard(dynamic faculty, bool isDarkMode) {
    // Get real paper count from facultyResearchPapers data
    final realPaperCount = facultyResearchPapers[faculty.name]?.length ?? 0;

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onFacultyTap(faculty),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Faculty Image
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(faculty.imageUrl ??
                            'assets/images/defaults/profile.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faculty.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        faculty.designation,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDarkMode
                              ? const Color(0xFF64748B)
                              : const Color(0xFF64748B),
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$realPaperCount papers',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2025 Minimal Categories Section - Flat Design
  Widget _buildCategoriesSection(bool isDarkMode) {
    // Use real ML categories from PdfService (same as category_screen.dart and app drawer)
    final categories = _mlCategories.entries.map((entry) {
      return {
        'name': entry.key,
        'icon': _getCategoryIcon(entry.key),
        'count': entry.value.length,
      };
    }).toList();

    // If no ML categories loaded yet, show loading or empty state
    if (categories.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: _isLoading
                ? CircularProgressIndicator(color: AppTheme.primaryBlue)
                : Text(
                    'No categories available',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Research Categories',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        'View All',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: categories.length > 4 ? 4 : categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildMinimalCategoryCard(
                  category['name'] as String,
                  category['icon'] as IconData,
                  category['count'] as int,
                  isDarkMode,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Get appropriate icon for category (same logic as category_screen.dart)
  IconData _getCategoryIcon(String categoryName) {
    final lowerName = categoryName.toLowerCase();

    // Computer Science & Technology
    if (lowerName.contains('computer') ||
        lowerName.contains('software') ||
        lowerName.contains('programming') ||
        lowerName.contains('algorithm')) {
      return Icons.computer_rounded;
    }
    // AI & Machine Learning
    if (lowerName.contains('ai') ||
        lowerName.contains('machine learning') ||
        lowerName.contains('neural') ||
        lowerName.contains('deep learning')) {
      return Icons.psychology_rounded;
    }
    // Data & Analytics
    if (lowerName.contains('data') ||
        lowerName.contains('analytics') ||
        lowerName.contains('mining') ||
        lowerName.contains('big data')) {
      return Icons.analytics_rounded;
    }
    // Security & Cryptography
    if (lowerName.contains('security') ||
        lowerName.contains('crypto') ||
        lowerName.contains('privacy') ||
        lowerName.contains('authentication')) {
      return Icons.security_rounded;
    }
    // Networks & Communication
    if (lowerName.contains('network') ||
        lowerName.contains('communication') ||
        lowerName.contains('wireless') ||
        lowerName.contains('iot')) {
      return Icons.wifi_rounded;
    }
    // Robotics & Hardware
    if (lowerName.contains('robot') ||
        lowerName.contains('hardware') ||
        lowerName.contains('embedded') ||
        lowerName.contains('sensor')) {
      return Icons.precision_manufacturing_rounded;
    }
    // Web & Mobile
    if (lowerName.contains('web') ||
        lowerName.contains('mobile') ||
        lowerName.contains('app') ||
        lowerName.contains('frontend')) {
      return Icons.phone_android_rounded;
    }
    // Education
    if (lowerName.contains('education') ||
        lowerName.contains('learning') ||
        lowerName.contains('teaching') ||
        lowerName.contains('pedagogy')) {
      return Icons.school_rounded;
    }
    // Business & Management
    if (lowerName.contains('business') ||
        lowerName.contains('management') ||
        lowerName.contains('economics') ||
        lowerName.contains('finance')) {
      return Icons.business_rounded;
    }
    // Medical & Health
    if (lowerName.contains('medical') ||
        lowerName.contains('health') ||
        lowerName.contains('biomedical') ||
        lowerName.contains('clinical')) {
      return Icons.biotech_rounded;
    }
    // Science & Engineering
    if (lowerName.contains('science') ||
        lowerName.contains('engineering') ||
        lowerName.contains('physics') ||
        lowerName.contains('chemistry')) {
      return Icons.science_rounded;
    }

    // Default icon
    return Icons.folder_rounded;
  }

  Widget _buildMinimalCategoryCard(
      String name, IconData icon, int count, bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to specific category papers screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryPapersScreen(category: name),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: AppTheme.primaryBlue,
                      size: 18,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Methods
  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    // Reload real-time data
    await _loadRealTimeData();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Advanced Search'),
        content: Text('Advanced search functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNewSubmissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Submission'),
        content: Text('Paper submission portal coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showJoinProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join Project'),
        content: Text('Project collaboration portal coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAllActivity() {
    Navigator.pushNamed(context, '/activity');
  }

  void _onFacultyTap(dynamic faculty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResearchPapersScreen(
          professorName: faculty.name,
        ),
      ),
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.newPaper:
        return AppTheme.primaryBlue;
      case ActivityType.citation:
        return AppTheme.accentGreen;
      case ActivityType.collaboration:
        return AppTheme.accentOrange;
      case ActivityType.update:
        return Colors.purple;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.newPaper:
        return Icons.article_outlined;
      case ActivityType.citation:
        return Icons.format_quote_outlined;
      case ActivityType.collaboration:
        return Icons.people_outline;
      case ActivityType.update:
        return Icons.update;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}
