import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/research_paper.dart';
import '../data/faculty_data.dart';

// PaperAnalytics model for tracking analytics per paper
class PaperAnalytics {
  final String paperId;
  final int totalViews;
  final int totalDownloads;
  final int uniqueViewers;
  final double averageRating;
  final int totalRatings;
  final int totalComments;
  final int totalBookmarks;
  final Map<String, int> viewsByCountry;
  final Map<String, int> viewsByReferrer;
  final Map<DateTime, int> dailyViews;
  final List<String> topKeywords;
  final DateTime lastUpdated;

  PaperAnalytics({
    required this.paperId,
    this.totalViews = 0,
    this.totalDownloads = 0,
    this.uniqueViewers = 0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalComments = 0,
    this.totalBookmarks = 0,
    this.viewsByCountry = const {},
    this.viewsByReferrer = const {},
    this.dailyViews = const {},
    this.topKeywords = const [],
    required this.lastUpdated,
  });

  factory PaperAnalytics.fromJson(Map<String, dynamic> json) {
    return PaperAnalytics(
      paperId: json['paperId'],
      totalViews: json['totalViews'] ?? 0,
      totalDownloads: json['totalDownloads'] ?? 0,
      uniqueViewers: json['uniqueViewers'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      totalBookmarks: json['totalBookmarks'] ?? 0,
      viewsByCountry: Map<String, int>.from(json['viewsByCountry'] ?? {}),
      viewsByReferrer: Map<String, int>.from(json['viewsByReferrer'] ?? {}),
      dailyViews: (json['dailyViews'] != null)
          ? Map<DateTime, int>.fromEntries(
              (json['dailyViews'] as Map<String, dynamic>)
                  .entries
                  .map((e) => MapEntry(DateTime.parse(e.key), e.value as int)))
          : {},
      topKeywords: List<String>.from(json['topKeywords'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() => {
        'paperId': paperId,
        'totalViews': totalViews,
        'totalDownloads': totalDownloads,
        'uniqueViewers': uniqueViewers,
        'averageRating': averageRating,
        'totalRatings': totalRatings,
        'totalComments': totalComments,
        'totalBookmarks': totalBookmarks,
        'viewsByCountry': viewsByCountry,
        'viewsByReferrer': viewsByReferrer,
        'dailyViews':
            dailyViews.map((k, v) => MapEntry(k.toIso8601String(), v)),
        'topKeywords': topKeywords,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final Map<String, PaperAnalytics> _paperAnalytics = {};
  final Map<String, List<AnalyticsEvent>> _events = {};
  final Map<String, UserAnalytics> _userAnalytics = {};

  // Initialize analytics
  Future<void> initialize() async {
    await _loadAnalyticsData();
  }

  // Real-time analytics tracking
  Future<void> trackEvent(AnalyticsEvent event) async {
    _events[event.paperId] = _events[event.paperId] ?? [];
    _events[event.paperId]!.add(event);

    // Update paper analytics
    await _updatePaperAnalytics(event);

    // Update user analytics
    await _updateUserAnalytics(event);

    // Save to persistent storage
    await _saveAnalyticsData();
  }

  // Track paper view
  Future<void> trackPaperView(String paperId, String userId,
      {String? referrer, String? country}) async {
    await trackEvent(AnalyticsEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      paperId: paperId,
      userId: userId,
      eventType: AnalyticsEventType.view,
      timestamp: DateTime.now(),
      metadata: {
        'referrer': referrer ?? 'direct',
        'country': country ?? 'unknown',
      },
    ));
  }

  // Track paper download
  Future<void> trackPaperDownload(String paperId, String userId) async {
    await trackEvent(AnalyticsEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      paperId: paperId,
      userId: userId,
      eventType: AnalyticsEventType.download,
      timestamp: DateTime.now(),
    ));
  }

  // Track search query
  Future<void> trackSearch(String query, String userId, int resultCount) async {
    await trackEvent(AnalyticsEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      paperId: 'search',
      userId: userId,
      eventType: AnalyticsEventType.search,
      timestamp: DateTime.now(),
      metadata: {
        'query': query,
        'resultCount': resultCount,
      },
    ));
  }

  // Get comprehensive analytics dashboard data
  AnalyticsDashboard getDashboardData({int days = 30}) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final recentEvents = _getAllEvents()
        .where((event) => event.timestamp.isAfter(startDate))
        .toList();

    return AnalyticsDashboard(
      totalViews: _getTotalViews(recentEvents),
      totalDownloads: _getTotalDownloads(recentEvents),
      totalUsers: _getUniqueUsers(recentEvents).length,
      totalPapers: _paperAnalytics.length,
      topPapers: _getTopPapers(limit: 10),
      trendingTopics: _getTrendingTopics(days: days),
      userEngagement: _getUserEngagementMetrics(recentEvents),
      geographicData: _getGeographicData(recentEvents),
      timeSeriesData: _getTimeSeriesData(recentEvents, days: days),
      searchInsights: _getSearchInsights(recentEvents),
    );
  }

  // Get paper-specific analytics
  PaperAnalytics? getPaperAnalytics(String paperId) {
    return _paperAnalytics[paperId];
  }

  // Public method to get all events (for recent activity display)
  List<AnalyticsEvent> getAllEvents() {
    return _getAllEvents();
  }

  // Get trending papers
  List<TrendingPaper> getTrendingPapers({int limit = 10, int days = 7}) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final recentViews = <String, int>{};
    final recentDownloads = <String, int>{};

    for (final events in _events.values) {
      for (final event in events) {
        if (event.timestamp.isAfter(startDate)) {
          if (event.eventType == AnalyticsEventType.view) {
            recentViews[event.paperId] = (recentViews[event.paperId] ?? 0) + 1;
          } else if (event.eventType == AnalyticsEventType.download) {
            recentDownloads[event.paperId] =
                (recentDownloads[event.paperId] ?? 0) + 1;
          }
        }
      }
    }

    final trendingPapers = <TrendingPaper>[];
    for (final paperId in recentViews.keys) {
      final paper = _findPaperById(paperId);
      if (paper != null) {
        final score = (recentViews[paperId] ?? 0) * 1.0 +
            (recentDownloads[paperId] ?? 0) * 3.0;
        trendingPapers.add(TrendingPaper(
          paper: paper,
          viewCount: recentViews[paperId] ?? 0,
          downloadCount: recentDownloads[paperId] ?? 0,
          trendScore: score,
        ));
      }
    }

    // Return ONLY real tracked data - no mock/dummy data
    trendingPapers.sort((a, b) => b.trendScore.compareTo(a.trendScore));
    return trendingPapers.take(limit).toList();
  }

  // Citation analytics
  CitationAnalytics getCitationAnalytics(String paperId) {
    final paper = _findPaperById(paperId);
    if (paper == null) {
      return CitationAnalytics(
        paperId: paperId,
        totalCitations: 0,
        hIndex: 0,
        citationTrend: [],
        citingPapers: [],
      );
    }

    // Mock citation data - in real app, this would come from external APIs
    final citationTrend = _generateMockCitationTrend(paper);
    final citingPapers = _findCitingPapers(paperId);

    return CitationAnalytics(
      paperId: paperId,
      totalCitations: paper.citations,
      hIndex: _calculateHIndex([paper]),
      citationTrend: citationTrend,
      citingPapers: citingPapers,
    );
  }

  // Research performance metrics
  ResearchPerformance getResearchPerformance(String authorId) {
    final authorPapers = _getAuthorPapers(authorId);

    return ResearchPerformance(
      authorId: authorId,
      totalPapers: authorPapers.length,
      totalCitations:
          authorPapers.map((p) => p.citations).fold(0, (a, b) => a + b),
      hIndex: _calculateHIndex(authorPapers),
      averageCitations: authorPapers.isNotEmpty
          ? authorPapers.map((p) => p.citations).reduce((a, b) => a + b) /
              authorPapers.length
          : 0.0,
      publicationTrend: _getPublicationTrend(authorPapers),
      collaborationNetwork: _getCollaborationNetwork(authorId),
      topKeywords: _getAuthorTopKeywords(authorPapers),
    );
  }

  // Advanced search analytics
  SearchAnalytics getSearchAnalytics({int days = 30}) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final searchEvents = _getAllEvents()
        .where((event) =>
            event.eventType == AnalyticsEventType.search &&
            event.timestamp.isAfter(startDate))
        .toList();

    final queries = <String, int>{};
    final zeroResultQueries = <String>[];

    for (final event in searchEvents) {
      final query = event.metadata['query'] as String?;
      final resultCount = event.metadata['resultCount'] as int?;

      if (query != null) {
        queries[query] = (queries[query] ?? 0) + 1;

        if (resultCount == 0) {
          zeroResultQueries.add(query);
        }
      }
    }

    return SearchAnalytics(
      totalSearches: searchEvents.length,
      uniqueQueries: queries.length,
      topQueries: _getTopQueries(queries),
      zeroResultQueries: zeroResultQueries,
      averageResultsPerQuery: _calculateAverageResults(searchEvents),
      searchTrends: _getSearchTrends(searchEvents),
    );
  }

  // Export analytics data
  Map<String, dynamic> exportAnalytics(
      {DateTime? startDate, DateTime? endDate}) {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final filteredEvents = _getAllEvents()
        .where((event) =>
            event.timestamp.isAfter(start) && event.timestamp.isBefore(end))
        .toList();

    return {
      'period': {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
      'summary': {
        'totalEvents': filteredEvents.length,
        'uniqueUsers': _getUniqueUsers(filteredEvents).length,
        'totalViews': _getTotalViews(filteredEvents),
        'totalDownloads': _getTotalDownloads(filteredEvents),
      },
      'events': filteredEvents.map((e) => e.toJson()).toList(),
      'paperAnalytics': _paperAnalytics.map((k, v) => MapEntry(k, v.toJson())),
      'userAnalytics': _userAnalytics.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  // Private helper methods
  Future<void> _updatePaperAnalytics(AnalyticsEvent event) async {
    _paperAnalytics[event.paperId] = _paperAnalytics[event.paperId] ??
        PaperAnalytics(paperId: event.paperId, lastUpdated: DateTime.now());

    final analytics = _paperAnalytics[event.paperId]!;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    switch (event.eventType) {
      case AnalyticsEventType.view:
        _paperAnalytics[event.paperId] = PaperAnalytics(
          paperId: analytics.paperId,
          totalViews: analytics.totalViews + 1,
          totalDownloads: analytics.totalDownloads,
          uniqueViewers: analytics.uniqueViewers +
              (analytics.dailyViews.containsKey(todayKey) ? 0 : 1),
          averageRating: analytics.averageRating,
          totalRatings: analytics.totalRatings,
          totalComments: analytics.totalComments,
          totalBookmarks: analytics.totalBookmarks,
          viewsByCountry: _updateCountryViews(analytics.viewsByCountry, event),
          viewsByReferrer:
              _updateReferrerViews(analytics.viewsByReferrer, event),
          dailyViews: _updateDailyViews(analytics.dailyViews, todayKey),
          topKeywords: analytics.topKeywords,
          lastUpdated: DateTime.now(),
        );
        break;
      case AnalyticsEventType.download:
        _paperAnalytics[event.paperId] = PaperAnalytics(
          paperId: analytics.paperId,
          totalViews: analytics.totalViews,
          totalDownloads: analytics.totalDownloads + 1,
          uniqueViewers: analytics.uniqueViewers,
          averageRating: analytics.averageRating,
          totalRatings: analytics.totalRatings,
          totalComments: analytics.totalComments,
          totalBookmarks: analytics.totalBookmarks,
          viewsByCountry: analytics.viewsByCountry,
          viewsByReferrer: analytics.viewsByReferrer,
          dailyViews: analytics.dailyViews,
          topKeywords: analytics.topKeywords,
          lastUpdated: DateTime.now(),
        );
        break;
      default:
        break;
    }
  }

  Future<void> _updateUserAnalytics(AnalyticsEvent event) async {
    _userAnalytics[event.userId] = _userAnalytics[event.userId] ??
        UserAnalytics(userId: event.userId, lastActivity: DateTime.now());

    final analytics = _userAnalytics[event.userId]!;

    _userAnalytics[event.userId] = UserAnalytics(
      userId: analytics.userId,
      totalViews: analytics.totalViews +
          (event.eventType == AnalyticsEventType.view ? 1 : 0),
      totalDownloads: analytics.totalDownloads +
          (event.eventType == AnalyticsEventType.download ? 1 : 0),
      totalSearches: analytics.totalSearches +
          (event.eventType == AnalyticsEventType.search ? 1 : 0),
      lastActivity: DateTime.now(),
      viewedPapers: {
        ...analytics.viewedPapers,
        if (event.eventType == AnalyticsEventType.view) event.paperId
      },
    );
  }

  Map<String, int> _updateCountryViews(
      Map<String, int> current, AnalyticsEvent event) {
    final country = event.metadata['country'] as String? ?? 'unknown';
    return {...current, country: (current[country] ?? 0) + 1};
  }

  Map<String, int> _updateReferrerViews(
      Map<String, int> current, AnalyticsEvent event) {
    final referrer = event.metadata['referrer'] as String? ?? 'direct';
    return {...current, referrer: (current[referrer] ?? 0) + 1};
  }

  Map<DateTime, int> _updateDailyViews(
      Map<DateTime, int> current, DateTime date) {
    return {...current, date: (current[date] ?? 0) + 1};
  }

  List<AnalyticsEvent> _getAllEvents() {
    final allEvents = <AnalyticsEvent>[];
    for (final eventList in _events.values) {
      allEvents.addAll(eventList);
    }
    return allEvents;
  }

  int _getTotalViews(List<AnalyticsEvent> events) {
    return events.where((e) => e.eventType == AnalyticsEventType.view).length;
  }

  int _getTotalDownloads(List<AnalyticsEvent> events) {
    return events
        .where((e) => e.eventType == AnalyticsEventType.download)
        .length;
  }

  Set<String> _getUniqueUsers(List<AnalyticsEvent> events) {
    return events.map((e) => e.userId).toSet();
  }

  List<TopPaper> _getTopPapers({int limit = 10}) {
    final paperScores = <String, double>{};

    for (final analytics in _paperAnalytics.values) {
      final score = analytics.totalViews * 1.0 +
          analytics.totalDownloads * 3.0 +
          analytics.totalRatings * 2.0;
      paperScores[analytics.paperId] = score;
    }

    final topPapers = <TopPaper>[];
    final sortedEntries = paperScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedEntries.take(limit)) {
      final paper = _findPaperById(entry.key);
      final analytics = _paperAnalytics[entry.key];

      if (paper != null && analytics != null) {
        topPapers.add(TopPaper(
          paper: paper,
          views: analytics.totalViews,
          downloads: analytics.totalDownloads,
          rating: analytics.averageRating,
          score: entry.value,
        ));
      }
    }

    return topPapers;
  }

  List<String> _getTrendingTopics({int days = 30}) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final topicCounts = <String, int>{};

    final recentEvents = _getAllEvents()
        .where((event) => event.timestamp.isAfter(startDate))
        .toList();

    for (final event in recentEvents) {
      if (event.eventType == AnalyticsEventType.view ||
          event.eventType == AnalyticsEventType.download) {
        final paper = _findPaperById(event.paperId);
        if (paper != null) {
          for (final keyword in paper.keywords) {
            topicCounts[keyword] = (topicCounts[keyword] ?? 0) + 1;
          }
        }
      }
    }

    final sortedTopics = topicCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTopics.take(10).map((e) => e.key).toList();
  }

  UserEngagementMetrics _getUserEngagementMetrics(List<AnalyticsEvent> events) {
    final userSessions = <String, List<DateTime>>{};

    for (final event in events) {
      userSessions[event.userId] = userSessions[event.userId] ?? [];
      userSessions[event.userId]!.add(event.timestamp);
    }

    final sessionDurations = <Duration>[];
    for (final sessions in userSessions.values) {
      if (sessions.length > 1) {
        sessions.sort();
        sessionDurations.add(sessions.last.difference(sessions.first));
      }
    }

    final avgSessionDuration = sessionDurations.isNotEmpty
        ? sessionDurations.map((d) => d.inSeconds).reduce((a, b) => a + b) /
            sessionDurations.length
        : 0.0;

    return UserEngagementMetrics(
      averageSessionDuration: Duration(seconds: avgSessionDuration.round()),
      bounceRate: _calculateBounceRate(userSessions),
      returnUserRate: _calculateReturnUserRate(userSessions),
      engagementScore: _calculateEngagementScore(events),
    );
  }

  Map<String, int> _getGeographicData(List<AnalyticsEvent> events) {
    final geographic = <String, int>{};

    for (final event in events) {
      final country = event.metadata['country'] as String? ?? 'Unknown';
      geographic[country] = (geographic[country] ?? 0) + 1;
    }

    return geographic;
  }

  Map<DateTime, int> _getTimeSeriesData(List<AnalyticsEvent> events,
      {int days = 30}) {
    final timeSeries = <DateTime, int>{};
    final endDate = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = DateTime(endDate.year, endDate.month, endDate.day)
          .subtract(Duration(days: i));
      timeSeries[date] = 0;
    }

    for (final event in events) {
      final date = DateTime(
          event.timestamp.year, event.timestamp.month, event.timestamp.day);
      if (timeSeries.containsKey(date)) {
        timeSeries[date] = timeSeries[date]! + 1;
      }
    }

    return timeSeries;
  }

  SearchInsights _getSearchInsights(List<AnalyticsEvent> events) {
    final searchEvents =
        events.where((e) => e.eventType == AnalyticsEventType.search).toList();
    final queries = <String>[];

    for (final event in searchEvents) {
      final query = event.metadata['query'] as String?;
      if (query != null) queries.add(query);
    }

    return SearchInsights(
      totalSearches: searchEvents.length,
      topQueries: _getTopSearchQueries(queries),
      searchTrends: [],
    );
  }

  List<String> _getTopSearchQueries(List<String> queries) {
    final queryCounts = <String, int>{};

    for (final query in queries) {
      queryCounts[query] = (queryCounts[query] ?? 0) + 1;
    }

    final sortedQueries = queryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedQueries.take(10).map((e) => e.key).toList();
  }

  ResearchPaper? _findPaperById(String id) {
    final allPapers = <ResearchPaper>[];
    facultyResearchPapers.forEach((_, papers) => allPapers.addAll(papers));

    if (allPapers.isEmpty) return null;

    try {
      return allPapers.firstWhere(
        (paper) => paper.id == id,
      );
    } catch (e) {
      try {
        return allPapers.firstWhere(
          (paper) => paper.title.hashCode.toString() == id,
        );
      } catch (e) {
        return null;
      }
    }
  }

  List<ResearchPaper> _getAuthorPapers(String authorId) {
    final allPapers = <ResearchPaper>[];
    facultyResearchPapers.forEach((_, papers) => allPapers.addAll(papers));
    return allPapers.where((paper) => paper.author.contains(authorId)).toList();
  }

  double _calculateHIndex(List<ResearchPaper> papers) {
    final citations = papers.map((p) => p.citations).toList()
      ..sort((a, b) => b.compareTo(a));

    int hIndex = 0;
    for (int i = 0; i < citations.length; i++) {
      if (citations[i] >= i + 1) {
        hIndex = i + 1;
      } else {
        break;
      }
    }

    return hIndex.toDouble();
  }

  List<CitationTrendPoint> _generateMockCitationTrend(ResearchPaper paper) {
    // Mock data - in real app, fetch from citation APIs
    final trend = <CitationTrendPoint>[];
    final startYear = int.tryParse(paper.year) ?? DateTime.now().year;

    for (int i = 0; i < 5; i++) {
      trend.add(CitationTrendPoint(
        year: startYear + i,
        citations: (paper.citations * math.pow(1.2, i)).round(),
      ));
    }

    return trend;
  }

  List<ResearchPaper> _findCitingPapers(String paperId) {
    // Mock implementation - in real app, use citation database
    return [];
  }

  List<PublicationTrendPoint> _getPublicationTrend(List<ResearchPaper> papers) {
    final yearCounts = <int, int>{};

    for (final paper in papers) {
      final year = int.tryParse(paper.year) ?? DateTime.now().year;
      yearCounts[year] = (yearCounts[year] ?? 0) + 1;
    }

    return yearCounts.entries
        .map((e) => PublicationTrendPoint(year: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));
  }

  List<String> _getCollaborationNetwork(String authorId) {
    // Mock implementation - in real app, analyze co-authorships
    return [];
  }

  List<String> _getAuthorTopKeywords(List<ResearchPaper> papers) {
    final keywordCounts = <String, int>{};

    for (final paper in papers) {
      for (final keyword in paper.keywords) {
        keywordCounts[keyword] = (keywordCounts[keyword] ?? 0) + 1;
      }
    }

    final sortedKeywords = keywordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedKeywords.take(10).map((e) => e.key).toList();
  }

  List<QueryCount> _getTopQueries(Map<String, int> queries) {
    final sortedQueries = queries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedQueries
        .take(10)
        .map((e) => QueryCount(query: e.key, count: e.value))
        .toList();
  }

  double _calculateAverageResults(List<AnalyticsEvent> searchEvents) {
    if (searchEvents.isEmpty) return 0.0;

    final totalResults = searchEvents
        .map((e) => e.metadata['resultCount'] as int? ?? 0)
        .fold(0, (a, b) => a + b);

    return totalResults / searchEvents.length;
  }

  List<SearchTrendPoint> _getSearchTrends(List<AnalyticsEvent> searchEvents) {
    final dailySearches = <DateTime, int>{};

    for (final event in searchEvents) {
      final date = DateTime(
          event.timestamp.year, event.timestamp.month, event.timestamp.day);
      dailySearches[date] = (dailySearches[date] ?? 0) + 1;
    }

    return dailySearches.entries
        .map((e) => SearchTrendPoint(date: e.key, searches: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  double _calculateBounceRate(Map<String, List<DateTime>> userSessions) {
    if (userSessions.isEmpty) return 0.0;

    final singleSessionUsers =
        userSessions.values.where((sessions) => sessions.length == 1).length;

    return singleSessionUsers / userSessions.length;
  }

  double _calculateReturnUserRate(Map<String, List<DateTime>> userSessions) {
    if (userSessions.isEmpty) return 0.0;

    final returnUsers =
        userSessions.values.where((sessions) => sessions.length > 1).length;

    return returnUsers / userSessions.length;
  }

  double _calculateEngagementScore(List<AnalyticsEvent> events) {
    // Simple engagement score based on different event types
    double score = 0.0;

    for (final event in events) {
      switch (event.eventType) {
        case AnalyticsEventType.view:
          score += 1.0;
          break;
        case AnalyticsEventType.download:
          score += 3.0;
          break;
        case AnalyticsEventType.bookmark:
          score += 2.0;
          break;
        case AnalyticsEventType.search:
          score += 0.5;
          break;
        default:
          score += 0.1;
      }
    }

    return events.isNotEmpty ? score / events.length : 0.0;
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load paper analytics
      final paperAnalyticsJson = prefs.getString('paper_analytics');
      if (paperAnalyticsJson != null) {
        final Map<String, dynamic> data = json.decode(paperAnalyticsJson);
        _paperAnalytics.clear();
        data.forEach((key, value) {
          _paperAnalytics[key] = PaperAnalytics.fromJson(value);
        });
      }

      // Load events
      final eventsJson = prefs.getString('analytics_events');
      if (eventsJson != null) {
        final Map<String, dynamic> data = json.decode(eventsJson);
        _events.clear();
        data.forEach((key, value) {
          _events[key] =
              (value as List).map((e) => AnalyticsEvent.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveAnalyticsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save paper analytics
      final paperAnalyticsData =
          _paperAnalytics.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString('paper_analytics', json.encode(paperAnalyticsData));

      // Save events (keep only recent events to prevent storage bloat)
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      final filteredEvents = <String, List<AnalyticsEvent>>{};

      _events.forEach((key, value) {
        final recentEvents =
            value.where((e) => e.timestamp.isAfter(cutoffDate)).toList();
        if (recentEvents.isNotEmpty) {
          filteredEvents[key] = recentEvents;
        }
      });

      final eventsData = filteredEvents.map(
          (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()));
      await prefs.setString('analytics_events', json.encode(eventsData));
    } catch (e) {
      // Handle error silently
    }
  }
}

// Analytics data models
class AnalyticsEvent {
  final String id;
  final String paperId;
  final String userId;
  final AnalyticsEventType eventType;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  AnalyticsEvent({
    required this.id,
    required this.paperId,
    required this.userId,
    required this.eventType,
    required this.timestamp,
    this.metadata = const {},
  });

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
        id: json['id'],
        paperId: json['paperId'],
        userId: json['userId'],
        eventType: AnalyticsEventType.values
            .firstWhere((e) => e.toString() == json['eventType']),
        timestamp: DateTime.parse(json['timestamp']),
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'paperId': paperId,
        'userId': userId,
        'eventType': eventType.toString(),
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };
}

enum AnalyticsEventType {
  view,
  download,
  bookmark,
  search,
  rating,
  comment,
  share,
}

class AnalyticsDashboard {
  final int totalViews;
  final int totalDownloads;
  final int totalUsers;
  final int totalPapers;
  final List<TopPaper> topPapers;
  final List<String> trendingTopics;
  final UserEngagementMetrics userEngagement;
  final Map<String, int> geographicData;
  final Map<DateTime, int> timeSeriesData;
  final SearchInsights searchInsights;

  AnalyticsDashboard({
    required this.totalViews,
    required this.totalDownloads,
    required this.totalUsers,
    required this.totalPapers,
    required this.topPapers,
    required this.trendingTopics,
    required this.userEngagement,
    required this.geographicData,
    required this.timeSeriesData,
    required this.searchInsights,
  });
}

class TopPaper {
  final ResearchPaper paper;
  final int views;
  final int downloads;
  final double rating;
  final double score;

  TopPaper({
    required this.paper,
    required this.views,
    required this.downloads,
    required this.rating,
    required this.score,
  });
}

class TrendingPaper {
  final ResearchPaper paper;
  final int viewCount;
  final int downloadCount;
  final double trendScore;

  TrendingPaper({
    required this.paper,
    required this.viewCount,
    required this.downloadCount,
    required this.trendScore,
  });
}

class UserEngagementMetrics {
  final Duration averageSessionDuration;
  final double bounceRate;
  final double returnUserRate;
  final double engagementScore;

  UserEngagementMetrics({
    required this.averageSessionDuration,
    required this.bounceRate,
    required this.returnUserRate,
    required this.engagementScore,
  });
}

class SearchInsights {
  final int totalSearches;
  final List<String> topQueries;
  final List<SearchTrendPoint> searchTrends;

  SearchInsights({
    required this.totalSearches,
    required this.topQueries,
    required this.searchTrends,
  });
}

class SearchTrendPoint {
  final DateTime date;
  final int searches;

  SearchTrendPoint({
    required this.date,
    required this.searches,
  });
}

class UserAnalytics {
  final String userId;
  final int totalViews;
  final int totalDownloads;
  final int totalSearches;
  final DateTime lastActivity;
  final Set<String> viewedPapers;

  UserAnalytics({
    required this.userId,
    this.totalViews = 0,
    this.totalDownloads = 0,
    this.totalSearches = 0,
    required this.lastActivity,
    this.viewedPapers = const {},
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'totalViews': totalViews,
        'totalDownloads': totalDownloads,
        'totalSearches': totalSearches,
        'lastActivity': lastActivity.toIso8601String(),
        'viewedPapers': viewedPapers.toList(),
      };

  factory UserAnalytics.fromJson(Map<String, dynamic> json) => UserAnalytics(
        userId: json['userId'],
        totalViews: json['totalViews'] ?? 0,
        totalDownloads: json['totalDownloads'] ?? 0,
        totalSearches: json['totalSearches'] ?? 0,
        lastActivity: DateTime.parse(json['lastActivity']),
        viewedPapers: Set<String>.from(json['viewedPapers'] ?? []),
      );
}

class CitationAnalytics {
  final String paperId;
  final int totalCitations;
  final double hIndex;
  final List<CitationTrendPoint> citationTrend;
  final List<ResearchPaper> citingPapers;

  CitationAnalytics({
    required this.paperId,
    required this.totalCitations,
    required this.hIndex,
    required this.citationTrend,
    required this.citingPapers,
  });
}

class CitationTrendPoint {
  final int year;
  final int citations;

  CitationTrendPoint({
    required this.year,
    required this.citations,
  });
}

class ResearchPerformance {
  final String authorId;
  final int totalPapers;
  final int totalCitations;
  final double hIndex;
  final double averageCitations;
  final List<PublicationTrendPoint> publicationTrend;
  final List<String> collaborationNetwork;
  final List<String> topKeywords;

  ResearchPerformance({
    required this.authorId,
    required this.totalPapers,
    required this.totalCitations,
    required this.hIndex,
    required this.averageCitations,
    required this.publicationTrend,
    required this.collaborationNetwork,
    required this.topKeywords,
  });
}

class PublicationTrendPoint {
  final int year;
  final int count;

  PublicationTrendPoint({
    required this.year,
    required this.count,
  });
}

class SearchAnalytics {
  final int totalSearches;
  final int uniqueQueries;
  final List<QueryCount> topQueries;
  final List<String> zeroResultQueries;
  final double averageResultsPerQuery;
  final List<SearchTrendPoint> searchTrends;

  SearchAnalytics({
    required this.totalSearches,
    required this.uniqueQueries,
    required this.topQueries,
    required this.zeroResultQueries,
    required this.averageResultsPerQuery,
    required this.searchTrends,
  });
}

class QueryCount {
  final String query;
  final int count;

  QueryCount({
    required this.query,
    required this.count,
  });
}
