import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../models/user.dart';
import '../../models/paper_models.dart';
import '../../main.dart';

class PublicUserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final AppUser? user; // Optional pre-loaded user

  const PublicUserProfileScreen({
    super.key,
    required this.userId,
    this.user,
  });

  @override
  ConsumerState<PublicUserProfileScreen> createState() =>
      _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState
    extends ConsumerState<PublicUserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppUser? _user;
  bool _isLoading = true;
  bool _isFollowing = false;
  int _publicPapersCount = 0;
  List<ResearchPaper> _publicPapers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Load user if not provided
      if (widget.user != null) {
        _user = widget.user;
      } else {
        final authState = ref.read(authProvider);
        _user = await authState.getUserById(widget.userId);
      }

      // Check if current user is following
      final authState = ref.read(authProvider);
      if (authState.currentUser != null) {
        _isFollowing = authState.isFollowing(widget.userId);
      }

      // Load public papers count
      await _loadPublicPapers();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPublicPapers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('research_papers')
          .where('uploadedBy', isEqualTo: widget.userId)
          .where('visibility', isEqualTo: 'public')
          .orderBy('uploadedAt', descending: true)
          .get();

      setState(() {
        _publicPapersCount = snapshot.docs.length;
        // For now, just store count. In production, parse into ResearchPaper objects
      });
    } catch (e) {
      debugPrint('Error loading public papers: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildProfileHeader()),
          SliverToBoxAdapter(child: _buildStatsRow()),
          SliverToBoxAdapter(child: _buildTabBar()),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPublicPapersTab(),
                _buildAboutTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getRoleColor().withOpacity(0.8),
                _getRoleColor(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_getRoleColor(), _getRoleColor().withOpacity(0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _getRoleColor().withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _user!.photoURL != null
                ? ClipOval(
                    child: Image.network(
                      _user!.photoURL!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _user!.displayName,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          if (_user!.username != null) ...[
            const SizedBox(height: 4),
            Text(
              '@${_user!.username}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _getRoleColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoleLabel(),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _getRoleColor(),
              ),
            ),
          ),

          if (_user!.bio != null) ...[
            const SizedBox(height: 16),
            Text(
              _user!.bio!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF475569),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        _user!.displayName[0].toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final authState = ref.watch(authProvider);
    final isOwnProfile = authState.currentUser?.uid == widget.userId;

    if (isOwnProfile) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleFollow,
            icon: Icon(_isFollowing ? Icons.check : Icons.person_add_rounded),
            label: Text(_isFollowing ? 'Following' : 'Follow'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isFollowing ? const Color(0xFFE2E8F0) : _getRoleColor(),
              foregroundColor:
                  _isFollowing ? const Color(0xFF475569) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Navigate to messaging
          },
          icon: const Icon(Icons.message_rounded),
          label: const Text('Message'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE2E8F0),
            foregroundColor: const Color(0xFF475569),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Papers', _publicPapersCount.toString()),
          _buildStatItem('Followers', _user!.followers.length.toString()),
          _buildStatItem('Following', _user!.following.length.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _getRoleColor(),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: _getRoleColor(),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Publications'),
          Tab(text: 'About'),
        ],
      ),
    );
  }

  Widget _buildPublicPapersTab() {
    if (_publicPapersCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No public papers yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('research_papers')
          .where('uploadedBy', isEqualTo: widget.userId)
          .where('visibility', isEqualTo: 'public')
          .orderBy('uploadedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final papers = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: papers.length,
          itemBuilder: (context, index) {
            final paper = papers[index].data() as Map<String, dynamic>;
            return _buildPaperCard(paper);
          },
        );
      },
    );
  }

  Widget _buildPaperCard(Map<String, dynamic> paper) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              paper['title'] ?? 'Untitled',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            if (paper['abstract'] != null)
              Text(
                paper['abstract'],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.visibility_outlined,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${paper['views'] ?? 0} views',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.download_outlined,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${paper['downloads'] ?? 0} downloads',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_user!.institution != null)
          _buildInfoCard(
            'Institution',
            _user!.institution!,
            Icons.school_rounded,
          ),
        if (_user!.department != null)
          _buildInfoCard(
            'Department',
            _user!.department!,
            Icons.business_rounded,
          ),
        if (_user!.designation != null)
          _buildInfoCard(
            'Designation',
            _user!.designation!,
            Icons.work_rounded,
          ),
        if (_user!.researchInterests.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Research Interests',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _user!.researchInterests
                .map((interest) => Chip(
                      label: Text(interest),
                      backgroundColor: _getRoleColor().withOpacity(0.1),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getRoleColor(),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRoleColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _getRoleColor(), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor() {
    switch (_user!.role) {
      case UserRole.professor:
        return const Color(0xFFDC2626);
      case UserRole.researcher:
        return const Color(0xFF0891B2);
      case UserRole.student:
        return const Color(0xFF4F46E5);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getRoleLabel() {
    switch (_user!.role) {
      case UserRole.professor:
        return 'Faculty Member';
      case UserRole.researcher:
        return 'Researcher';
      case UserRole.student:
        return 'Student';
      default:
        return 'User';
    }
  }

  Future<void> _toggleFollow() async {
    final authState = ref.read(authProvider);

    setState(() => _isFollowing = !_isFollowing);

    try {
      if (_isFollowing) {
        await authState.followUser(widget.userId);
      } else {
        await authState.unfollowUser(widget.userId);
      }
    } catch (e) {
      // Revert on error
      setState(() => _isFollowing = !_isFollowing);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
