import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/social_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/social_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/discussion_card.dart';
import '../../widgets/create_discussion_dialog.dart';
import '../../widgets/activity_feed_item.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  DiscussionCategory? _selectedCategory;

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscussionsTab(),
                _buildActivityFeedTab(),
                _buildFollowingTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDiscussionDialog,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Discussion',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Research Community',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.darkSlate,
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryBlue,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Discussions'),
          Tab(text: 'Activity'),
          Tab(text: 'Following'),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showNotifications,
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined,
                  color: AppTheme.darkSlate),
              Consumer<SocialProvider>(
                builder: (context, socialProvider, child) {
                  final authProvider = Provider.of<AuthProvider>(context);
                  final currentUserId = authProvider.currentUser?.id ?? '';
                  final unreadCount =
                      socialProvider.getUnreadNotificationCount(currentUserId);

                  if (unreadCount == 0) return const SizedBox.shrink();

                  return Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search discussions...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All', null),
                const SizedBox(width: 8),
                ...DiscussionCategory.values.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(
                      _getCategoryName(category),
                      category,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, DiscussionCategory? category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryBlue.withOpacity(0.1),
      checkmarkColor: AppTheme.primaryBlue,
      labelStyle: GoogleFonts.inter(
        color: isSelected ? AppTheme.primaryBlue : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  Widget _buildDiscussionsTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        List<DiscussionThread> discussions = socialProvider.discussions;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          discussions = socialProvider.searchDiscussions(_searchQuery);
        }

        // Apply category filter
        if (_selectedCategory != null) {
          discussions = discussions
              .where((d) => d.category == _selectedCategory)
              .toList();
        }

        if (discussions.isEmpty) {
          return _buildEmptyState(
            'No Discussions Found',
            'Be the first to start a research discussion!',
            Icons.forum_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh logic here
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: discussions.length,
            // Aggressive performance optimizations for smooth scrolling
            addAutomaticKeepAlives: false, // Disable to save memory
            addRepaintBoundaries: true,
            addSemanticIndexes: false,
            cacheExtent: 150, // Reduced cache for better performance
            physics: const ClampingScrollPhysics(), // Better for web/desktop
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12), // Reduced spacing
                child: RepaintBoundary(
                  child: DiscussionCard(discussion: discussions[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActivityFeedTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context);
        final currentUserId = authProvider.currentUser?.id ?? '';
        final activities = socialProvider.getFollowingActivities(currentUserId);

        if (activities.isEmpty) {
          return _buildEmptyState(
            'No Activity Yet',
            'Follow other researchers to see their activity here!',
            Icons.timeline_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh logic here
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            // Aggressive performance optimizations for smooth scrolling
            addAutomaticKeepAlives: false, // Disable to save memory
            addRepaintBoundaries: true,
            addSemanticIndexes: false,
            cacheExtent: 100, // Minimal cache for activity items
            physics: const ClampingScrollPhysics(), // Better for web/desktop
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8), // Reduced spacing
                child: RepaintBoundary(
                  child: ActivityFeedItemWidget(activity: activities[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFollowingTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context);
        final currentUserId = authProvider.currentUser?.id ?? '';
        final following = socialProvider.getFollowing(currentUserId);

        if (following.isEmpty) {
          return _buildEmptyState(
            'Not Following Anyone',
            'Discover and follow researchers to build your academic network!',
            Icons.people_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: following.length,
          // Aggressive performance optimizations for smooth scrolling
          addAutomaticKeepAlives: false, // Simple cards don't need keep alive
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
          cacheExtent: 50, // Minimal cache for simple user cards
          physics: const ClampingScrollPhysics(), // Better for web/desktop
          itemBuilder: (context, index) {
            return RepaintBoundary(
              child: _buildFollowingUserCard(following[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildFollowingUserCard(String userId) {
    // This would typically fetch user details
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
          child: Text(
            'U',
            style: GoogleFonts.inter(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          'User $userId', // Replace with actual user name
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Researcher',
          style: GoogleFonts.inter(color: Colors.grey[600]),
        ),
        trailing: Consumer<SocialProvider>(
          builder: (context, socialProvider, child) {
            final authProvider = Provider.of<AuthProvider>(context);
            final currentUserId = authProvider.currentUser?.id ?? '';
            final isFollowing =
                socialProvider.isFollowing(currentUserId, userId);

            return OutlinedButton(
              onPressed: () async {
                if (isFollowing) {
                  await socialProvider.unfollowUser(currentUserId, userId);
                } else {
                  await socialProvider.followUser(currentUserId, userId);
                }
              },
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    isFollowing ? AppTheme.primaryBlue : Colors.white,
                foregroundColor:
                    isFollowing ? Colors.white : AppTheme.primaryBlue,
              ),
              child: Text(isFollowing ? 'Following' : 'Follow'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCreateDiscussionDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateDiscussionDialog(),
    );
  }

  void _showNotifications() {
    Navigator.pushNamed(context, '/notifications');
  }

  String _getCategoryName(DiscussionCategory category) {
    switch (category) {
      case DiscussionCategory.general:
        return 'General';
      case DiscussionCategory.research:
        return 'Research';
      case DiscussionCategory.methodology:
        return 'Methodology';
      case DiscussionCategory.collaboration:
        return 'Collaboration';
      case DiscussionCategory.feedback:
        return 'Feedback';
      case DiscussionCategory.announcement:
        return 'Announcements';
    }
  }
}
