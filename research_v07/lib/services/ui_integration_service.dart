import 'package:flutter/material.dart';
import '../services/ml_categorization_service.dart';
import '../services/recommendation_service.dart';
import '../services/analytics_service.dart';
import '../services/admin_service.dart';
import '../models/research_paper.dart';
import '../data/faculty_data.dart';

class UIIntegrationService {
  static final UIIntegrationService _instance =
      UIIntegrationService._internal();
  factory UIIntegrationService() => _instance;
  UIIntegrationService._internal();

  // Service instances
  final MLCategorizationService _mlService = MLCategorizationService();
  final RecommendationService _recommendationService = RecommendationService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final AdminService _adminService = AdminService();

  bool _isInitialized = false;

  // Initialize all services
  Future<void> initializeServices() async {
    if (_isInitialized) return;

    try {
      await Future.wait([
        _recommendationService.initialize(),
        _analyticsService.initialize(),
        _adminService.initialize(),
      ]);

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing services: $e');
      rethrow;
    }
  }

  // Search functionality using existing data
  List<ResearchPaper> performSimpleSearch(String query) {
    final allPapers = <ResearchPaper>[];
    facultyResearchPapers.forEach((_, papers) => allPapers.addAll(papers));

    if (query.isEmpty) return allPapers;

    final queryLower = query.toLowerCase();
    return allPapers.where((paper) {
      return paper.title.toLowerCase().contains(queryLower) ||
          paper.author.toLowerCase().contains(queryLower) ||
          paper.abstract.toLowerCase().contains(queryLower) ||
          paper.keywords
              .any((keyword) => keyword.toLowerCase().contains(queryLower));
    }).toList();
  }

  List<String> getSearchSuggestions(String partialQuery) {
    final allPapers = <ResearchPaper>[];
    facultyResearchPapers.forEach((_, papers) => allPapers.addAll(papers));

    final suggestions = <String>{};
    final queryLower = partialQuery.toLowerCase();

    for (final paper in allPapers) {
      // Add matching titles
      if (paper.title.toLowerCase().contains(queryLower)) {
        suggestions.add(paper.title);
      }

      // Add matching keywords
      for (final keyword in paper.keywords) {
        if (keyword.toLowerCase().contains(queryLower)) {
          suggestions.add(keyword);
        }
      }

      // Add matching authors
      if (paper.author.toLowerCase().contains(queryLower)) {
        suggestions.add(paper.author);
      }
    }

    return suggestions.take(10).toList();
  }

  // ML and Categorization
  Future<List<PaperCluster>> getResearchClusters() async {
    await _ensureInitialized();
    return await _mlService.performKMeansClustering();
  }

  List<String> getTrendingTopics({int limit = 10}) {
    final allPapers = <ResearchPaper>[];
    facultyResearchPapers.forEach((_, papers) => allPapers.addAll(papers));

    final keywordCounts = <String, int>{};
    for (final paper in allPapers) {
      for (final keyword in paper.keywords) {
        keywordCounts[keyword] = (keywordCounts[keyword] ?? 0) + 1;
      }
    }

    final sortedKeywords = keywordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedKeywords.take(limit).map((e) => e.key).toList();
  }

  List<String> getResearchTrends() {
    // Simplified trends based on paper years
    final allPapers = <ResearchPaper>[];
    facultyResearchPapers.forEach((_, papers) => allPapers.addAll(papers));

    final yearCounts = <String, int>{};
    for (final paper in allPapers) {
      yearCounts[paper.year] = (yearCounts[paper.year] ?? 0) + 1;
    }

    final sortedYears = yearCounts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return sortedYears
        .take(5)
        .map((e) => 'Research in ${e.key}: ${e.value} papers')
        .toList();
  }

  Map<String, double> getTopicDistribution() {
    final allPapers = <ResearchPaper>[];
    facultyResearchPapers.forEach((_, papers) => allPapers.addAll(papers));

    final keywordCounts = <String, int>{};
    for (final paper in allPapers) {
      for (final keyword in paper.keywords) {
        keywordCounts[keyword] = (keywordCounts[keyword] ?? 0) + 1;
      }
    }

    final total = keywordCounts.values.fold(0, (a, b) => a + b);
    if (total == 0) return {};

    return keywordCounts.map((key, value) => MapEntry(key, value / total));
  }

  // Recommendation System
  Future<List<ResearchPaper>> getPersonalizedRecommendations(
      String userId) async {
    await _ensureInitialized();
    final recommendations =
        await _recommendationService.getPersonalizedRecommendations(userId);
    return recommendations.map((rec) => rec.paper).toList();
  }

  Future<List<ResearchPaper>> getTrendingPapers() async {
    await _ensureInitialized();
    final trending = await _recommendationService.getTrendingRecommendations();
    return trending.map((rec) => rec.paper).toList();
  }

  List<ResearchPaper> getSimilarPapers(String paperId) {
    final allPapers = <ResearchPaper>[];
    facultyResearchPapers.forEach((_, papers) => allPapers.addAll(papers));

    final targetPaper = allPapers.firstWhere(
      (paper) => paper.id == paperId,
      orElse: () => allPapers.isNotEmpty
          ? allPapers.first
          : ResearchPaper(
              id: '',
              title: '',
              author: '',
              abstract: '',
              keywords: [],
              pdfUrl: '',
              year: '',
              citations: 0,
              journalName: '',
              doi: '',
            ),
    );

    if (targetPaper.id.isEmpty) return [];

    // Simple similarity based on keywords
    final similarPapers = <ResearchPaper>[];
    for (final paper in allPapers) {
      if (paper.id == paperId) continue;

      final commonKeywords = paper.keywords
          .where((keyword) => targetPaper.keywords.contains(keyword))
          .length;

      if (commonKeywords > 0) {
        similarPapers.add(paper);
      }
    }

    // Sort by similarity (more common keywords = more similar)
    similarPapers.sort((a, b) {
      final aCommon =
          a.keywords.where((k) => targetPaper.keywords.contains(k)).length;
      final bCommon =
          b.keywords.where((k) => targetPaper.keywords.contains(k)).length;
      return bCommon.compareTo(aCommon);
    });

    return similarPapers.take(5).toList();
  }

  Future<List<ResearchPaper>> getCollaborativeRecommendations(
      String userId) async {
    await _ensureInitialized();
    final recommendations =
        await _recommendationService.getHybridRecommendations(userId);
    return recommendations.map((rec) => rec.paper).toList();
  }

  // Analytics Dashboard
  Future<AnalyticsDashboard> getDashboardData({int days = 30}) async {
    await _ensureInitialized();
    return _analyticsService.getDashboardData(days: days);
  }

  Future<List<TrendingPaper>> getTrendingPapersAnalytics(
      {int limit = 10}) async {
    await _ensureInitialized();
    return _analyticsService.getTrendingPapers(limit: limit);
  }

  Future<CitationAnalytics> getCitationAnalytics(String paperId) async {
    await _ensureInitialized();
    return _analyticsService.getCitationAnalytics(paperId);
  }

  Future<ResearchPerformance> getResearchPerformance(String authorId) async {
    await _ensureInitialized();
    return _analyticsService.getResearchPerformance(authorId);
  }

  // User Interaction Tracking
  Future<void> trackPaperView(String paperId, String userId,
      {String? referrer}) async {
    await _ensureInitialized();
    await _analyticsService.trackPaperView(paperId, userId, referrer: referrer);
  }

  Future<void> trackPaperDownload(String paperId, String userId) async {
    await _ensureInitialized();
    await _analyticsService.trackPaperDownload(paperId, userId);
  }

  Future<void> trackSearch(String query, String userId, int resultCount) async {
    await _ensureInitialized();
    await _analyticsService.trackSearch(query, userId, resultCount);
  }

  // Admin Functions
  Future<AdminAuthResult> authenticateAdmin(
      String username, String password) async {
    await _ensureInitialized();
    return await _adminService.authenticateAdmin(username, password);
  }

  Future<SystemHealthReport> getSystemHealth() async {
    await _ensureInitialized();
    return await _adminService.getSystemHealth();
  }

  Future<AdminAnalytics> getAdminAnalytics({int days = 30}) async {
    await _ensureInitialized();
    return await _adminService.getAdminAnalytics(days: days);
  }

  Future<List<SystemLog>> getSystemLogs({int limit = 100}) async {
    await _ensureInitialized();
    return await _adminService.getSystemLogs(limit: limit);
  }

  // Widget Helpers for UI
  Widget buildSearchWidget({
    required Function(String) onSearch,
    required Function(String) onSuggestionTap,
  }) {
    return SearchWidget(
      onSearch: onSearch,
      onSuggestionTap: onSuggestionTap,
      searchService: this,
    );
  }

  Widget buildRecommendationWidget({
    required String userId,
    required Function(ResearchPaper) onPaperTap,
  }) {
    return RecommendationWidget(
      userId: userId,
      onPaperTap: onPaperTap,
      integrationService: this,
    );
  }

  Widget buildAnalyticsWidget({
    required int days,
  }) {
    return AnalyticsWidget(
      days: days,
      integrationService: this,
    );
  }

  Widget buildTrendingTopicsWidget({
    required Function(String) onTopicTap,
  }) {
    return TrendingTopicsWidget(
      onTopicTap: onTopicTap,
      integrationService: this,
    );
  }

  Widget buildAdminDashboardWidget() {
    return AdminDashboardWidget(
      integrationService: this,
    );
  }

  // Utility Functions
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initializeServices();
    }
  }

  // Export all data
  Future<Map<String, dynamic>> exportAllData() async {
    await _ensureInitialized();
    return await _adminService.exportAllData();
  }

  // System optimization
  Future<void> optimizeSystem() async {
    await _ensureInitialized();
    await _adminService.optimizeDatabase();
    await _adminService.clearCache();
  }

  // Get service status
  ServiceStatus getServiceStatus() {
    return ServiceStatus(
      isInitialized: _isInitialized,
      searchService: _isInitialized,
      mlService: _isInitialized,
      recommendationService: _isInitialized,
      analyticsService: _isInitialized,
      adminService: _isInitialized,
    );
  }
}

// UI Widget Classes
class SearchWidget extends StatefulWidget {
  final Function(String) onSearch;
  final Function(String) onSuggestionTap;
  final UIIntegrationService searchService;

  const SearchWidget({
    super.key,
    required this.onSearch,
    required this.onSuggestionTap,
    required this.searchService,
  });

  @override
  SearchWidgetState createState() => SearchWidgetState();
}

class SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _controller = TextEditingController();
  List<String> _suggestions = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Search research papers...',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: widget.onSearch,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Card(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_suggestions[index]),
                    onTap: () => widget.onSuggestionTap(_suggestions[index]),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final suggestions =
          await widget.searchService.getSearchSuggestions(query);
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class RecommendationWidget extends StatelessWidget {
  final String userId;
  final Function(ResearchPaper) onPaperTap;
  final UIIntegrationService integrationService;

  const RecommendationWidget({
    super.key,
    required this.userId,
    required this.onPaperTap,
    required this.integrationService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommended for You',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Add See All functionality here
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<ResearchPaper>>(
              future: integrationService.getPersonalizedRecommendations(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingShimmer();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final papers = snapshot.data ?? [];
                return ListView.separated(
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: papers.length,
                  itemBuilder: (context, index) {
                    final paper = papers[index];
                    return _buildRecommendationItem(context, paper);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(BuildContext context, ResearchPaper paper) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onPaperTap(paper),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paper.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      paper.author,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      paper.year,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
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
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
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
    );
  }
}

class AnalyticsWidget extends StatelessWidget {
  final int days;
  final UIIntegrationService integrationService;

  const AnalyticsWidget({
    super.key,
    required this.days,
    required this.integrationService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Dashboard (Last $days days)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<AnalyticsDashboard>(
              future: integrationService.getDashboardData(days: days),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final dashboard = snapshot.data!;
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                            'Views', dashboard.totalViews.toString()),
                        _buildStatCard(
                            'Downloads', dashboard.totalDownloads.toString()),
                        _buildStatCard(
                            'Users', dashboard.totalUsers.toString()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Trending Topics:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      children: dashboard.trendingTopics
                          .map((topic) => Chip(label: Text(topic)))
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class TrendingTopicsWidget extends StatelessWidget {
  final Function(String) onTopicTap;
  final UIIntegrationService integrationService;

  const TrendingTopicsWidget({
    super.key,
    required this.onTopicTap,
    required this.integrationService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trending Topics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<String>>(
              future: Future.value(integrationService.getTrendingTopics()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final topics = snapshot.data ?? [];
                return Wrap(
                  children: topics
                      .map((topic) => ActionChip(
                            label: Text(topic),
                            onPressed: () => onTopicTap(topic),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboardWidget extends StatelessWidget {
  final UIIntegrationService integrationService;

  const AdminDashboardWidget({
    super.key,
    required this.integrationService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Health',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<SystemHealthReport>(
              future: integrationService.getSystemHealth(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final health = snapshot.data!;
                return Column(
                  children: [
                    _buildHealthIndicator(health.overallStatus),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCard(
                            'Papers', health.totalPapers.toString()),
                        _buildMetricCard(
                            'Faculty', health.totalFaculty.toString()),
                        _buildMetricCard(
                            'Active Users', health.activeUsers.toString()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCard('Memory',
                            '${health.memoryUsage.toStringAsFixed(1)}%'),
                        _buildMetricCard('Storage',
                            '${health.storageUsage.toStringAsFixed(1)}%'),
                        _buildMetricCard('Response Time',
                            '${health.averageResponseTime.toStringAsFixed(1)}ms'),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(SystemStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case SystemStatus.healthy:
        color = Colors.green;
        text = 'Healthy';
        icon = Icons.check_circle;
        break;
      case SystemStatus.warning:
        color = Colors.orange;
        text = 'Warning';
        icon = Icons.warning;
        break;
      case SystemStatus.critical:
        color = Colors.red;
        text = 'Critical';
        icon = Icons.error;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// Supporting Data Classes
class ServiceStatus {
  final bool isInitialized;
  final bool searchService;
  final bool mlService;
  final bool recommendationService;
  final bool analyticsService;
  final bool adminService;

  ServiceStatus({
    required this.isInitialized,
    required this.searchService,
    required this.mlService,
    required this.recommendationService,
    required this.analyticsService,
    required this.adminService,
  });
}
