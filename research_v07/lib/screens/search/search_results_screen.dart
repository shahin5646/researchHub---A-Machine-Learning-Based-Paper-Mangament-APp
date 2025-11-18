import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/firebase_paper.dart';
import '../../models/user_profile.dart';
import '../../providers/search_providers.dart';
import '../social/user_profile_screen.dart';

enum SearchResultType { papers, users }

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;
  final SearchResultType type;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.type = SearchResultType.papers,
  });

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  SearchResultType _currentType = SearchResultType.papers;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _currentType = widget.type;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "${widget.query}"'),
        actions: [
          // View Toggle (only for papers)
          if (_currentType == SearchResultType.papers)
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
              tooltip: _isGridView ? 'List View' : 'Grid View',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildTypeToggle(theme),
        ),
      ),
      body: _buildResults(),
    );
  }

  Widget _buildTypeToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<SearchResultType>(
              segments: const [
                ButtonSegment(
                  value: SearchResultType.papers,
                  label: Text('Papers'),
                  icon: Icon(Icons.description),
                ),
                ButtonSegment(
                  value: SearchResultType.users,
                  label: Text('Users'),
                  icon: Icon(Icons.people),
                ),
              ],
              selected: {_currentType},
              onSelectionChanged: (Set<SearchResultType> newSelection) {
                setState(() {
                  _currentType = newSelection.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_currentType == SearchResultType.papers) {
      return _buildPaperResults();
    } else {
      return _buildUserResults();
    }
  }

  Widget _buildPaperResults() {
    final searchResults = ref.watch(currentSearchResultsProvider);

    return searchResults.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (papers) {
        if (papers.isEmpty) {
          return _buildEmptyState(
              'No papers found', Icons.description_outlined);
        }

        return _isGridView
            ? _buildPapersGrid(papers)
            : _buildPapersList(papers);
      },
    );
  }

  Widget _buildUserResults() {
    final params = {'query': widget.query};
    final userResults = ref.watch(userSearchResultsProvider(params));

    return userResults.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (users) {
        if (users.isEmpty) {
          return _buildEmptyState('No users found', Icons.person_outline);
        }

        return _buildUsersList(users);
      },
    );
  }

  Widget _buildPapersList(List<FirebasePaper> papers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: papers.length,
      itemBuilder: (context, index) {
        return _buildPaperListCard(papers[index]);
      },
    );
  }

  Widget _buildPapersGrid(List<FirebasePaper> papers) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: papers.length,
      itemBuilder: (context, index) {
        return _buildPaperGridCard(papers[index]);
      },
    );
  }

  Widget _buildPaperListCard(FirebasePaper paper) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToPaper(paper),
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
                paper.authors.join(', '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Date and Category
              Row(
                children: [
                  Text(
                    dateFormat.format(paper.uploadedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (paper.category.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        paper.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Description
              if (paper.description != null &&
                  paper.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  paper.description!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  _buildStat(Icons.visibility, paper.views, theme),
                  const SizedBox(width: 16),
                  _buildStat(Icons.thumb_up, paper.likesCount, theme),
                  const SizedBox(width: 16),
                  _buildStat(Icons.comment, paper.commentsCount, theme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaperGridCard(FirebasePaper paper) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => _navigateToPaper(paper),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Expanded(
                child: Text(
                  paper.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Category
              if (paper.category.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    paper.category,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(Icons.visibility, paper.views, theme),
                  _buildStat(Icons.thumb_up, paper.likesCount, theme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList(List<UserProfile> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return _buildUserCard(users[index]);
      },
    );
  }

  Widget _buildUserCard(UserProfile user) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToUser(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
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

              // User Info
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
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.bio!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (user.institution != null &&
                            user.institution!.isNotEmpty) ...[
                          Icon(
                            Icons.school,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              user.institution!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (user.department != null &&
                            user.department!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.work,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              user.department!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${user.followersCount}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'followers',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildStat(IconData icon, int count, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
        ],
      ),
    );
  }

  void _navigateToPaper(FirebasePaper paper) {
    // TODO: Convert FirebasePaper to ResearchPaper or update PaperDetailScreen
    // For now, we'll navigate to a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening paper: ${paper.title}')),
    );
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => PaperDetailScreen(paper: paper),
    //   ),
    // );
  }

  void _navigateToUser(UserProfile user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: user.id),
      ),
    );
  }
}
