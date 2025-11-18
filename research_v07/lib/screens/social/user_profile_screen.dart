import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import '../../providers/social_providers.dart';
import '../../services/messaging_service.dart';
import 'edit_profile_screen.dart';
import 'followers_screen.dart';
import 'following_screen.dart';
import '../saved_papers_screen.dart';
import '../papers/my_papers_screen.dart';
import '../messaging/chat_screen.dart';
import '../profile/public_user_profile_screen.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  final bool isCurrentUser;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading profile: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Profile Picture
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primaryContainer,
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Hero(
                          tag: 'profile_${profile.id}',
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            child: profile.photoURL != null
                                ? ClipOval(
                                    child: Image.network(
                                      profile.photoURL!,
                                      width: 116,
                                      height: 116,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) =>
                                          const Icon(Icons.person, size: 60),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 60),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: isCurrentUser
                    ? [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _navigateToEditProfile(context),
                        ),
                      ]
                    : null,
              ),

              // Profile Content
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildProfileInfo(context, ref, profile, currentUserId),
                    const SizedBox(height: 16),
                    _buildStatsRow(context, profile),
                    const SizedBox(height: 24),
                    if (isCurrentUser) _buildQuickActions(context, profile),
                    if (isCurrentUser) const SizedBox(height: 24),
                    if (!isCurrentUser && currentUserId != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildFollowButton(
                                context, ref, currentUserId, userId),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMessageButton(
                                context, ref, profile, currentUserId),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (profile.bio != null && profile.bio!.isNotEmpty)
                      _buildBioSection(context, profile),
                    if (profile.researchInterests.isNotEmpty)
                      _buildResearchInterestsSection(context, profile),
                    if (_hasSocialLinks(profile))
                      _buildSocialLinksSection(context, profile),
                    const SizedBox(height: 24),
                    _buildPapersSection(context, userId),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileInfo(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    String? currentUserId,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.verified,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ],
            ],
          ),
          if (profile.username != null && profile.username!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@${profile.username}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (profile.institution != null || profile.position != null) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (profile.position != null) profile.position,
                if (profile.institution != null) profile.institution,
              ].join(' at '),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (profile.showEmail && profile.email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              profile.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(context, 'Papers', profile.papersCount.toString()),
          _buildStatItem(
            context,
            'Followers',
            profile.followersCount.toString(),
            onTap: () => _navigateToFollowers(context, profile.id),
          ),
          _buildStatItem(
            context,
            'Following',
            profile.followingCount.toString(),
            onTap: () => _navigateToFollowing(context, profile.id),
          ),
          if (profile.citationsCount > 0)
            _buildStatItem(
              context,
              'Citations',
              profile.citationsCount.toString(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageButton(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    String currentUserId,
  ) {
    final messagingService = MessagingService();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
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
              // Get current user info from provider
              final currentUserProfile = await ref.read(
                userProfileProvider(currentUserId).future,
              );

              if (currentUserProfile == null) {
                Navigator.pop(context);
                return;
              }

              final conversationId =
                  await messagingService.getOrCreateConversation(
                currentUserId: currentUserId,
                otherUserId: profile.id,
                currentUserName: currentUserProfile.displayName,
                otherUserName: profile.displayName,
                currentUserUsername: currentUserProfile.username,
                otherUserUsername: profile.username,
                currentUserPhotoUrl: currentUserProfile.photoURL,
                otherUserPhotoUrl: profile.photoURL,
              );

              Navigator.pop(context); // Close loading dialog

              // Navigate to chat screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    conversationId: conversationId,
                    otherUserId: profile.id,
                    otherUserName: profile.displayName,
                    otherUserUsername: profile.username,
                    otherUserPhotoUrl: profile.photoURL,
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
          icon: const Icon(Icons.message_outlined),
          label: const Text('Message'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
    String targetUserId,
  ) {
    final followState = ref.watch(
      followNotifierProvider(
        (currentUserId: currentUserId, targetUserId: targetUserId),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: followState.when(
          loading: () => const ElevatedButton(
            onPressed: null,
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, stack) => ElevatedButton(
            onPressed: () {},
            child: const Text('Error'),
          ),
          data: (isFollowing) {
            return ElevatedButton.icon(
              onPressed: () {
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
              },
              icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add),
              label: Text(isFollowing ? 'Unfollow' : 'Follow'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Theme.of(context).colorScheme.primary,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBioSection(BuildContext context, UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.bio ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildResearchInterestsSection(
    BuildContext context,
    UserProfile profile,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Research Interests',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.researchInterests.map((interest) {
              return Chip(
                label: Text(interest),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinksSection(BuildContext context, UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Links',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (profile.linkedinUrl != null)
                _buildSocialChip(context, 'LinkedIn', Icons.business),
              if (profile.googleScholarUrl != null)
                _buildSocialChip(context, 'Google Scholar', Icons.school),
              if (profile.orcidId != null)
                _buildSocialChip(context, 'ORCID', Icons.badge),
              if (profile.researchGateUrl != null)
                _buildSocialChip(context, 'ResearchGate', Icons.science),
              if (profile.websiteUrl != null)
                _buildSocialChip(context, 'Website', Icons.language),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialChip(BuildContext context, String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }

  Widget _buildPapersSection(BuildContext context, String userId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Public Papers',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to PublicUserProfileScreen for full papers list
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicUserProfileScreen(
                        userId: userId,
                      ),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('papers')
                .where('uploadedBy', isEqualTo: userId)
                .where('visibility', isEqualTo: 'public')
                .orderBy('uploadedAt', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text(
                  'Error loading papers',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text(
                  'No public papers yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.article),
                      title: Text(
                        data['title'] ?? 'Untitled',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        data['abstract'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(
                        Icons.public,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _hasSocialLinks(UserProfile profile) {
    return profile.linkedinUrl != null ||
        profile.googleScholarUrl != null ||
        profile.orcidId != null ||
        profile.researchGateUrl != null ||
        profile.websiteUrl != null;
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userId: userId),
      ),
    );
  }

  void _navigateToFollowers(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersScreen(userId: userId),
      ),
    );
  }

  void _navigateToFollowing(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowingScreen(userId: userId),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 2,
        child: Column(
          children: [
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.deepOrange.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.bookmark,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'Saved Papers',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('View your bookmarked research papers'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedPapersScreen(),
                  ),
                );
              },
            ),
            // Show My Papers to all current users
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400,
                      Colors.purple.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: const Text(
                'My Papers',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Manage your uploaded research papers'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyPapersScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProfilePicture(UserProfile profile) {
    // TODO: Implement full-screen profile picture viewer
  }
}
