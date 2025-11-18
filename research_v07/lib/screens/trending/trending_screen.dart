import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/trending_providers.dart';
import '../../models/firebase_paper.dart';
import '../../models/user_profile.dart';
import '../social/user_profile_screen.dart';

class TrendingScreen extends ConsumerStatefulWidget {
  const TrendingScreen({super.key});

  @override
  ConsumerState<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends ConsumerState<TrendingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About ML Ranking',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('🤖 ML-Powered Trending'),
                  content: const Text(
                    'Papers are ranked using machine learning algorithms based on:\n\n'
                    '• Views (0.5x weight)\n'
                    '• Clicks (1x weight)\n'
                    '• Likes (3x weight)\n'
                    '• Comments (8x weight) 💬\n'
                    '• Shares (10x weight) 📤\n'
                    '• Downloads (5x weight)\n\n'
                    'Recent papers get a time-decay boost.\n'
                    'Auto-updates every 30 minutes.',
                    style: TextStyle(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalculate Trending',
            onPressed: () async {
              final service = ref.read(trendingServiceProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 Recalculating trending papers with ML...'),
                  duration: Duration(seconds: 2),
                ),
              );
              await service.calculateTrendingPapers();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Trending papers updated!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'Papers'),
            Tab(icon: Icon(Icons.people), text: 'Researchers'),
            Tab(icon: Icon(Icons.topic), text: 'Topics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrendingPapers(),
          _buildTrendingFaculty(),
          _buildHotTopics(),
        ],
      ),
    );
  }

  Widget _buildTrendingPapers() {
    final trendingPapers = ref.watch(trendingPapersStreamProvider(20));

    return trendingPapers.when(
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
                ref.invalidate(trendingPapersStreamProvider(20));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (papers) {
        if (papers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No trending papers yet'),
                const SizedBox(height: 8),
                const Text(
                  'Papers with most likes, comments & views\nwill appear here using ML ranking',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: papers.length,
          itemBuilder: (context, index) {
            return _buildPaperCard(papers[index], index + 1);
          },
        );
      },
    );
  }

  Widget _buildPaperCard(FirebasePaper paper, int rank) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRankColor(rank),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Paper info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paper.authors.join(', '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.visibility,
                          size: 16, color: Colors.blue.shade400),
                      const SizedBox(width: 4),
                      Text('${paper.views}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(width: 12),
                      Icon(Icons.favorite,
                          size: 16, color: Colors.red.shade400),
                      const SizedBox(width: 4),
                      Text('${paper.likesCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(width: 12),
                      Icon(Icons.comment,
                          size: 16, color: Colors.green.shade400),
                      const SizedBox(width: 4),
                      Text('${paper.commentsCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ],
              ),
            ),

            // Trending icon
            Icon(
              Icons.trending_up,
              color: _getRankColor(rank),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingFaculty() {
    final trendingFaculty = ref.watch(trendingFacultyProvider(20));

    return trendingFaculty.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
      data: (faculty) {
        if (faculty.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No trending researchers yet'),
                const SizedBox(height: 8),
                const Text(
                  'Researchers who post papers with high engagement\nwill appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final service = ref.read(trendingServiceProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔄 Calculating trending researchers...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    await service.calculateTrendingFaculty();
                    ref.invalidate(trendingFacultyProvider(20));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Trending researchers calculated!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Calculate Trending'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: faculty.length,
          itemBuilder: (context, index) {
            return _buildFacultyCard(faculty[index], index + 1);
          },
        );
      },
    );
  }

  Widget _buildFacultyCard(UserProfile user, int rank) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(userId: user.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getRankColor(rank),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    user.photoURL != null && user.photoURL!.isNotEmpty
                        ? NetworkImage(user.photoURL!)
                        : null,
                child: user.photoURL == null || user.photoURL!.isEmpty
                    ? Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.titleLarge,
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user.institution != null &&
                        user.institution!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.institution!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${user.followersCount} followers',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Trending icon
              Icon(
                Icons.trending_up,
                color: _getRankColor(rank),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotTopics() {
    final hotTopics = ref.watch(hotTopicsProvider(20));

    return hotTopics.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
      data: (topics) {
        if (topics.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.topic, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No hot topics yet'),
                const SizedBox(height: 8),
                const Text(
                  'Popular keywords and tags from papers\nwill appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final service = ref.read(trendingServiceProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔄 Calculating hot topics...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    await service.calculateHotTopics();
                    ref.invalidate(hotTopicsProvider(20));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Hot topics calculated!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Calculate Topics'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
            return _buildTopicCard(
              topic['topic'] as String,
              topic['count'] as int,
              index + 1,
            );
          },
        );
      },
    );
  }

  Widget _buildTopicCard(String topic, int count, int rank) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRankColor(rank),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Topic info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count papers',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Fire icon for hot topics
            Icon(
              Icons.local_fire_department,
              color: _getRankColor(rank),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber; // Gold
    if (rank == 2) return Colors.grey.shade400; // Silver
    if (rank == 3) return Colors.brown.shade400; // Bronze
    if (rank <= 10) return Colors.blue;
    return Colors.grey;
  }
}
