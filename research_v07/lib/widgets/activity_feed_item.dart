import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/social_models.dart';
import '../../providers/social_provider.dart';
import '../../theme/app_theme.dart';

class ActivityFeedItemWidget extends StatelessWidget {
  final ActivityFeedItem activity;

  const ActivityFeedItemWidget({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final socialProvider = Provider.of<SocialProvider>(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActivityIcon(socialProvider),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActivityHeader(socialProvider),
                  const SizedBox(height: 4),
                  _buildActivityDescription(),
                ],
              ),
            ),
            Text(
              socialProvider.formatTimeAgo(activity.createdAt),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityIcon(SocialProvider socialProvider) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getActivityColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          socialProvider.getActivityIcon(activity.type),
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildActivityHeader(SocialProvider socialProvider) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.darkSlate,
        ),
        children: [
          TextSpan(
            text: activity.userName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: ' ${_getActivityAction()}',
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDescription() {
    return Text(
      activity.description,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: Colors.grey[600],
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getActivityAction() {
    switch (activity.type) {
      case ActivityType.paperUploaded:
        return 'uploaded a new paper';
      case ActivityType.paperCommented:
        return 'commented on a paper';
      case ActivityType.paperReacted:
        return 'reacted to a paper';
      case ActivityType.discussionCreated:
        return 'started a discussion';
      case ActivityType.discussionCommented:
        return 'commented on a discussion';
      case ActivityType.userFollowed:
        return 'followed a user';
      case ActivityType.paperBookmarked:
        return 'bookmarked a paper';
    }
  }

  Color _getActivityColor() {
    switch (activity.type) {
      case ActivityType.paperUploaded:
        return Colors.blue;
      case ActivityType.paperCommented:
      case ActivityType.discussionCommented:
        return Colors.green;
      case ActivityType.paperReacted:
      case ActivityType.discussionCreated:
        return Colors.orange;
      case ActivityType.userFollowed:
        return Colors.purple;
      case ActivityType.paperBookmarked:
        return Colors.red;
    }
  }
}
