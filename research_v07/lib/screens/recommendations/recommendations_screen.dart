import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/recommendation_providers.dart';
import '../../services/auth_service.dart';
import '../../services/recommendation_service.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Recommendations')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Recommendations')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (currentUser) {
        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Recommendations')),
            body: const Center(
              child: Text('Please sign in to see recommendations'),
            ),
          );
        }

        return _buildMainContent(currentUser.id);
      },
    );
  }

  Widget _buildMainContent(String userId) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.star), text: 'For You'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trending'),
            Tab(icon: Icon(Icons.new_releases), text: 'Popular'),
            Tab(icon: Icon(Icons.bookmark), text: 'Bookmarked'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPersonalizedTab(userId),
          _buildTrendingTab(userId),
          _buildHybridTab(userId),
          _buildBookmarkedTab(userId),
        ],
      ),
    );
  }

  Widget _buildPersonalizedTab(String userId) {
    final recommendations = ref.watch(
      personalizedRecommendationsProvider((userId: userId, limit: 20)),
    );

    return recommendations.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(
                  personalizedRecommendationsProvider(
                      (userId: userId, limit: 20)),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.recommend, size: 64),
                const SizedBox(height: 16),
                const Text('No recommendations yet'),
                const SizedBox(height: 8),
                Text(
                  'Start viewing papers to get personalized recommendations',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return _buildPaperListItem(result);
          },
        );
      },
    );
  }

  Widget _buildTrendingTab(String userId) {
    final trending = ref.watch(trendingRecommendationsProvider(20));

    return trending.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 64),
                SizedBox(height: 16),
                Text('No trending papers yet'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return _buildPaperListItem(result);
          },
        );
      },
    );
  }

  Widget _buildHybridTab(String userId) {
    final hybrid = ref.watch(
      hybridRecommendationsProvider((userId: userId, limit: 20)),
    );

    return hybrid.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
      data: (results) {
        if (results.isEmpty) {
          return const Center(child: Text('No recommendations available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return _buildPaperListItem(result);
          },
        );
      },
    );
  }

  Widget _buildBookmarkedTab(String userId) {
    final bookmarked = ref.watch(bookmarkedPapersProvider(userId));

    return bookmarked.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64),
                SizedBox(height: 16),
                Text('No bookmarked papers yet'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return _buildPaperListItem(result);
          },
        );
      },
    );
  }

  Widget _buildPaperListItem(RecommendationResult result) {
    final theme = Theme.of(context);
    final paper = result.paper;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to paper detail screen
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                paper.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Authors
              Text(
                paper.author,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Metadata
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(paper.year, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                  if (paper.citations > 0) ...[
                    Icon(Icons.format_quote,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${paper.citations}',
                        style: theme.textTheme.bodySmall),
                  ],
                ],
              ),

              if (result.reasoning.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _getTypeIcon(result.recommendationType),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.reasoning,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTypeIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.personalized:
        return const Icon(Icons.star, size: 16, color: Colors.amber);
      case RecommendationType.trending:
        return const Icon(Icons.trending_up, size: 16, color: Colors.orange);
      case RecommendationType.popular:
        return const Icon(Icons.thumb_up, size: 16, color: Colors.blue);
      case RecommendationType.recent:
        return const Icon(Icons.new_releases, size: 16, color: Colors.green);
      case RecommendationType.similar:
        return const Icon(Icons.compare_arrows, size: 16, color: Colors.purple);
      case RecommendationType.category:
        return const Icon(Icons.category, size: 16, color: Colors.teal);
      case RecommendationType.bookmarked:
        return const Icon(Icons.bookmark, size: 16, color: Colors.red);
    }
  }
}
