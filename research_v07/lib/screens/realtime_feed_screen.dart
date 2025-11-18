import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/realtime_social_service.dart';
import '../widgets/realtime_comments_widget.dart';
import '../providers/auth_provider.dart';
import '../screens/unified_pdf_viewer.dart';

/// Real-time social media feed screen - works like Instagram/LinkedIn
/// All features update instantly across all devices
class RealtimeFeedScreen extends StatefulWidget {
  const RealtimeFeedScreen({super.key});

  @override
  State<RealtimeFeedScreen> createState() => _RealtimeFeedScreenState();
}

class _RealtimeFeedScreenState extends State<RealtimeFeedScreen>
    with SingleTickerProviderStateMixin {
  final RealtimeSocialService _socialService = RealtimeSocialService();
  late TabController _tabController;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          _buildFilterChips(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllPapersFeed(),
                _buildFollowingFeed(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Research Feed',
        style: GoogleFonts.inter(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF0F172A),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF0F172A),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'All Papers'),
          Tab(text: 'Following'),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      'All',
      'Computer Science',
      'Medical Science',
      'Engineering'
    ];

    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(filter),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: const Color(0xFF0F172A),
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllPapersFeed() {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _socialService.getPapersFeedStream(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final papers = _filterPapers(snapshot.data!);

        if (papers.isEmpty) {
          return _buildEmptyFilterState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            // StreamBuilder automatically refreshes
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: papers.length,
            itemBuilder: (context, index) {
              return _buildRealtimePaperCard(papers[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildFollowingFeed() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return _buildSignInPrompt();
    }

    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _socialService.getFollowingPapersFeedStream(
        currentUserId: currentUser.id,
        limit: 50,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoFollowingState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildRealtimePaperCard(snapshot.data![index]);
            },
          ),
        );
      },
    );
  }

  List<DocumentSnapshot> _filterPapers(List<DocumentSnapshot> papers) {
    if (_selectedFilter == 'All') return papers;

    return papers.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      final category = data?['category'] as String? ?? '';
      return category == _selectedFilter;
    }).toList();
  }

  Widget _buildRealtimePaperCard(DocumentSnapshot paperDoc) {
    final paperId = paperDoc.id;
    final paperData = paperDoc.data() as Map<String, dynamic>?;

    if (paperData == null) return const SizedBox();

    final title = paperData['title'] as String? ?? 'Untitled';
    final authorName = paperData['authorName'] as String? ?? 'Unknown Author';
    final uploadedBy = paperData['uploadedBy'] as String? ?? '';
    final category = paperData['category'] as String? ?? '';
    final abstract = paperData['abstract'] as String? ?? '';
    final uploadedAt = paperData['uploadedAt'] as Timestamp?;

    String timeAgo = 'Recently';
    if (uploadedAt != null) {
      try {
        timeAgo = timeago.format(uploadedAt.toDate(), locale: 'en_short');
      } catch (e) {
        // Handle error
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Author info + Follow button
          _buildPaperHeader(uploadedBy, authorName, category, timeAgo, paperId),

          // Paper Title & Abstract
          _buildPaperContent(title, abstract, paperId),

          // Real-time engagement stats
          _buildEngagementStats(paperId),

          // Action buttons (Like, Comment, Share)
          _buildActionButtons(paperId, title),
        ],
      ),
    );
  }

  Widget _buildPaperHeader(
    String uploadedBy,
    String authorName,
    String category,
    String timeAgo,
    String paperId,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Author Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF0F172A),
            child: Text(
              authorName.isNotEmpty ? authorName[0].toUpperCase() : 'A',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Author Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authorName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      ' • $timeAgo',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Real-time Follow Button
          if (currentUser != null && uploadedBy != currentUser.id)
            StreamBuilder<bool>(
              stream: _socialService.getFollowStatusStream(
                currentUserId: currentUser.id,
                targetUserId: uploadedBy,
              ),
              builder: (context, snapshot) {
                final isFollowing = snapshot.data ?? false;

                return OutlinedButton(
                  onPressed: () async {
                    await _socialService.toggleFollow(
                      currentUserId: currentUser.id,
                      targetUserId: uploadedBy,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    backgroundColor:
                        isFollowing ? Colors.grey.shade100 : Colors.white,
                    side: BorderSide(
                      color: isFollowing
                          ? Colors.grey.shade300
                          : const Color(0xFF0F172A),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFollowing
                          ? Colors.grey.shade700
                          : const Color(0xFF0F172A),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPaperContent(String title, String abstract, String paperId) {
    return InkWell(
      onTap: () => _openPaperDetails(paperId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (abstract.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                abstract,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementStats(String paperId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _socialService.getPaperStream(paperId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 12);

        final paperData = snapshot.data!.data() as Map<String, dynamic>?;
        final reactions =
            paperData?['reactions'] as Map<String, dynamic>? ?? {};
        final commentsCount = paperData?['commentsCount'] as int? ?? 0;
        final sharesCount = paperData?['sharesCount'] as int? ?? 0;

        final likeCount = reactions.length;

        if (likeCount == 0 && commentsCount == 0 && sharesCount == 0) {
          return const SizedBox(height: 12);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              if (likeCount > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 14,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$likeCount',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              if (likeCount > 0 && (commentsCount > 0 || sharesCount > 0))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '•',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              if (commentsCount > 0)
                Text(
                  '$commentsCount ${commentsCount == 1 ? 'comment' : 'comments'}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              if (sharesCount > 0) ...[
                if (commentsCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '•',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                Text(
                  '$sharesCount ${sharesCount == 1 ? 'share' : 'shares'}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(String paperId, String title) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: _socialService.getPaperStream(paperId),
      builder: (context, snapshot) {
        final paperData = snapshot.hasData
            ? snapshot.data!.data() as Map<String, dynamic>?
            : null;

        final reactions =
            paperData?['reactions'] as Map<String, dynamic>? ?? {};
        final isLiked =
            currentUser != null && reactions.containsKey(currentUser.id);
        final commentsCount = paperData?['commentsCount'] as int? ?? 0;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Like Button
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  color: isLiked ? Colors.red : Colors.grey.shade700,
                  onTap: () => _toggleLike(paperId),
                ),

                // Comment Button
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  color: Colors.grey.shade700,
                  onTap: () => _showComments(paperId, title),
                  badge: commentsCount > 0 ? commentsCount.toString() : null,
                ),

                // Share Button
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: Colors.grey.shade700,
                  onTap: () => _sharePaper(paperId, title),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(String paperId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      _showSignInDialog();
      return;
    }

    try {
      await _socialService.toggleLike(
        paperId: paperId,
        userId: currentUser.id,
        userName: currentUser.displayName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComments(String paperId, String title) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      _showSignInDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RealtimeCommentsWidget(
        paperId: paperId,
        paperTitle: title,
      ),
    );
  }

  Future<void> _sharePaper(String paperId, String title) async {
    try {
      await _socialService.sharePaper(paperId);

      final shareText = '''Check out this research paper:

$title

Shared from Research Hub''';

      await Share.share(shareText, subject: title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _openPaperDetails(String paperId) {
    // Navigate to PDF viewer or paper details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening paper: $paperId'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'No Papers Yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share research!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'No Papers Found',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFollowingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'No Following Feed',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow researchers to see their papers here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _tabController.animateTo(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Discover Researchers',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'Sign In Required',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to see papers from researchers you follow',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
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
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'Error Loading Feed',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showSignInDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign In Required',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Please sign in to interact with papers.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
