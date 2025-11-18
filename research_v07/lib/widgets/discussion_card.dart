import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/social_models.dart';
import '../providers/social_provider.dart';
import '../theme/app_theme.dart';

class DiscussionCard extends StatelessWidget {
  final DiscussionThread discussion;

  const DiscussionCard({
    super.key,
    required this.discussion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToDiscussion(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildContent(),
              const SizedBox(height: 12),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final socialProvider = Provider.of<SocialProvider>(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
          child: Text(
            discussion.authorName.isNotEmpty
                ? discussion.authorName[0].toUpperCase()
                : 'A',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                discussion.authorName,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.darkSlate,
                ),
              ),
              Text(
                socialProvider.formatTimeAgo(discussion.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildCategoryBadge(context),
      ],
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    final socialProvider = Provider.of<SocialProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            socialProvider.getCategoryIcon(discussion.category),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            _getCategoryName(discussion.category),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          discussion.title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkSlate,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          discussion.content,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (discussion.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: discussion.tags.take(3).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$tag',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        _buildStatItem(
          Icons.comment_outlined,
          discussion.comments.length.toString(),
          'Comments',
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          Icons.thumb_up_outlined,
          discussion.reactions.length.toString(),
          'Reactions',
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          Icons.visibility_outlined,
          discussion.viewCount.toString(),
          'Views',
        ),
        const Spacer(),
        if (discussion.isPinned)
          Icon(
            Icons.push_pin,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _navigateToDiscussion(BuildContext context) {
    // For now, just show a simple dialog
    // Later this would navigate to a full discussion detail screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(discussion.title),
        content: Text(discussion.content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
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
