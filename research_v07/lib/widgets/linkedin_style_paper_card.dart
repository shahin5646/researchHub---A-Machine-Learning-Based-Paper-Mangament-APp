import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/paper_models.dart';
import '../models/user_models.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/follow_button.dart';
import '../screens/papers/paper_detail_screen.dart';

class LinkedInStylePaperCard extends StatelessWidget {
  final ResearchPaper paper;
  final User? author;

  const LinkedInStylePaperCard({
    super.key,
    required this.paper,
    this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuthorHeader(context),
          _buildPaperContent(context),
          _buildInteractionBar(context),
          _buildSocialStats(context),
        ],
      ),
    );
  }

  Widget _buildAuthorHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildAuthorAvatar(context),
          const SizedBox(width: 12),
          Expanded(
            child: _buildAuthorInfo(context),
          ),
          _buildFollowButton(context),
        ],
      ),
    );
  }

  Widget _buildAuthorAvatar(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToAuthorProfile(context),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlue.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: author?.profileImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.network(
                  author!.profileImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultAvatar(),
                ),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    final initials = _getAuthorInitials();
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAuthorInfo(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToAuthorProfile(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            author?.name ?? _getFirstAuthor(),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkSlate,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                _getRoleIcon(),
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getAuthorSubtitle(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                _formatTimeAgo(paper.publishedDate),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCategoryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  paper.category,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getCategoryColor(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context) {
    if (author == null) return const SizedBox.shrink();

    return FollowButton(
      targetUserId: author!.id,
      targetUserName: author!.name,
      compact: true,
    );
  }

  Widget _buildPaperContent(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToPaperDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              paper.title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSlate,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (paper.abstract?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                paper.abstract!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (paper.description?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Author's Note",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      paper.description!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.darkSlate,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildPaperMetadata(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaperMetadata() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (paper.journal?.isNotEmpty == true)
          _buildMetadataItem(Icons.book, paper.journal!),
        if (paper.publishedDate.year > 1900)
          _buildMetadataItem(
              Icons.calendar_today, paper.publishedDate.year.toString()),
        _buildMetadataItem(Icons.visibility, '${paper.views} views'),
        _buildMetadataItem(Icons.download, '${paper.downloads} downloads'),
      ],
    );
  }

  Widget _buildMetadataItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionBar(BuildContext context) {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context);
        final currentUserId = authProvider.currentUser?.id ?? '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[200]!),
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInteractionButton(
                icon: Icons.thumb_up_outlined,
                label: 'Like',
                count: paper.reactions.values
                    .where((r) => r.type == ReactionType.like)
                    .length,
                isActive: paper.reactions.containsKey(currentUserId) &&
                    paper.reactions[currentUserId]!.type == ReactionType.like,
                onTap: () => _handleReaction(
                    socialProvider, ReactionType.like, currentUserId),
              ),
              _buildInteractionButton(
                icon: Icons.comment_outlined,
                label: 'Comment',
                count: paper.comments.length,
                onTap: () => _navigateToPaperDetail(context),
              ),
              _buildInteractionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () => _sharePaper(context),
              ),
              _buildInteractionButton(
                icon: paper.isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_outline,
                label: 'Save',
                isActive: paper.isBookmarked,
                onTap: () =>
                    _toggleBookmark(socialProvider, currentUserId, context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    int? count,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppTheme.primaryBlue : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              count != null && count > 0 ? '$label ($count)' : label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? AppTheme.primaryBlue : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialStats(BuildContext context) {
    final totalReactions = paper.reactions.length;
    final totalComments = paper.comments.length;

    if (totalReactions == 0 && totalComments == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (totalReactions > 0) ...[
            Row(
              children: [
                ...ReactionType.values.take(3).map((type) {
                  final count = paper.reactions.values
                      .where((r) => r.type == type)
                      .length;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(right: 2),
                    child: Text(
                      _getReactionEmoji(type),
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                Text(
                  '$totalReactions reactions',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          if (totalReactions > 0 && totalComments > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 12,
              color: Colors.grey[300],
            ),
          if (totalComments > 0)
            Text(
              '$totalComments comments',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  String _getAuthorInitials() {
    if (author != null) {
      final names = author!.name.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else if (names.isNotEmpty) {
        return names[0][0].toUpperCase();
      }
    }
    final firstAuthor = _getFirstAuthor();
    final words = firstAuthor.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return firstAuthor.isNotEmpty ? firstAuthor[0].toUpperCase() : 'A';
  }

  String _getFirstAuthor() {
    return paper.authors.isNotEmpty ? paper.authors.first : 'Unknown Author';
  }

  String _getAuthorSubtitle() {
    if (author != null) {
      final parts = <String>[];
      if (author!.role == UserRole.faculty) parts.add('Professor');
      if (author!.role == UserRole.researcher) parts.add('Researcher');
      if (author!.department?.isNotEmpty == true)
        parts.add(author!.department!);
      if (author!.affiliation?.isNotEmpty == true)
        parts.add(author!.affiliation!);
      return parts.join(' • ');
    }
    return 'Researcher';
  }

  IconData _getRoleIcon() {
    if (author?.role == UserRole.faculty) return Icons.school;
    if (author?.role == UserRole.researcher) return Icons.science;
    return Icons.person;
  }

  Color _getCategoryColor() {
    switch (paper.category.toLowerCase()) {
      case 'computer science':
        return Colors.blue;
      case 'physics':
        return Colors.purple;
      case 'chemistry':
        return Colors.green;
      case 'biology':
        return Colors.orange;
      case 'mathematics':
        return Colors.red;
      default:
        return AppTheme.primaryBlue;
    }
  }

  String _getReactionEmoji(ReactionType type) {
    switch (type) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.insightful:
        return '💡';
      case ReactionType.helpful:
        return '🔥';
      case ReactionType.bookmark:
        return '🔖';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  // Navigation methods
  void _navigateToAuthorProfile(BuildContext context) {
    if (author != null) {
      // Temporarily disabled due to User model conflicts
      // Will be resolved when standardizing User models
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('View ${author!.name} profile'),
          action: SnackBarAction(
            label: 'Coming Soon',
            onPressed: () {},
          ),
        ),
      );

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => TeacherProfileScreen(teacher: author!),
      //   ),
      // );
    }
  }

  void _navigateToPaperDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaperDetailScreen(paper: paper),
      ),
    );
  }

  // Interaction methods
  void _handleReaction(
      SocialProvider socialProvider, ReactionType type, String userId) {
    if (userId.isEmpty) return;
    socialProvider.reactToPaper(
      paperId: paper.id,
      userId: userId,
      reactionType: type,
    );
  }

  void _toggleBookmark(
      SocialProvider socialProvider, String userId, BuildContext context) {
    // Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            paper.isBookmarked ? 'Removed from saved' : 'Saved to bookmarks'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sharePaper(BuildContext context) {
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
            Text(
              'Share Paper',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share via...'),
              onTap: () {
                Navigator.pop(context);
                // Implement share functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
