import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_user.dart';
import '../models/user.dart'; // For UserRole
import '../providers/auth_provider.dart';

import '../services/realtime_social_service.dart';
import '../widgets/realtime_comments_widget.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../screens/unified_pdf_viewer.dart';
import '../screens/faculty_profile_screen.dart';
import '../screens/user_search_screen.dart';
import '../data/faculty_data.dart';
import '../utils/firestore_seeder.dart';

class LinkedInStylePapersScreen extends StatefulWidget {
  const LinkedInStylePapersScreen({super.key});

  @override
  State<LinkedInStylePapersScreen> createState() =>
      _LinkedInStylePapersScreenState();
}

class _LinkedInStylePapersScreenState extends State<LinkedInStylePapersScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  bool _showPostComposer = true;
  final RealtimeSocialService _realtimeService = RealtimeSocialService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _paperOrder = []; // Maintain stable paper order
  final List<Map<String, dynamic>> _filters = [
    {'name': 'All', 'icon': Icons.feed_outlined},
    {'name': 'Following', 'icon': Icons.people_outline},
    {'name': 'Computer Science', 'icon': Icons.computer},
    {'name': 'Research Papers', 'icon': Icons.article_outlined},
    {'name': 'Recent', 'icon': Icons.schedule},
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        cacheExtent: 500.0,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _buildModernAppBar(false),
          SliverToBoxAdapter(
            child: _buildModernFilterBar(),
          ),
          if (_showPostComposer)
            SliverToBoxAdapter(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: 1.0,
                child: _buildModernPostComposer(),
              ),
            ),
          _buildModernPapersFeedSliver(),
        ],
      ),
    );
  }

  SliverAppBar _buildModernAppBar(bool isScrolled) {
    return SliverAppBar(
      expandedHeight: 100, // Reduced from 120
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      elevation: 0, // Flat design
      surfaceTintColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: Colors.white, // 2025 Minimal: Flat white, no gradient
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36, // Reduced from 40
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9), // Minimal gray bg
                          borderRadius:
                              BorderRadius.circular(8), // Reduced radius
                        ),
                        child: const Icon(
                          Icons.feed_outlined, // Outlined icon
                          color: Color(0xFF0F172A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Research Feed',
                              style: GoogleFonts.inter(
                                fontSize: 20, // Reduced from 24
                                fontWeight:
                                    FontWeight.w700, // Reduced from w800
                                color: const Color(0xFF0F172A),
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Academic networking & research sharing',
                              style: GoogleFonts.inter(
                                fontSize: 13, // Reduced from 14
                                fontWeight:
                                    FontWeight.w400, // Reduced from w500
                                color: const Color(0xFF64748B),
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        // User Search/Discovery
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.people_outline,
                  size: 18, color: Color(0xFF64748B)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserSearchScreen(),
                ),
              );
            },
            tooltip: 'Find Users',
          ),
        ),
        // Paper Search
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC), // Very subtle bg
                borderRadius: BorderRadius.circular(8), // Reduced from 10
              ),
              child: const Icon(Icons.search_outlined,
                  size: 18, color: Color(0xFF64748B)),
            ),
            onPressed: () => _showSearchDialog(),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_outlined,
                  size: 18, color: Color(0xFF64748B)),
            ),
            onPressed: () => _showNotifications(),
          ),
        ),
      ],
    );
  }

  Widget _buildModernFilterBar() {
    return Container(
      height: 64, // Reduced from 80
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter['name'];
          return Container(
            margin: const EdgeInsets.only(right: 8), // Reduced from 12
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = filter['name'];
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : Colors.white, // Dark when selected
                  borderRadius: BorderRadius.circular(8), // Reduced from 25
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'],
                      size: 16, // Reduced from 18
                      color:
                          isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6), // Reduced from 8
                    Text(
                      filter['name'],
                      style: GoogleFonts.inter(
                        fontSize: 13, // Reduced from 14
                        fontWeight: FontWeight.w500, // Reduced from w600
                        color:
                            isSelected ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernPostComposer() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final canPost = user?.role == UserRole.professor ||
            user?.role == UserRole.admin ||
            user?.role == UserRole.student;

        if (!canPost) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12), // Reduced vertical
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12), // Reduced from 16
            border: Border.all(
              color: const Color(0xFFE2E8F0), // Subtle border instead of shadow
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16), // Reduced from 20
                child: Row(
                  children: [
                    _buildUserAvatar(user),
                    const SizedBox(width: 12), // Reduced from 16
                    Expanded(
                      child: InkWell(
                        onTap: () => _showCreatePostDialog(),
                        borderRadius:
                            BorderRadius.circular(8), // Reduced from 25
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, // Reduced from 20
                            vertical: 12, // Reduced from 16
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF8FAFC), // Lighter background
                            borderRadius:
                                BorderRadius.circular(8), // Reduced from 25
                            border: Border.all(
                                color:
                                    const Color(0xFFE2E8F0)), // Subtle border
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _getPostPlaceholder(user?.role),
                                  style: GoogleFonts.inter(
                                    fontSize: 13, // Reduced from 14
                                    color:
                                        const Color(0xFF64748B), // Muted gray
                                    fontWeight:
                                        FontWeight.w400, // Reduced from w500
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.edit_outlined,
                                color: const Color(0xFF94A3B8), // Lighter gray
                                size: 18, // Reduced from 20
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: const Color(0xFFE2E8F0), // Subtle divider
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10), // Reduced padding
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.article_outlined,
                      label: 'Paper',
                      color: const Color(0xFF3B82F6), // Blue
                      onTap: () => _showAddPaperDialog(),
                    ),
                    _buildActionButton(
                      icon: Icons.image_outlined,
                      label: 'Photo',
                      color: const Color(0xFF059669), // Green
                      onTap: () => _showAddPhotoDialog(),
                    ),
                    _buildActionButton(
                      icon: Icons.link_outlined,
                      label: 'Link',
                      color: const Color(0xFFF59E0B), // Amber
                      onTap: () => _showAddLinkDialog(),
                    ),
                    _buildActionButton(
                      icon: Icons.poll_outlined,
                      label: 'Poll',
                      color: const Color(0xFF8B5CF6), // Purple
                      onTap: () => _showCreatePollDialog(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernPapersFeedSliver() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.currentUser;

        if (currentUser == null) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Please sign in',
                      style: GoogleFonts.inter(fontSize: 16)),
                ],
              ),
            ),
          );
        }

        // Show following list instead of papers when Following tab is selected
        if (_selectedFilter == 'Following') {
          return SliverFillRemaining(
            child: _buildFollowingList(currentUser.id),
          );
        }

        // Use real-time stream for papers feed
        final stream = _realtimeService.getPapersFeedStream(limit: 30);

        return StreamBuilder<List<DocumentSnapshot>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Error loading feed',
                          style: GoogleFonts.inter(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('${snapshot.error}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              );
            }

            var papers = snapshot.data ?? [];

            // Initialize paper order on first load to keep stable positions
            if (_paperOrder.isEmpty && papers.isNotEmpty) {
              _paperOrder = papers.map((p) => p.id).toList();
            }

            // Sort papers by the stable order (Instagram-like behavior)
            if (_paperOrder.isNotEmpty) {
              papers.sort((a, b) {
                final aIndex = _paperOrder.indexOf(a.id);
                final bIndex = _paperOrder.indexOf(b.id);
                if (aIndex == -1) return 1; // New papers go to end
                if (bIndex == -1) return -1;
                return aIndex.compareTo(bIndex);
              });
            }

            // Filter papers based on search query
            if (_searchQuery.isNotEmpty) {
              papers = papers.where((paper) {
                final data = paper.data() as Map<String, dynamic>?;
                if (data == null) return false;

                final title = (data['title'] as String? ?? '').toLowerCase();
                final authors =
                    (data['authors'] as String? ?? '').toLowerCase();
                final abstract =
                    (data['abstract'] as String? ?? '').toLowerCase();
                final topics =
                    (data['topics'] as List?)?.join(' ').toLowerCase() ?? '';
                final authorName =
                    (data['authorName'] as String? ?? '').toLowerCase();

                return title.contains(_searchQuery) ||
                    authors.contains(_searchQuery) ||
                    abstract.contains(_searchQuery) ||
                    topics.contains(_searchQuery) ||
                    authorName.contains(_searchQuery);
              }).toList();
            }

            if (papers.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No papers yet',
                          style: GoogleFonts.inter(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Load real faculty research papers!',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: Colors.grey.shade600)),
                      const SizedBox(height: 24),
                      // Button to add real faculty papers
                      ElevatedButton.icon(
                        onPressed: () async {
                          final seeder = FirestoreSeeder();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '🌱 Loading 60 papers from 11 faculty members...'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                          // Clear existing papers first to ensure exactly 60
                          await seeder.clearAllPapers();
                          setState(() {
                            _paperOrder.clear(); // Reset paper order
                          });
                          await Future.delayed(
                              const Duration(milliseconds: 500));
                          await seeder.seedSamplePapers(currentUser.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ 60 faculty papers loaded!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.school),
                        label: const Text('Add 60 Faculty Papers'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Show "Clear & Reload" button when papers exist
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverMainAxisGroup(
                slivers: [
                  // Clear and reload button at the top
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final seeder = FirestoreSeeder();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🗑️ Clearing old papers...'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                await seeder.clearAllPapers();
                                setState(() {
                                  _paperOrder.clear(); // Reset paper order
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Old papers cleared!'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text('Clear All',
                                  style: GoogleFonts.inter(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final seeder = FirestoreSeeder();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        '🔄 Reloading 60 papers from 11 faculty members...'),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                await seeder.clearAllPapers();
                                setState(() {
                                  _paperOrder.clear(); // Reset paper order
                                });
                                await Future.delayed(
                                    const Duration(milliseconds: 500));
                                await seeder.seedSamplePapers(currentUser.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('✅ Faculty papers reloaded!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text('Reload 60 Papers',
                                  style: GoogleFonts.inter(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Papers list
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final paperDoc = papers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RepaintBoundary(
                            key: ValueKey(paperDoc.id),
                            child:
                                _buildRealtimePaperCard(paperDoc, currentUser),
                          ),
                        );
                      },
                      childCount: papers.length,
                      addAutomaticKeepAlives: true,
                      addRepaintBoundaries: true,
                      addSemanticIndexes: true,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserAvatar(AppUser? user) {
    return Container(
      width: 44, // Reduced from 50
      height: 44, // Reduced from 50
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF0F172A), // Flat dark background
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 2,
        ),
      ),
      child: user?.profileImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                user!.profileImageUrl!,
                fit: BoxFit.cover,
                cacheWidth: 100, // Limit cache size for better memory
                cacheHeight: 100,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildDefaultAvatar(user.name);
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultAvatar(user.name),
              ),
            )
          : _buildDefaultAvatar(user?.name ?? 'U'),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6), // Reduced from 8
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10), // Reduced from 12
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18), // Reduced from 20
              const SizedBox(width: 5), // Reduced from 6
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12, // Reduced from 13
                  fontWeight: FontWeight.w500, // Reduced from w600
                  color: const Color(0xFF64748B), // Muted gray
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPostPlaceholder(UserRole? role) {
    switch (role) {
      case UserRole.professor:
        return 'Share your latest research or academic insights...';
      case UserRole.admin:
        return 'Share announcements or updates...';
      case UserRole.student:
        return 'Share your thoughts on research or ask questions...';
      default:
        return 'What\'s on your mind?';
    }
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (value) {
                          setModalState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search papers, authors, topics...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setModalState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _searchQuery = '';
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final currentUser = authProvider.currentUser;
                    if (currentUser == null) {
                      return const Center(child: Text('Please sign in'));
                    }

                    return StreamBuilder<List<DocumentSnapshot>>(
                      stream: _realtimeService.getPapersFeedStream(limit: 100),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        var papers = snapshot.data ?? [];

                        // Filter papers based on search query
                        if (_searchQuery.isNotEmpty) {
                          papers = papers.where((paper) {
                            final data = paper.data() as Map<String, dynamic>?;
                            if (data == null) return false;

                            final title =
                                (data['title'] as String? ?? '').toLowerCase();
                            final authors = (data['authors'] as String? ?? '')
                                .toLowerCase();
                            final abstract = (data['abstract'] as String? ?? '')
                                .toLowerCase();
                            final topics = (data['topics'] as List?)
                                    ?.join(' ')
                                    .toLowerCase() ??
                                '';
                            final authorName =
                                (data['authorName'] as String? ?? '')
                                    .toLowerCase();

                            return title.contains(_searchQuery) ||
                                authors.contains(_searchQuery) ||
                                abstract.contains(_searchQuery) ||
                                topics.contains(_searchQuery) ||
                                authorName.contains(_searchQuery);
                          }).toList();
                        }

                        if (_searchQuery.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'Search papers, authors, or topics',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (papers.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try different keywords',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: papers.length,
                          itemBuilder: (context, index) {
                            final paper = papers[index];
                            return _buildRealtimePaperCard(paper, currentUser);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications() {
    Navigator.pushNamed(context, '/notifications');
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Create Post',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                maxLines: 10,
                minLines: 5,
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Post',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPaperDialog() {
    Navigator.pushNamed(context, '/add-paper');
  }

  void _showAddPhotoDialog() {
    // Implement photo upload
  }

  void _showAddLinkDialog() {
    // Implement link sharing
  }

  void _showCreatePollDialog() {
    // Implement poll creation
  }

  Widget _buildRealtimePaperCard(
      DocumentSnapshot paperDoc, AppUser currentUser) {
    final data = paperDoc.data() as Map<String, dynamic>?;

    if (data == null) return const SizedBox.shrink();

    final paperId = paperDoc.id;
    final title = data['title'] as String? ?? 'Untitled';
    final abstract = data['abstract'] as String? ?? '';
    final authorName = data['authorName'] as String? ?? 'Unknown';

    // Generate authorId from author name if missing or invalid
    var authorId = data['authorId'] as String? ?? '';
    if (authorId.isEmpty || authorId == currentUser.id) {
      authorId = _generateUserIdFromAuthor(authorName);
    }

    final createdAt =
        (data['uploadedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?)
                ?.toDate() ??
            DateTime.now();
    final pdfUrl = data['pdfUrl'] as String? ?? '';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Author Header with Follow Button
            _buildRealtimeAuthorHeader(
                authorId, authorName, createdAt, currentUser),
            const SizedBox(height: 12),

            // Paper Content (Track clicks when tapped)
            GestureDetector(
              onTap: () {
                // Track paper click for engagement ranking
                _realtimeService.incrementPaperClicks(paperId);
                _openPaperPDFFromUrl(pdfUrl, title);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (abstract.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      abstract,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Real-time Engagement Stats
            _buildRealtimeEngagementStats(paperId),
            const SizedBox(height: 8),

            // Real-time Action Buttons
            _buildRealtimeActionButtons(paperId, currentUser),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeAuthorHeader(String authorId, String authorName,
      DateTime createdAt, AppUser currentUser) {
    return Row(
      children: [
        // Author Avatar
        GestureDetector(
          onTap: () => _navigateToAuthorProfile(authorName),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: const Color(0xFF0F172A),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getAuthorInitials(authorName),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Author Info
        Expanded(
          child: GestureDetector(
            onTap: () => _navigateToAuthorProfile(authorName),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authorName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  timeago.format(createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Real-time Follow Button
        if (currentUser.id != authorId)
          StreamBuilder<bool>(
            stream: _realtimeService.getFollowStatusStream(
              currentUserId: currentUser.id,
              targetUserId: authorId,
            ),
            builder: (context, snapshot) {
              final isFollowing = snapshot.data ?? false;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: OutlinedButton(
                  onPressed: () => _handleRealtimeFollow(
                      currentUser.id, authorId, isFollowing),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: isFollowing
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    backgroundColor:
                        isFollowing ? const Color(0xFFF1F5F9) : Colors.white,
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isFollowing
                          ? const Color(0xFF64748B)
                          : const Color(0xFF0F172A),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRealtimeEngagementStats(String paperId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('papers')
          .doc(paperId)
          .snapshots(includeMetadataChanges: false),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final likesCount = data?['likesCount'] as int? ?? 0;
        final commentsCount = data?['commentsCount'] as int? ?? 0;
        final sharesCount = data?['sharesCount'] as int? ?? 0;

        return Row(
          children: [
            if (likesCount > 0) ...[
              Icon(Icons.favorite, size: 14, color: Colors.red.shade400),
              const SizedBox(width: 4),
              Text(
                '$likesCount',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (commentsCount > 0) ...[
              Text(
                '$commentsCount comments',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (sharesCount > 0) ...[
              Text(
                '$sharesCount shares',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRealtimeActionButtons(String paperId, AppUser currentUser) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('papers')
          .doc(paperId)
          .snapshots(includeMetadataChanges: false),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final reactions = data?['reactions'] as Map<String, dynamic>? ?? {};
        final isLiked = reactions.containsKey(currentUser.id);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Like Button
            Expanded(
              child: InkWell(
                onTap: () => _handleRealtimeLike(paperId, currentUser),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_outline,
                        size: 20,
                        color: isLiked ? Colors.red : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Like',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isLiked ? Colors.red : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Comment Button
            Expanded(
              child: InkWell(
                onTap: () => _handleRealtimeComment(paperId),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.comment_outlined,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Comment',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Share Button
            Expanded(
              child: InkWell(
                onTap: () => _handleShare(
                    paperId, data?['title'] as String? ?? 'Research Paper'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Share',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleRealtimeLike(String paperId, AppUser currentUser) async {
    try {
      await _realtimeService.toggleLike(
        paperId: paperId,
        userId: currentUser.id,
        userName: currentUser.displayName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleRealtimeFollow(
      String currentUserId, String targetUserId, bool isFollowing) async {
    try {
      final result = await _realtimeService.toggleFollow(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result ? 'Following!' : 'Unfollowed',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: result ? Colors.green : Colors.grey[700],
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleRealtimeComment(String paperId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RealtimeCommentsWidget(
        paperId: paperId,
        paperTitle: 'Research Paper',
      ),
    );
  }

  void _handleShare(String paperId, String title) {
    Share.share('Check out this research paper: $title');
  }

  void _openPaperPDFFromUrl(String pdfUrl, String title) {
    if (pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF not available')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedPdfViewer(
          pdfPath: pdfUrl,
          title: title,
        ),
      ),
    );
  }

  void _navigateToAuthorProfile(String authorId) {
    // Navigate to faculty profile
    final faculty = facultyMembers.firstWhere(
      (f) =>
          _generateUserIdFromAuthor(f.name) == authorId || f.name == authorId,
      orElse: () => facultyMembers.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FacultyProfileScreen(faculty: faculty),
      ),
    );
  }

  String _generateUserIdFromAuthor(String authorName) {
    return 'user_${authorName.toLowerCase().replaceAll(' ', '_')}';
  }

  String _getAuthorInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'A';
  }

  // Build Instagram-style following list
  Widget _buildFollowingList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('following')
          .snapshots(includeMetadataChanges: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('Error loading following list',
                    style: GoogleFonts.inter(fontSize: 16)),
              ],
            ),
          );
        }

        final followingDocs = snapshot.data?.docs ?? [];

        if (followingDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('Not following anyone yet',
                    style: GoogleFonts.inter(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Follow faculty to see their papers!',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: followingDocs.length,
          itemBuilder: (context, index) {
            final followingId = followingDocs[index].id;
            return _buildFollowingUserCard(userId, followingId);
          },
        );
      },
    );
  }

  // Build user card for following list
  Widget _buildFollowingUserCard(String currentUserId, String targetUserId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .snapshots(includeMetadataChanges: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();

        final name = userData['name'] ?? 'Unknown User';
        final email = userData['email'] ?? '';
        final followersCount = userData['followersCount'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF0F172A),
              child: Text(
                _getAuthorInitials(name),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(
              name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '$followersCount followers',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            trailing: _buildFollowingButton(currentUserId, targetUserId),
          ),
        );
      },
    );
  }

  // Build follow/unfollow button
  Widget _buildFollowingButton(String currentUserId, String targetUserId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .snapshots(includeMetadataChanges: false),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data?.exists ?? false;

        return OutlinedButton(
          onPressed: () async {
            try {
              await _realtimeService.toggleFollow(
                currentUserId: currentUserId,
                targetUserId: targetUserId,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFollowing ? 'Unfollowed' : 'Following!'),
                    backgroundColor: isFollowing ? Colors.grey : Colors.green,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey.shade100 : Colors.white,
            side: BorderSide(
              color:
                  isFollowing ? Colors.grey.shade400 : const Color(0xFF0F172A),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: GoogleFonts.inter(
              color:
                  isFollowing ? Colors.grey.shade700 : const Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }
}
