import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/social_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class FollowButton extends StatefulWidget {
  final String targetUserId;
  final String? targetUserName;
  final bool compact;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.targetUserName,
    this.compact = false,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context);
        final currentUserId = authProvider.currentUser?.id ?? '';

        // Don't show follow button for self
        if (currentUserId == widget.targetUserId || currentUserId.isEmpty) {
          return const SizedBox.shrink();
        }

        final isFollowing =
            socialProvider.isFollowing(currentUserId, widget.targetUserId);

        if (widget.compact) {
          return _buildCompactButton(
              isFollowing, socialProvider, currentUserId);
        } else {
          return _buildFullButton(isFollowing, socialProvider, currentUserId);
        }
      },
    );
  }

  Widget _buildCompactButton(
      bool isFollowing, SocialProvider socialProvider, String currentUserId) {
    return InkWell(
      onTap: _isLoading
          ? null
          : () => _toggleFollow(socialProvider, currentUserId, isFollowing),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryBlue,
            width: 1,
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFollowing ? Colors.white : AppTheme.primaryBlue,
                  ),
                ),
              )
            : Text(
                isFollowing ? 'Following' : 'Follow',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isFollowing ? Colors.white : AppTheme.primaryBlue,
                ),
              ),
      ),
    );
  }

  Widget _buildFullButton(
      bool isFollowing, SocialProvider socialProvider, String currentUserId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading
            ? null
            : () => _toggleFollow(socialProvider, currentUserId, isFollowing),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFollowing ? Colors.grey[100] : AppTheme.primaryBlue,
          foregroundColor: isFollowing ? Colors.grey[700] : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isFollowing
                ? BorderSide(color: Colors.grey[300]!)
                : BorderSide.none,
          ),
        ),
        icon: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFollowing ? Colors.grey[700]! : Colors.white,
                  ),
                ),
              )
            : Icon(
                isFollowing ? Icons.person_remove : Icons.person_add,
                size: 18,
              ),
        label: Text(
          isFollowing ? 'Unfollow' : 'Follow',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFollow(
    SocialProvider socialProvider,
    String currentUserId,
    bool isFollowing,
  ) async {
    setState(() => _isLoading = true);

    try {
      bool success;
      if (isFollowing) {
        success = await socialProvider.unfollowUser(
            currentUserId, widget.targetUserId);
      } else {
        success =
            await socialProvider.followUser(currentUserId, widget.targetUserId);
      }

      if (success && mounted) {
        final action = isFollowing ? 'unfollowed' : 'followed';
        final userName = widget.targetUserName ?? 'user';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You $action $userName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to ${isFollowing ? 'unfollow' : 'follow'} user'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
