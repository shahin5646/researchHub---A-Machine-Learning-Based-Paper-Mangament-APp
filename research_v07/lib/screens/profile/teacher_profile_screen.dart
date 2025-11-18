import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_models.dart';
import '../../models/paper_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/follow_button.dart';
import '../../widgets/linkedin_style_paper_card.dart';

class TeacherProfileScreen extends StatefulWidget {
  final User teacher;

  const TeacherProfileScreen({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ResearchPaper> _teacherPapers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTeacherPapers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherPapers() async {
    // For now, use mock data since we need to adapt to Riverpod
    setState(() {
      _teacherPapers = []; // Empty for now
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildProfileAppBar(context, innerBoxIsScrolled),
        ],
        body: _buildTabContent(),
      ),
    );
  }

  Widget _buildProfileAppBar(BuildContext context, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.darkSlate,
      elevation: innerBoxIsScrolled ? 1 : 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showMoreOptions(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildProfileHeader(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: AppTheme.primaryBlue,
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Papers'),
              Tab(text: 'About'),
              Tab(text: 'Activity'),
              Tab(text: 'Contact'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          _buildProfileImage(),
          const SizedBox(height: 16),
          _buildProfileInfo(),
          const SizedBox(height: 16),
          _buildProfileStats(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryBlue.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: widget.teacher.profileImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                widget.teacher.profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultProfileImage(),
              ),
            )
          : _buildDefaultProfileImage(),
    );
  }

  Widget _buildDefaultProfileImage() {
    final initials = _getInitials(widget.teacher.name);
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Text(
          widget.teacher.name,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkSlate,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getRoleIcon(),
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              _getRoleTitle(),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        if (widget.teacher.department != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.teacher.department!,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
        if (widget.teacher.affiliation != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.teacher.affiliation!,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          'Papers',
          _teacherPapers.length.toString(),
        ),
        _buildStatItem('Followers', widget.teacher.followers.length.toString()),
        _buildStatItem('Following', widget.teacher.following.length.toString()),
        _buildStatItem(
          'Citations',
          '0', // Placeholder since citationCount doesn't exist in user_models
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkSlate,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isOwnProfile = authProvider.currentUser?.id == widget.teacher.id;

        if (isOwnProfile) {
          return ElevatedButton.icon(
            onPressed: () => _editProfile(context),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FollowButton(
              targetUserId: widget.teacher.id,
              targetUserName: widget.teacher.name,
              compact: false,
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _sendMessage(context),
              icon: const Icon(Icons.message, size: 18),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPapersTab(),
        _buildAboutTab(),
        _buildActivityTab(),
        _buildContactTab(),
      ],
    );
  }

  Widget _buildPapersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teacherPapers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No papers published yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Published research papers will appear here',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _teacherPapers.length,
      itemBuilder: (context, index) {
        return LinkedInStylePaperCard(
          paper: _teacherPapers[index],
          author: widget.teacher,
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.teacher.bio != null) ...[
            _buildSectionTitle('About'),
            const SizedBox(height: 12),
            Text(
              widget.teacher.bio!,
              style: GoogleFonts.inter(
                fontSize: 16,
                height: 1.5,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (widget.teacher.researchInterests.isNotEmpty) ...[
            _buildSectionTitle('Research Interests'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.teacher.researchInterests.map((interest) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    interest,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          _buildSectionTitle('Professional Information'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.school, 'Role', _getRoleTitle()),
          if (widget.teacher.department != null)
            _buildInfoRow(
                Icons.domain, 'Department', widget.teacher.department!),
          if (widget.teacher.affiliation != null)
            _buildInfoRow(Icons.location_city, 'Institution',
                widget.teacher.affiliation!),
          _buildInfoRow(Icons.email, 'Email', widget.teacher.email),
          _buildInfoRow(
            Icons.calendar_today,
            'Member since',
            _formatDate(widget.teacher.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return const Center(
      child: Text('Activity feed coming soon'),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Contact Information'),
          const SizedBox(height: 16),
          _buildContactCard(
            icon: Icons.email,
            title: 'Email',
            subtitle: widget.teacher.email,
            onTap: () => _sendEmail(widget.teacher.email),
          ),
          if (widget.teacher.affiliation != null)
            _buildContactCard(
              icon: Icons.location_on,
              title: 'Institution',
              subtitle: widget.teacher.affiliation!,
              onTap: () {},
            ),
          const SizedBox(height: 24),
          _buildSectionTitle('Connect'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendMessage(context),
                  icon: const Icon(Icons.message, size: 20),
                  label: const Text('Send Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _scheduleCall(context),
                  icon: const Icon(Icons.videocam, size: 20),
                  label: const Text('Schedule Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppTheme.darkSlate,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.darkSlate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
          child: Icon(
            icon,
            color: AppTheme.primaryBlue,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  // Helper methods
  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return words.isNotEmpty ? words[0][0].toUpperCase() : 'A';
  }

  IconData _getRoleIcon() {
    switch (widget.teacher.role) {
      case UserRole.faculty:
        return Icons.school;
      case UserRole.researcher:
        return Icons.science;
      default:
        return Icons.person;
    }
  }

  String _getRoleTitle() {
    switch (widget.teacher.role) {
      case UserRole.faculty:
        return 'Professor';
      case UserRole.researcher:
        return 'Researcher';
      case UserRole.student:
        return 'Student';
      default:
        return 'Academic';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // Action methods
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                _reportProfile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile(BuildContext context) {
    // Navigate to edit profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature coming soon')),
    );
  }

  void _sendMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messaging feature coming soon')),
    );
  }

  void _scheduleCall(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video call feature coming soon')),
    );
  }

  void _sendEmail(String email) {
    // Implement email functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening email client for $email')),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile link copied to clipboard')),
    );
  }

  void _reportProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted')),
    );
  }
}
