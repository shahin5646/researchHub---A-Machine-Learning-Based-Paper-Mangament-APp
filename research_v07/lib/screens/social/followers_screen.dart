import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/social_providers.dart';
import 'user_profile_screen.dart';

class FollowersScreen extends ConsumerStatefulWidget {
  final String userId;

  const FollowersScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends ConsumerState<FollowersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followersAsync = ref.watch(followersProvider(widget.userId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search followers...',
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
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: followersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
                'Error loading followers',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (followers) {
          if (followers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No followers yet',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          // Filter followers based on search query
          final filteredFollowers = _searchQuery.isEmpty
              ? followers
              : followers.where((follower) {
                  final displayName = follower.displayName.toLowerCase();
                  final email = follower.email.toLowerCase();
                  final institution = follower.institution?.toLowerCase() ?? '';
                  final query = _searchQuery;

                  return displayName.contains(query) ||
                      email.contains(query) ||
                      institution.contains(query);
                }).toList();

          if (filteredFollowers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No followers found',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(followersProvider(widget.userId));
            },
            child: ListView.builder(
              itemCount: filteredFollowers.length,
              itemBuilder: (context, index) {
                final follower = filteredFollowers[index];
                return _buildFollowerCard(
                  context,
                  follower,
                  currentUserId,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFollowerCard(
    BuildContext context,
    UserProfile follower,
    String? currentUserId,
  ) {
    final theme = Theme.of(context);
    final isCurrentUser = follower.id == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToProfile(context, follower.id, isCurrentUser),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Picture
              Hero(
                tag: 'profile_${follower.id}',
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: follower.photoURL != null
                      ? NetworkImage(follower.photoURL!)
                      : null,
                  child: follower.photoURL == null
                      ? Text(
                          follower.displayName[0].toUpperCase(),
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
                            follower.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (follower.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    if (follower.position != null ||
                        follower.institution != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (follower.position != null) follower.position,
                          if (follower.institution != null)
                            follower.institution,
                        ].join(' at '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (follower.researchInterests.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        follower.researchInterests.take(2).join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Follow Button
              if (!isCurrentUser && currentUserId != null)
                _buildFollowButton(context, currentUserId, follower.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(
    BuildContext context,
    String currentUserId,
    String targetUserId,
  ) {
    final followState = ref.watch(
      followNotifierProvider(
        (currentUserId: currentUserId, targetUserId: targetUserId),
      ),
    );

    return followState.when(
      loading: () => const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => const Icon(Icons.error_outline),
      data: (isFollowing) {
        return IconButton(
          icon: Icon(
            isFollowing ? Icons.person_remove : Icons.person_add,
            color: isFollowing
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            ref
                .read(
                  followNotifierProvider(
                    (currentUserId: currentUserId, targetUserId: targetUserId),
                  ).notifier,
                )
                .toggleFollow();
          },
          tooltip: isFollowing ? 'Unfollow' : 'Follow',
        );
      },
    );
  }

  void _navigateToProfile(
      BuildContext context, String userId, bool isCurrentUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: userId,
          isCurrentUser: isCurrentUser,
        ),
      ),
    );
  }
}
