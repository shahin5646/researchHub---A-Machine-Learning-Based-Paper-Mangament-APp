import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/paper_models.dart';
import '../../providers/social_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class PaperSocialInteractions extends StatefulWidget {
  final ResearchPaper paper;

  const PaperSocialInteractions({
    super.key,
    required this.paper,
  });

  @override
  State<PaperSocialInteractions> createState() =>
      _PaperSocialInteractionsState();
}

class _PaperSocialInteractionsState extends State<PaperSocialInteractions> {
  final _commentController = TextEditingController();
  bool _showCommentField = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReactionsSection(socialProvider),
            const SizedBox(height: 16),
            _buildCommentsSection(socialProvider),
          ],
        );
      },
    );
  }

  Widget _buildReactionsSection(SocialProvider socialProvider) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reactions',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ReactionType.values.map((type) {
                final count = widget.paper.reactions.values
                    .where((r) => r.type == type)
                    .length;
                final hasReacted =
                    widget.paper.reactions.containsKey(currentUserId) &&
                        widget.paper.reactions[currentUserId]!.type == type;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildReactionButton(
                    socialProvider,
                    type,
                    count,
                    hasReacted,
                    currentUserId,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton(
    SocialProvider socialProvider,
    ReactionType type,
    int count,
    bool hasReacted,
    String currentUserId,
  ) {
    return InkWell(
      onTap: () => _handleReaction(socialProvider, type, currentUserId),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasReacted
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: hasReacted
              ? Border.all(color: AppTheme.primaryBlue, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              socialProvider.getReactionIcon(type),
              style: const TextStyle(fontSize: 16),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasReacted ? AppTheme.primaryBlue : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(SocialProvider socialProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments (${widget.paper.comments.length})',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkSlate,
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showCommentField = !_showCommentField),
                  icon: Icon(
                    _showCommentField ? Icons.close : Icons.add_comment,
                    size: 16,
                  ),
                  label: Text(
                    _showCommentField ? 'Cancel' : 'Add Comment',
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                ),
              ],
            ),
            if (_showCommentField) ...[
              const SizedBox(height: 12),
              _buildCommentField(socialProvider),
            ],
            if (widget.paper.comments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              ...widget.paper.comments
                  .map((comment) => _buildCommentItem(comment)),
            ] else if (!_showCommentField) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'No comments yet. Be the first to comment!',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentField(SocialProvider socialProvider) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id ?? '';

    return Column(
      children: [
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Share your thoughts about this paper...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryBlue),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() => _showCommentField = false);
                _commentController.clear();
              },
              child: Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _addComment(socialProvider, currentUserId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Post Comment'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentItem(PaperComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.userName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.darkSlate,
                      ),
                    ),
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _likeComment(comment),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.thumb_up_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            comment.likes.length.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
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
        ],
      ),
    );
  }

  void _handleReaction(
    SocialProvider socialProvider,
    ReactionType type,
    String currentUserId,
  ) {
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to react to papers'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    socialProvider.reactToPaper(
      paperId: widget.paper.id,
      userId: currentUserId,
      reactionType: type,
    );
  }

  void _addComment(SocialProvider socialProvider, String currentUserId) {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to comment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    socialProvider.addPaperComment(
      paperId: widget.paper.id,
      userId: currentUserId,
      content: content,
    );

    _commentController.clear();
    setState(() => _showCommentField = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _likeComment(PaperComment comment) {
    // This would typically implement comment liking functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment liked!'),
        backgroundColor: Colors.green,
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
