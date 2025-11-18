# Real-Time Social Media Features Implementation Guide

## Overview
This guide shows how to integrate real-time Firebase functionality into your research feed to make it work like a real social media platform (Instagram, LinkedIn, etc.).

## What's Been Added

### 1. RealtimeSocialService (`lib/services/realtime_social_service.dart`)
A complete Firebase-powered real-time service that provides:

- **Real-time Likes**: Instant updates when users like/unlike papers
- **Real-time Comments**: Live comment feed with immediate updates
- **Real-time Follow/Unfollow**: Instant follow status updates
- **Real-time Feeds**: Papers stream that updates automatically
- **Real-time Bookmarks**: Instant bookmark status tracking

**Key Features:**
- Uses Firebase Firestore `snapshots()` for real-time streams
- Optimistic UI updates (immediate feedback)
- Automatic synchronization across all devices
- No manual refresh needed

### 2. RealtimeCommentsWidget (`lib/widgets/realtime_comments_widget.dart`)
A beautiful, real-time comments modal that:

- Shows comments instantly as they're added
- Auto-scrolls to new comments
- Displays user avatars and timestamps
- Works exactly like Instagram/LinkedIn comments
- No refresh needed - updates happen automatically

## How to Use in Your App

### Option 1: Add Real-Time to Existing LinkedIn Feed

Update `linkedin_style_papers_screen.dart` to use real-time features:

```dart
// Add import
import '../services/realtime_social_service.dart';
import '../widgets/realtime_comments_widget.dart';

// In your state class
final RealtimeSocialService _realtimeSocialService = RealtimeSocialService();

// Replace _showCommentsModal method
void _showCommentsModal(ResearchPaper paper) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RealtimeCommentsWidget(
      paperId: paper.id,
      paperTitle: paper.title,
    ),
  );
}

// Update _toggleLike method for real-time
void _toggleLike(ResearchPaper paper) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final currentUser = authProvider.currentUser;
  
  if (currentUser == null) return;

  // Optimistic update - UI feels instant!
  await _realtimeSocialService.toggleLike(
    paperId: paper.id,
    userId: currentUser.id,
    userName: currentUser.displayName,
  );
  
  // No setState needed - Firebase updates automatically!
}

// Add real-time like count display
Widget _buildLikeButton(ResearchPaper paper) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final currentUser = authProvider.currentUser;
  
  if (currentUser == null) {
    return const SizedBox();
  }

  return StreamBuilder<DocumentSnapshot>(
    stream: _realtimeSocialService.getPaperStream(paper.id),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return _buildStaticLikeButton(paper);
      }

      final paperData = snapshot.data!.data() as Map<String, dynamic>?;
      final reactions = paperData?['reactions'] as Map<String, dynamic>? ?? {};
      final isLiked = reactions.containsKey(currentUser.id);
      final likeCount = reactions.length;

      return InkWell(
        onTap: () => _toggleLike(paper),
        child: Row(
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text('$likeCount'),
          ],
        ),
      );
    },
  );
}
```

### Option 2: Build New Real-Time Feed Screen

Create a completely new feed screen with real-time features:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/realtime_social_service.dart';
import '../widgets/realtime_comments_widget.dart';

class RealTimeFeedScreen extends StatelessWidget {
  final RealtimeSocialService _socialService = RealtimeSocialService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Research Feed')),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _socialService.getPapersFeedStream(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No papers yet'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final paperDoc = snapshot.data![index];
              final paperData = paperDoc.data() as Map<String, dynamic>;
              
              return _buildPaperCard(
                context,
                paperDoc.id,
                paperData,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPaperCard(
    BuildContext context,
    String paperId,
    Map<String, dynamic> data,
  ) {
    final title = data['title'] as String? ?? '';
    final author = data['uploadedBy'] as String? ?? '';
    final reactions = data['reactions'] as Map<String, dynamic>? ?? {};
    final commentsCount = data['commentsCount'] as int? ?? 0;

    return Card(
      margin: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author info
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Action buttons (Like, Comment, Share)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Like button with real-time count
                StreamBuilder<DocumentSnapshot>(
                  stream: _socialService.getPaperStream(paperId),
                  builder: (context, snapshot) {
                    final reactions = snapshot.hasData
                        ? (snapshot.data!.data() as Map<String, dynamic>?)?['reactions'] as Map<String, dynamic>? ?? {}
                        : <String, dynamic>{};
                    
                    return TextButton.icon(
                      onPressed: () {
                        // Add current user ID here
                        _socialService.toggleLike(
                          paperId: paperId,
                          userId: 'currentUserId',
                          userName: 'Current User',
                        );
                      },
                      icon: Icon(Icons.favorite_border),
                      label: Text('${reactions.length}'),
                    );
                  },
                ),

                // Comment button
                TextButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => RealtimeCommentsWidget(
                        paperId: paperId,
                        paperTitle: title,
                      ),
                    );
                  },
                  icon: Icon(Icons.comment_outlined),
                  label: Text('$commentsCount'),
                ),

                // Share button
                TextButton.icon(
                  onPressed: () => _socialService.sharePaper(paperId),
                  icon: Icon(Icons.share_outlined),
                  label: Text('Share'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Firebase Database Structure

### Papers Collection
```
papers/
  {paperId}/
    title: string
    uploadedBy: string
    uploadedAt: timestamp
    visibility: string
    commentsCount: number
    likesCount: number
    sharesCount: number
    reactions:
      {userId}: {
        userId: string
        userName: string
        type: string
        createdAt: timestamp
      }
```

### Comments Subcollection
```
papers/
  {paperId}/
    comments/
      {commentId}/
        id: string
        paperId: string
        userId: string
        userName: string
        userPhotoUrl: string?
        content: string
        timestamp: timestamp
        likes: number
        likedBy: array
```

### User Following/Followers
```
users/
  {userId}/
    followingCount: number
    followersCount: number
    bookmarksCount: number
    following/
      {targetUserId}/
        userId: string
        timestamp: timestamp
    followers/
      {followerUserId}/
        userId: string
        timestamp: timestamp
    bookmarks/
      {paperId}/
        paperId: string
        timestamp: timestamp
```

## Key Features Explained

### 1. Real-Time Likes
```dart
// When user clicks like:
await _realtimeSocialService.toggleLike(
  paperId: paper.id,
  userId: currentUser.id,
  userName: currentUser.displayName,
);

// UI updates automatically via StreamBuilder
StreamBuilder<DocumentSnapshot>(
  stream: _realtimeSocialService.getPaperStream(paperId),
  builder: (context, snapshot) {
    // Automatically rebuilds when like count changes!
  },
)
```

### 2. Real-Time Comments
```dart
// Comments appear instantly for all users
StreamBuilder<List<Map<String, dynamic>>>(
  stream: _realtimeSocialService.getCommentsStream(paperId),
  builder: (context, snapshot) {
    final comments = snapshot.data ?? [];
    // List updates automatically when new comments added!
  },
)
```

### 3. Real-Time Follow Status
```dart
// Follow button updates instantly
StreamBuilder<bool>(
  stream: _realtimeSocialService.getFollowStatusStream(
    currentUserId: currentUser.id,
    targetUserId: author.id,
  ),
  builder: (context, snapshot) {
    final isFollowing = snapshot.data ?? false;
    return ElevatedButton(
      onPressed: () => _realtimeSocialService.toggleFollow(
        currentUserId: currentUser.id,
        targetUserId: author.id,
      ),
      child: Text(isFollowing ? 'Following' : 'Follow'),
    );
  },
)
```

## Benefits of This Implementation

✅ **Instant Updates**: No refresh needed - changes appear immediately
✅ **Multi-Device Sync**: Updates sync across all devices in real-time
✅ **Scalable**: Firebase handles millions of concurrent users
✅ **Reliable**: Built-in offline support and data persistence
✅ **Professional**: Works like Instagram, LinkedIn, Twitter, etc.
✅ **Easy to Use**: Simple API with StreamBuilder integration

## Testing Real-Time Features

1. Open app on two devices/emulators
2. Like a paper on device 1
3. See like count update immediately on device 2
4. Add comment on device 2
5. Comment appears instantly on device 1
6. Follow a user on device 1
7. Follow button updates on device 2

## Performance Tips

1. **Limit Query Results**: Use `.limit()` to avoid loading too many documents
2. **Use Pagination**: Load more papers as user scrolls
3. **Index Fields**: Create Firestore indexes for common queries
4. **Cache Data**: Enable Firestore persistence for offline support

```dart
// Enable offline persistence (in main.dart)
await FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

## Next Steps

1. ✅ Created RealtimeSocialService with all social features
2. ✅ Created RealtimeCommentsWidget for live comments
3. 📝 Integrate into existing LinkedIn feed screen
4. 📝 Add real-time follow buttons
5. 📝 Add real-time notifications
6. 📝 Add real-time activity feed
7. 📝 Test on multiple devices

## Migration from Hive to Firebase

Currently your app uses Hive (local storage). To fully enable real-time features:

1. **Papers**: Already in Firebase ✅
2. **Comments**: Use CommentService (already Firebase) ✅
3. **Likes/Reactions**: Update SocialService to use RealtimeSocialService
4. **Follow/Unfollow**: Migrate to Firebase using RealtimeSocialService
5. **Notifications**: Use Firebase Cloud Messaging (FCM)

## Conclusion

You now have a complete real-time social media system! The RealtimeSocialService and RealtimeCommentsWidget provide everything you need for Instagram/LinkedIn-style real-time interactions.

Just integrate them into your existing screens using the examples above, and your research feed will work like a professional social media platform with instant updates across all devices!
