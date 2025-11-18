import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/social_models.dart';
import '../../providers/social_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkSlate,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(context),
            child: Text(
              'Mark all read',
              style: GoogleFonts.inter(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<SocialProvider>(
        builder: (context, socialProvider, child) {
          final authProvider = Provider.of<AuthProvider>(context);
          final currentUserId = authProvider.currentUser?.id ?? '';
          final notifications =
              socialProvider.getUserNotifications(currentUserId);

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildNotificationCard(
                  context,
                  notifications[index],
                  socialProvider,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    SocialNotification notification,
    SocialProvider socialProvider,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: notification.isRead ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead
            ? BorderSide.none
            : BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () =>
            _handleNotificationTap(context, notification, socialProvider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead
                ? Colors.white
                : AppTheme.primaryBlue.withOpacity(0.02),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      socialProvider.formatTimeAgo(notification.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.follow:
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      case NotificationType.unfollow:
        icon = Icons.person_remove;
        color = Colors.grey;
        break;
      case NotificationType.paperComment:
        icon = Icons.comment;
        color = Colors.green;
        break;
      case NotificationType.paperReaction:
        icon = Icons.thumb_up;
        color = Colors.orange;
        break;
      case NotificationType.discussionComment:
        icon = Icons.forum;
        color = Colors.purple;
        break;
      case NotificationType.discussionReaction:
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case NotificationType.mention:
        icon = Icons.alternate_email;
        color = Colors.teal;
        break;
      case NotificationType.newPaper:
        icon = Icons.article;
        color = Colors.indigo;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications here when someone\ninteracts with your content',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    SocialNotification notification,
    SocialProvider socialProvider,
  ) {
    // Mark as read
    if (!notification.isRead) {
      socialProvider.markNotificationAsRead(notification.id);
    }

    // Navigate based on notification type
    if (notification.relatedId != null) {
      switch (notification.type) {
        case NotificationType.paperComment:
        case NotificationType.paperReaction:
          // Navigate to paper detail
          break;
        case NotificationType.discussionComment:
        case NotificationType.discussionReaction:
          // Navigate to discussion detail
          break;
        case NotificationType.follow:
          // Navigate to user profile
          break;
        default:
          break;
      }
    }
  }

  void _markAllAsRead(BuildContext context) {
    final socialProvider = Provider.of<SocialProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id ?? '';
    final notifications = socialProvider.getUserNotifications(currentUserId);

    for (final notification in notifications) {
      if (!notification.isRead) {
        socialProvider.markNotificationAsRead(notification.id);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
