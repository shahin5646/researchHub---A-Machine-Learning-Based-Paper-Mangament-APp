import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/social_providers.dart';
import 'user_profile_screen.dart';

class FollowingScreen extends ConsumerStatefulWidget {
  final String userId;

  const FollowingScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends ConsumerState<FollowingScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followingAsync = ref.watch(followingProvider(widget.userId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search following...',
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
      body: followingAsync.when(
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
                'Error loading following',
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
        data: (following) {
          if (following.isEmpty) {
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
                    'Not following anyone yet',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover researchers to follow',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter following based on search query
          final filteredFollowing = _searchQuery.isEmpty
              ? following
              : following.where((user) {
                  final displayName = user.displayName.toLowerCase();
                  final email = user.email.toLowerCase();
                  final institution = user.institution?.toLowerCase() ?? '';
                  final query = _searchQuery;

                  return displayName.contains(query) ||
                      email.contains(query) ||
                      institution.contains(query);
                }).toList();

          if (filteredFollowing.isEmpty) {
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
                    'No users found',
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
              ref.invalidate(followingProvider(widget.userId));
            },
            child: ListView.builder(
              itemCount: filteredFollowing.length,
              itemBuilder: (context, index) {
                final user = filteredFollowing[index];
                return _buildUserCard(
                  context,
                  user,
                  currentUserId,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    UserProfile user,
    String? currentUserId,
  ) {
    final theme = Theme.of(context);
    final isCurrentUser = user.id == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToProfile(context, user.id, isCurrentUser),
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
                      const SizedBox(height: 4),
                      Text(
                        user.researchInterests.take(2).join(', '),
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

              // Unfollow Button
              if (!isCurrentUser && currentUserId != null)
                _buildUnfollowButton(context, currentUserId, user.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnfollowButton(
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
            Icons.person_remove,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: isFollowing
              ? () {
                  ref
                      .read(
                        followNotifierProvider(
                          (
                            currentUserId: currentUserId,
                            targetUserId: targetUserId
                          ),
                        ).notifier,
                      )
                      .toggleFollow();
                }
              : null,
          tooltip: 'Unfollow',
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
