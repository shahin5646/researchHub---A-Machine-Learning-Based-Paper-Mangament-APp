import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/social_providers.dart';
import '../../services/messaging_service.dart';
import 'user_profile_screen.dart';
import '../profile/public_user_profile_screen.dart';
import '../messaging/chat_screen.dart';

class DiscoverUsersScreen extends ConsumerStatefulWidget {
  const DiscoverUsersScreen({super.key});

  @override
  ConsumerState<DiscoverUsersScreen> createState() =>
      _DiscoverUsersScreenState();
}

class _DiscoverUsersScreenState extends ConsumerState<DiscoverUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Researchers'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recommended'),
            Tab(text: 'Popular'),
            Tab(text: 'Search'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecommendedTab(),
          _buildPopularTab(),
          _buildSearchTab(),
        ],
      ),
    );
  }

  Widget _buildRecommendedTab() {
    final recommendedAsync = ref.watch(recommendedUsersProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return recommendedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (users) {
        if (users.isEmpty) {
          return _buildEmptyState(
            icon: Icons.explore,
            title: 'No recommendations yet',
            subtitle: 'Add research interests to your profile',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recommendedUsersProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _buildUserCard(users[index], currentUserId);
            },
          ),
        );
      },
    );
  }

  Widget _buildPopularTab() {
    final popularAsync = ref.watch(popularAuthorsProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return popularAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (authors) {
        if (authors.isEmpty) {
          return _buildEmptyState(
            icon: Icons.trending_up,
            title: 'No popular authors yet',
            subtitle: 'Check back later',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(popularAuthorsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: authors.length,
            itemBuilder: (context, index) {
              final author = authors[index];
              return _buildPopularAuthorCard(author, currentUserId);
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    final currentUserId = ref.watch(currentUserIdProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, institution...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: _searchQuery.isEmpty
              ? _buildEmptyState(
                  icon: Icons.search,
                  title: 'Search for researchers',
                  subtitle: 'Enter a name or institution',
                )
              : _buildSearchResults(currentUserId),
        ),
      ],
    );
  }

  Widget _buildSearchResults(String? currentUserId) {
    final searchAsync = ref.watch(userSearchProvider(_searchQuery));

    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (users) {
        if (users.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title: 'No users found',
            subtitle: 'Try a different search term',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index], currentUserId);
          },
        );
      },
    );
  }

  Widget _buildUserCard(UserProfile user, String? currentUserId) {
    final theme = Theme.of(context);
    final isCurrentUser = user.id == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToProfile(user.id, isCurrentUser),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Picture
              Hero(
                tag: 'profile_${user.id}',
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(
                          user.displayName[0].toUpperCase(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.username != null && user.username!.isNotEmpty
                          ? '@${user.username}'
                          : user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.position != null || user.institution != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (user.position != null) user.position,
                          if (user.institution != null) user.institution,
                        ].join(' at '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (user.researchInterests.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children:
                            user.researchInterests.take(3).map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              interest,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.article,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.papersCount} papers',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.people,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.followersCount} followers',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              if (!isCurrentUser && currentUserId != null)
                Column(
                  children: [
                    _buildFollowButton(currentUserId, user.id),
                    const SizedBox(height: 8),
                    _buildMessageButton(currentUserId, user),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularAuthorCard(
    Map<String, dynamic> author,
    String? currentUserId,
  ) {
    final theme = Theme.of(context);
    final authorId = author['id'] as String;
    final displayName = author['displayName'] as String;
    final photoURL = author['photoURL'] as String?;
    final papersCount = author['papersCount'] as int;
    final followersCount = author['followersCount'] as int;
    final institution = author['institution'] as String?;
    final isCurrentUser = authorId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToProfile(authorId, isCurrentUser),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Picture
              Hero(
                tag: 'profile_$authorId',
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage:
                      photoURL != null ? NetworkImage(photoURL) : null,
                  child: photoURL == null
                      ? Text(
                          displayName[0].toUpperCase(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (institution != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        institution,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.article,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$papersCount papers',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.people,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$followersCount followers',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Follow Button
              if (!isCurrentUser && currentUserId != null)
                _buildFollowButton(currentUserId, authorId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(String currentUserId, String targetUserId) {
    final followState = ref.watch(
      followNotifierProvider(
        (currentUserId: currentUserId, targetUserId: targetUserId),
      ),
    );

    return followState.when(
      loading: () => const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stack) => const Icon(Icons.error_outline),
      data: (isFollowing) {
        return ElevatedButton(
          onPressed: () {
            ref
                .read(
                  followNotifierProvider(
                    (currentUserId: currentUserId, targetUserId: targetUserId),
                  ).notifier,
                )
                .toggleFollow();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.primary,
            foregroundColor: isFollowing
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(isFollowing ? 'Following' : 'Follow'),
        );
      },
    );
  }

  Widget _buildMessageButton(String currentUserId, UserProfile user) {
    return OutlinedButton(
      onPressed: () async {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          final messagingService = MessagingService();

          // Get current user info
          final currentUserProfile = await ref.read(
            userProfileProvider(currentUserId).future,
          );

          if (currentUserProfile == null) {
            Navigator.pop(context);
            return;
          }

          final conversationId = await messagingService.getOrCreateConversation(
            currentUserId: currentUserId,
            otherUserId: user.id,
            currentUserName: currentUserProfile.displayName,
            otherUserName: user.displayName,
            currentUserUsername: currentUserProfile.username,
            otherUserUsername: user.username,
            currentUserPhotoUrl: currentUserProfile.photoURL,
            otherUserPhotoUrl: user.photoURL,
          );

          Navigator.pop(context); // Close loading dialog

          // Navigate to chat screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversationId,
                otherUserId: user.id,
                otherUserName: user.displayName,
                otherUserUsername: user.username,
                otherUserPhotoUrl: user.photoURL,
              ),
            ),
          );
        } catch (e) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start conversation: $e')),
          );
        }
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: const Text('Message'),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
            title,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading users',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile(String userId, bool isCurrentUser) {
    if (isCurrentUser) {
      // Navigate to own profile with edit capabilities
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            userId: userId,
            isCurrentUser: true,
          ),
        ),
      );
    } else {
      // Navigate to public profile view for other users
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PublicUserProfileScreen(
            userId: userId,
          ),
        ),
      );
    }
  }
}
