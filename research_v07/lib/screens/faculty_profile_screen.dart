import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/faculty.dart';
import '../common_widgets/safe_image.dart';
import 'research_papers_screen.dart';
import '../services/realtime_social_service.dart';
import '../services/messaging_service.dart';
import '../providers/auth_provider.dart';
import 'messaging/chat_screen.dart';

class FacultyProfileScreen extends StatefulWidget {
  final Faculty faculty;

  const FacultyProfileScreen({
    super.key,
    required this.faculty,
  });

  @override
  State<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends State<FacultyProfileScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  bool _isScrolled = false;
  final RealtimeSocialService _realtimeService = RealtimeSocialService();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _scrollController.addListener(_scrollListener);

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  void _scrollListener() {
    bool scrolled = _scrollController.offset > 100;
    if (_isScrolled != scrolled) {
      setState(() {
        _isScrolled = scrolled;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F1419) : const Color(0xFFF8FAFF),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildModernSliverAppBar(isDarkMode),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildModernProfileHeader(isDarkMode),
                  _buildModernContactSection(isDarkMode),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ultra-Modern Glass-morphic AppBar with blur effect
  Widget _buildModernSliverAppBar(bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      elevation: 0,
      backgroundColor: (isDarkMode ? const Color(0xFF1E293B) : Colors.white)
          .withOpacity(_isScrolled ? 0.95 : 0),
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle:
          isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: _isScrolled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16, right: 60),
        title: AnimatedOpacity(
          opacity: _isScrolled ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Text(
            widget.faculty.name,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        centerTitle: false,
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.share_rounded,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              size: 20,
            ),
            onPressed: () => _shareProfile(),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Ultra-Modern Glass-morphic Profile Header with stunning animations
  Widget _buildModernProfileHeader(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E293B)
            : const Color(0xFFFFFFFF).withOpacity(0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _scaleController,
              curve: Curves.easeOutBack,
            ),
            child: _buildModernProfileImage(isDarkMode),
          ),
          const SizedBox(height: 24),
          _buildModernNameAndTitle(isDarkMode),
          const SizedBox(height: 28),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final currentUser = authProvider.currentUser;
              if (currentUser == null) {
                return _buildModernActionButton(isDarkMode);
              }
              return Column(
                children: [
                  _buildModernActionButton(isDarkMode),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFollowButton(currentUser.id, isDarkMode),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMessageButton(currentUser, isDarkMode),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Ultra-Modern Profile Image with Teal/Blue Gradient Ring
  Widget _buildModernProfileImage(bool isDarkMode) {
    return Hero(
      tag: 'faculty_${widget.faculty.employeeId}',
      child: Container(
        width: 136,
        height: 136,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00D2FF),
              Color(0xFF3A7BD5),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D2FF).withOpacity(0.3),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: SafeCircleAvatar(
              radius: 60,
              imagePath: widget.faculty.imageUrl,
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            ),
          ),
        ),
      ),
    );
  }

  // Ultra-Modern Name and Title Section with elegant styling
  Widget _buildModernNameAndTitle(bool isDarkMode) {
    return Column(
      children: [
        Text(
          widget.faculty.name,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white : const Color(0xFF111827),
            letterSpacing: -1.0,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00D2FF),
                Color(0xFF3A7BD5),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D2FF).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.faculty.designation,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school_rounded,
                size: 14,
                color: isDarkMode ? Colors.grey[400] : const Color(0xFF4B5563),
              ),
              const SizedBox(width: 6),
              Text(
                _getDepartmentName(widget.faculty.department),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDarkMode ? Colors.grey[300] : const Color(0xFF4B5563),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Ultra-Modern Research Papers Button with stunning gradient
  Widget _buildModernActionButton(bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResearchPapersScreen(
                professorName: widget.faculty.name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00D2FF),
                Color(0xFF3A7BD5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.article_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'View Research Papers',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ultra-Modern Follow Button with smooth animations and glassmorphic design
  Widget _buildFollowButton(String currentUserId, bool isDarkMode) {
    final facultyUserId = _generateFacultyUserId();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(facultyUserId)
          .snapshots(),
      builder: (context, snapshot) {
        final isFollowing = snapshot.hasData && snapshot.data!.exists;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isFollowing
                ? null
                : const LinearGradient(
                    colors: [
                      Color(0xFF00D2FF),
                      Color(0xFF3A7BD5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isFollowing
                ? (isDarkMode
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEEF2FF))
                : null,
            border: isFollowing
                ? Border.all(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.15)
                        : const Color(0xFFE5E7EB),
                    width: 1.5,
                  )
                : null,
            boxShadow: isFollowing
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () async {
                try {
                  await _realtimeService.toggleFollow(
                    currentUserId: currentUserId,
                    targetUserId: facultyUserId,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFollowing
                                    ? Icons.person_remove_rounded
                                    : Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isFollowing ? 'Unfollowed' : 'Following!',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: isFollowing
                            ? const Color(0xFF64748B)
                            : const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(milliseconds: 2000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                        elevation: 8,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Something went wrong',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                        elevation: 8,
                      ),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(16),
              splashColor: isFollowing
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.white.withOpacity(0.2),
              highlightColor: isFollowing
                  ? Colors.grey.withOpacity(0.05)
                  : Colors.white.withOpacity(0.1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: child,
                        );
                      },
                      child: Icon(
                        isFollowing
                            ? Icons.person_remove_rounded
                            : Icons.person_add_alt_1_rounded,
                        key: ValueKey(isFollowing),
                        color: isFollowing
                            ? (isDarkMode
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF4B5563))
                            : Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isFollowing
                              ? (isDarkMode
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF4B5563))
                              : Colors.white,
                          letterSpacing: 0.1,
                          height: 1,
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Ultra-Modern Message Button with secondary design
  Widget _buildMessageButton(dynamic currentUser, bool isDarkMode) {
    final messagingService = MessagingService();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.15)
              : const Color(0xFFBAE6FD),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            try {
              final conversationId =
                  await messagingService.getOrCreateConversation(
                currentUserId: currentUser.id,
                otherUserId: _generateFacultyUserId(),
                currentUserName: currentUser.displayName,
                otherUserName: widget.faculty.name,
                currentUserUsername: currentUser.username,
                otherUserUsername: null,
                currentUserPhotoUrl: currentUser.photoURL,
                otherUserPhotoUrl: widget.faculty.imageUrl,
              );

              if (!mounted) return;
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    conversationId: conversationId,
                    otherUserId: _generateFacultyUserId(),
                    otherUserName: widget.faculty.name,
                    otherUserUsername: null,
                    otherUserPhotoUrl: widget.faculty.imageUrl,
                  ),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Failed to start conversation',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_rounded,
                  color: isDarkMode
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF0369A1),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Message',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF0369A1),
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Generate consistent user ID for faculty
  String _generateFacultyUserId() {
    return 'user_${widget.faculty.name.toLowerCase().replaceAll(' ', '_')}';
  }

  // Modern contact information section
  Widget _buildModernContactSection(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Icon(
                  Icons.contacts_rounded,
                  color: isDarkMode
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF2563EB),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Contact Information',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                _buildModernInfoTile(
                  Icons.business_rounded,
                  'Department',
                  widget.faculty.department,
                  isDarkMode,
                ),
                _buildModernInfoTile(
                  Icons.school_rounded,
                  'Faculty',
                  widget.faculty.faculty,
                  isDarkMode,
                ),
                _buildModernInfoTile(
                  Icons.badge_rounded,
                  'Employee ID',
                  widget.faculty.employeeId,
                  isDarkMode,
                ),
                _buildModernInfoTile(
                  Icons.email_rounded,
                  'Email',
                  widget.faculty.email,
                  isDarkMode,
                  isClickable: true,
                  onTap: () => _launchEmail(widget.faculty.email),
                ),
                _buildModernInfoTile(
                  Icons.phone_rounded,
                  'Office Phone',
                  widget.faculty.officePhone,
                  isDarkMode,
                  isClickable: true,
                  onTap: () => _launchPhone(widget.faculty.officePhone),
                ),
                _buildModernInfoTile(
                  Icons.smartphone_rounded,
                  'Cell Phone',
                  widget.faculty.cellPhone,
                  isDarkMode,
                  isClickable: true,
                  onTap: () => _launchPhone(widget.faculty.cellPhone),
                ),
                _buildModernInfoTile(
                  Icons.language_rounded,
                  'Personal Webpage',
                  widget.faculty.personalWebpage,
                  isDarkMode,
                  isClickable: true,
                  onTap: () => _launchUrl(widget.faculty.personalWebpage),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern info tile with enhanced design
  Widget _buildModernInfoTile(
    IconData icon,
    String label,
    String value,
    bool isDarkMode, {
    bool isClickable = false,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isClickable ? onTap : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF374151).withOpacity(0.6)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isDarkMode
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF2563EB),
                    ),
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
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isClickable
                                ? (isDarkMode
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF2563EB))
                                : (isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF1E293B)),
                            decoration:
                                isClickable ? TextDecoration.underline : null,
                            decorationColor: isClickable
                                ? (isDarkMode
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF2563EB))
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isClickable)
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
            indent: 52,
          ),
      ],
    );
  }

  // Helper methods
  String _getDepartmentName(String department) {
    if (department.contains('Computer Science')) return 'CSE Department';
    if (department.contains('Software')) return 'SWE Department';
    if (department.contains('Pharmacy')) return 'Pharmacy Department';
    if (department.contains('Electrical')) return 'EEE Department';
    return department;
  }

  void _shareProfile() {
    // Copy profile info to clipboard
    final profileInfo = '''
${widget.faculty.name}
${widget.faculty.designation}
${widget.faculty.department}
Email: ${widget.faculty.email}
Phone: ${widget.faculty.officePhone}
    ''';

    Clipboard.setData(ClipboardData(text: profileInfo));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile information copied to clipboard',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (!await launchUrl(emailUri)) {
      _showErrorSnackBar('Could not open email app');
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(phoneUri)) {
      _showErrorSnackBar('Could not open phone app');
    }
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _showErrorSnackBar('Could not launch $urlString');
      }
    } catch (e) {
      _showErrorSnackBar('Invalid URL: $urlString');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14),
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
