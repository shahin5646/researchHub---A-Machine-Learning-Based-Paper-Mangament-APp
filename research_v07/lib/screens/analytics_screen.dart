import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart' as analytics;
import '../services/pdf_service.dart';
import '../data/faculty_data.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final analytics.AnalyticsService _analyticsService =
      analytics.AnalyticsService();
  final PdfService _pdfService = PdfService();

  late AnimationController _animationController;
  Timer? _refreshTimer;

  String _scope = 'Last 30 Days';
  int _selectedDays = 30;
  bool _loading = true;

  // Real-time ML-based analytics data
  analytics.AnalyticsDashboard? _dashboard;
  int totalPublications = 0;
  int totalCitations = 0;
  int totalViews = 0;
  int totalDownloads = 0;
  int activeUsers = 0;
  double hIndex = 0;
  double avgCitations = 0.0;
  int mlCategories = 0;
  List<analytics.TrendingPaper> _topPapers = [];
  List<String> _trendingTopics = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _initializeAnalytics();
    _animationController.forward();

    // Real-time updates every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchAnalyticsData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeAnalytics() async {
    await _analyticsService.initialize();
    await _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      // Get real-time dashboard data
      final dashboard = _analyticsService.getDashboardData(days: _selectedDays);

      // Get all papers for publication stats
      final allPapers = await _pdfService.getAllPapersIncludingUserUploads();

      // Get ML categorized data
      final categorizedData =
          await _pdfService.getCategorizedPapersWithUploads();

      // Get trending papers
      final trending =
          _analyticsService.getTrendingPapers(limit: 10, days: _selectedDays);

      // Get trending topics from real activity, or fallback to ML category names
      List<String> trendingTopicsList = dashboard.trendingTopics;
      if (trendingTopicsList.isEmpty && categorizedData.isNotEmpty) {
        // Use ML-discovered category names as fallback (real ML data, not dummy)
        trendingTopicsList = categorizedData.keys.take(10).toList();
      }

      // Calculate total citations from all faculty papers
      int totalCitationsCount = 0;
      int totalPapersCount = 0;
      facultyResearchPapers.forEach((_, papers) {
        totalPapersCount += papers.length;
        for (final paper in papers) {
          totalCitationsCount += paper.citations;
        }
      });

      // Calculate H-index
      final allFacultyPapers = <int>[];
      facultyResearchPapers.forEach((_, papers) {
        allFacultyPapers.addAll(papers.map((p) => p.citations));
      });
      allFacultyPapers.sort((a, b) => b.compareTo(a));
      int calculatedHIndex = 0;
      for (int i = 0; i < allFacultyPapers.length; i++) {
        if (allFacultyPapers[i] >= i + 1) {
          calculatedHIndex = i + 1;
        } else {
          break;
        }
      }

      if (mounted) {
        setState(() {
          _dashboard = dashboard;
          totalPublications = allPapers.length;
          totalCitations = totalCitationsCount;
          totalViews = dashboard.totalViews;
          totalDownloads = dashboard.totalDownloads;
          activeUsers = dashboard.totalUsers;
          hIndex = calculatedHIndex.toDouble();
          avgCitations = totalPapersCount > 0
              ? totalCitationsCount / totalPapersCount
              : 0.0;
          mlCategories = categorizedData.length;
          _topPapers = trending;
          _trendingTopics = trendingTopicsList;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching analytics: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildMinimalAppBar(isDarkMode),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterRow(isDarkMode),
                    const SizedBox(height: 24),
                    Text(
                      'Research Statistics',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver:
                  _loading ? _buildLoadingStats() : _buildStatsGrid(isDarkMode),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Research Impact',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _loading
                        ? _buildLoadingChart()
                        : _buildImpactChart(isDarkMode),
                    const SizedBox(height: 24),
                    Text(
                      'Publication Trends',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _loading
                        ? _buildLoadingChart()
                        : _buildTrendsChart(isDarkMode),
                    SizedBox(height: 24 + bottomPadding),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2025 Minimal App Bar
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
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
                      Icons.arrow_back_rounded,
                      color: isDarkMode
                          ? const Color(0xFF64748B)
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Analytics',
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
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Real-time ML',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF10B981),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
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
                      Icons.download_rounded,
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

  // 2025 Minimal Filter Row
  Widget _buildFilterRow(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildMinimalDropdown(
            value: _scope,
            items: ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'All Time'],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _scope = val;
                  _selectedDays = val == 'Last 7 Days'
                      ? 7
                      : val == 'Last 30 Days'
                          ? 30
                          : val == 'Last 90 Days'
                              ? 90
                              : 365;
                });
                _fetchAnalyticsData();
              }
            },
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _fetchAnalyticsData,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: isDarkMode
                        ? const Color(0xFF64748B)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Refresh',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                isDense: true,
                icon: const SizedBox.shrink(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
                dropdownColor:
                    isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                selectedItemBuilder: (BuildContext context) {
                  return items.map((item) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList();
                },
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color:
                isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B),
            size: 18,
          ),
        ],
      ),
    );
  }

  // 2025 Minimal Stats Grid
  Widget _buildStatsGrid(bool isDarkMode) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      delegate: SliverChildListDelegate([
        _buildMinimalStatCard(
          'Total Publications',
          totalPublications.toString(),
          Icons.description_outlined,
          const Color(0xFF3B82F6),
          isDarkMode,
        ),
        _buildMinimalStatCard(
          'Total Citations',
          totalCitations.toString(),
          Icons.format_quote_outlined,
          const Color(0xFF10B981),
          isDarkMode,
        ),
        _buildMinimalStatCard(
          'Real-time Views',
          totalViews.toString(),
          Icons.visibility_outlined,
          const Color(0xFFF59E0B),
          isDarkMode,
        ),
        _buildMinimalStatCard(
          'H-Index',
          hIndex.toStringAsFixed(0),
          Icons.leaderboard_rounded,
          const Color(0xFF8B5CF6),
          isDarkMode,
        ),
        _buildMinimalStatCard(
          'Avg. Citations',
          avgCitations.toStringAsFixed(1),
          Icons.bar_chart_rounded,
          const Color(0xFF14B8A6),
          isDarkMode,
        ),
        _buildMinimalStatCard(
          'ML Categories',
          mlCategories.toString(),
          Icons.category_outlined,
          const Color(0xFF6366F1),
          isDarkMode,
        ),
      ]),
    );
  }

  Widget _buildMinimalStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDarkMode
                  ? const Color(0xFF64748B)
                  : const Color(0xFF64748B),
              letterSpacing: -0.2,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStats() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      delegate: SliverChildListDelegate(
        List.generate(6, (i) => _buildShimmerCard()),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
    );
  }

  // 2025 Minimal Impact Chart with Trending Topics
  Widget _buildImpactChart(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 20,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trending Topics',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      _trendingTopics.isNotEmpty
                          ? 'From real user activity & ML categories'
                          : 'View papers to see trending topics',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDarkMode
                            ? const Color(0xFF64748B)
                            : const Color(0xFF64748B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _trendingTopics.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No trending topics yet',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDarkMode
                            ? const Color(0xFF475569)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _trendingTopics.take(10).map((topic) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        topic,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8B5CF6),
                          letterSpacing: -0.2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // 2025 Minimal Trends Chart with Top Papers
  Widget _buildTrendsChart(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  size: 20,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Trending Papers',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Real-time ML analytics',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDarkMode
                            ? const Color(0xFF64748B)
                            : const Color(0xFF64748B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _topPapers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No trending papers yet',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDarkMode
                            ? const Color(0xFF475569)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: _topPapers.take(5).map((trending) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trending.paper.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      size: 12,
                                      color: isDarkMode
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${trending.viewCount} views',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: isDarkMode
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF64748B),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.download_outlined,
                                      size: 12,
                                      color: isDarkMode
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${trending.downloadCount}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: isDarkMode
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF64748B),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  size: 12,
                                  color: const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  trending.trendScore.toStringAsFixed(0),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildLoadingChart() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      ),
    );
  }
}
