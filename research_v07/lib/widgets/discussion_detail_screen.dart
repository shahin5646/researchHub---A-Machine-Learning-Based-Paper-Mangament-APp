import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/social_models.dart';
import '../../theme/app_theme.dart';

class DiscussionDetailScreen extends StatelessWidget {
  final DiscussionThread discussion;

  const DiscussionDetailScreen({
    super.key,
    required this.discussion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discussion',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkSlate,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDiscussionHeader(),
            const SizedBox(height: 16),
            _buildDiscussionContent(),
            const SizedBox(height: 24),
            _buildCommentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              discussion.title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  child: Text(
                    discussion.authorName.isNotEmpty
                        ? discussion.authorName[0].toUpperCase()
                        : 'A',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  discussion.authorName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimeAgo(discussion.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionContent() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          discussion.content,
          style: GoogleFonts.inter(
            fontSize: 16,
            height: 1.5,
            color: AppTheme.darkSlate,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments (${discussion.comments.length})',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 16),
            if (discussion.comments.isEmpty)
              Center(
                child: Text(
                  'No comments yet. Be the first to comment!',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                  ),
                ),
              )
            else
              ...discussion.comments
                  .map((comment) => _buildCommentItem(comment)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(DiscussionComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: Text(
              comment.userName.isNotEmpty
                  ? comment.userName[0].toUpperCase()
                  : 'U',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
