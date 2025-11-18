# Firebase Services Quick Reference Guide

## Overview
This guide provides quick examples for using the new Firebase-based paper management services.

---

## 1. Firebase Paper Service

### Upload a New Paper

```dart
import '../services/firebase_paper_service.dart';
import '../models/firebase_paper.dart';
import 'dart:io';

final paperService = FirebasePaperService();

// Step 1: Upload PDF file
final pdfFile = File('/path/to/paper.pdf');
final pdfUrl = await paperService.uploadPaperFile(
  file: pdfFile,
  userId: currentUserId,
  fileName: 'my_research_paper.pdf', // Optional custom name
);

// Step 2: Upload thumbnail (optional)
final thumbnailFile = File('/path/to/thumbnail.jpg');
final thumbnailUrl = await paperService.uploadThumbnail(
  file: thumbnailFile,
  userId: currentUserId,
);

// Step 3: Create paper metadata
final paper = FirebasePaper(
  id: '', // Auto-generated
  title: 'AI in Healthcare Research',
  authors: ['Dr. John Doe', 'Dr. Jane Smith'],
  abstract: 'This paper explores...',
  keywords: ['AI', 'Healthcare', 'Machine Learning'],
  category: 'Computer Science',
  subject: 'Artificial Intelligence',
  faculty: 'Engineering',
  pdfUrl: pdfUrl,
  thumbnailUrl: thumbnailUrl,
  publishedDate: DateTime.now(),
  uploadedAt: DateTime.now(),
  uploadedBy: currentUserId,
  visibility: 'public', // or 'private', 'restricted'
  views: 0,
  downloads: 0,
  likesCount: 0,
  commentsCount: 0,
  sharesCount: 0,
  tags: ['research', 'AI', 'medical'],
  DOI: '10.1234/example.doi',
  journal: 'Journal of AI Research',
  fileSize: pdfFile.lengthSync(),
  fileType: 'pdf',
  description: 'Detailed description...',
);

final paperId = await paperService.createPaper(paper);
print('Paper created with ID: $paperId');
```

### Get Papers (Paginated)

```dart
// Get first page of papers
final papers = await paperService.getPapers(
  limit: 20,
  category: 'Computer Science', // Optional filter
);

// Get next page (pagination)
final morePapers = await paperService.getPapers(
  limit: 20,
  lastDocument: papers.last, // Pass last document for cursor
);
```

### Get Real-time Paper Feed

```dart
// Stream of papers (updates automatically)
Stream<List<FirebasePaper>> paperStream = paperService.getPapersStream(
  limit: 50,
  category: 'Biology',
);

// Use in StreamBuilder
StreamBuilder<List<FirebasePaper>>(
  stream: paperStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final papers = snapshot.data!;
      return ListView.builder(
        itemCount: papers.length,
        itemBuilder: (context, index) {
          final paper = papers[index];
          return PaperCard(paper: paper);
        },
      );
    }
    return CircularProgressIndicator();
  },
);
```

### Search Papers

```dart
// Basic title search
final results = await paperService.searchPapers('machine learning');

// For production, use Algolia (coming in Phase 3)
```

### Get Trending Papers

```dart
// Most viewed papers in last 7 days
final trending = await paperService.getTrendingPapers(limit: 10);
```

### Track Engagement

```dart
// Increment view count
await paperService.incrementViews(paperId);

// Increment download count
await paperService.incrementDownloads(paperId);
```

---

## 2. Comment Service

### Add a Comment

```dart
import '../services/comment_service.dart';
import '../models/firebase_paper.dart';

final commentService = CommentService();

// Create a root-level comment
final comment = PaperComment(
  id: '', // Auto-generated
  paperId: paperId,
  userId: currentUserId,
  userName: 'John Doe',
  userPhotoUrl: userPhotoUrl,
  content: 'Great research! Very insightful findings.',
  timestamp: DateTime.now(),
  likes: 0,
  likedBy: [],
  parentCommentId: null, // null = root comment
);

await commentService.addComment(
  paperId: paperId,
  comment: comment,
);
```

### Add a Reply (Nested Comment)

```dart
// Reply to an existing comment
final reply = PaperComment(
  id: '',
  paperId: paperId,
  userId: currentUserId,
  userName: 'Jane Smith',
  userPhotoUrl: userPhotoUrl,
  content: 'I agree! The methodology is solid.',
  timestamp: DateTime.now(),
  likes: 0,
  likedBy: [],
  parentCommentId: parentCommentId, // ID of comment being replied to
);

await commentService.addComment(
  paperId: paperId,
  comment: reply,
);
```

### Get Comments (Real-time)

```dart
// Stream of comments (auto-updates)
Stream<List<PaperComment>> commentStream = 
  commentService.getCommentsStream(paperId);

// Use in UI
StreamBuilder<List<PaperComment>>(
  stream: commentStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final comments = snapshot.data!;
      return CommentList(comments: comments);
    }
    return CircularProgressIndicator();
  },
);
```

### Get Replies to a Comment

```dart
// Get all replies for a specific comment
final replies = await commentService.getReplies(
  paperId: paperId,
  parentCommentId: commentId,
);
```

### Like/Unlike Comment

```dart
// Like a comment
await commentService.likeComment(
  paperId: paperId,
  commentId: commentId,
  userId: currentUserId,
);

// Unlike a comment
await commentService.unlikeComment(
  paperId: paperId,
  commentId: commentId,
  userId: currentUserId,
);

// Check if user liked
final hasLiked = await commentService.hasUserLikedComment(
  paperId: paperId,
  commentId: commentId,
  userId: currentUserId,
);
```

### Update/Delete Comment

```dart
// Update comment content
await commentService.updateComment(
  paperId: paperId,
  commentId: commentId,
  content: 'Updated comment text',
);

// Delete comment
await commentService.deleteComment(
  paperId: paperId,
  commentId: commentId,
);
```

---

## 3. Reaction Service

### Add a Reaction

```dart
import '../services/reaction_service.dart';

final reactionService = ReactionService();

// Add a 'like' reaction
await reactionService.addReaction(
  paperId: paperId,
  userId: currentUserId,
  type: 'like', // Options: 'like', 'love', 'insightful', 'bookmark'
);
```

### Toggle Reaction (One-Click)

```dart
// Add if not exists, remove if exists
final isReacted = await reactionService.toggleReaction(
  paperId: paperId,
  userId: currentUserId,
  type: 'like',
);

if (isReacted) {
  print('Reaction added');
} else {
  print('Reaction removed');
}
```

### Change Reaction Type

```dart
// Change from 'like' to 'love'
await reactionService.updateReaction(
  paperId: paperId,
  userId: currentUserId,
  newType: 'love',
);
```

### Get User's Reaction

```dart
// Check if user has reacted
final userReaction = await reactionService.getUserReaction(
  paperId: paperId,
  userId: currentUserId,
);

if (userReaction != null) {
  print('User reacted with: ${userReaction.type}');
}
```

### Get Reaction Statistics

```dart
// Get counts by type
final counts = await reactionService.getReactionCounts(paperId);
print('Likes: ${counts['like']}');
print('Loves: ${counts['love']}');
print('Insightful: ${counts['insightful']}');
print('Bookmarks: ${counts['bookmark']}');

// Get users who used specific reaction
final likedBy = await reactionService.getUsersByReactionType(
  paperId: paperId,
  type: 'like',
);
print('${likedBy.length} users liked this paper');
```

---

## 4. Paper Migration Service

### Migrate All Papers

```dart
import '../services/paper_migration_service.dart';

final migrationService = PaperMigrationService();

// Migrate with progress tracking
final successCount = await migrationService.migrateAllPapers(
  userId: currentUserId,
  onProgress: (current, total, status) {
    print('[$current/$total] $status');
    // Update UI progress bar here
  },
);

print('Migrated $successCount papers');
```

### Verify Migration

```dart
// Check migration status
final verification = await migrationService.verifyMigration(currentUserId);

print('Hive papers: ${verification['hive']}');
print('Firestore papers: ${verification['firestore']}');
print('Missing: ${verification['missing']}');
```

### Cleanup After Migration

```dart
// ⚠️ WARNING: This deletes all local Hive papers
await migrationService.cleanupHiveData();
```

### Rollback Migration

```dart
// ⚠️ EXTREME CAUTION: Deletes all Firestore papers
await migrationService.rollbackMigration(currentUserId);
```

---

## 5. Using in UI - Complete Example

### Paper Detail Screen with Comments and Reactions

```dart
import 'package:flutter/material.dart';
import '../services/firebase_paper_service.dart';
import '../services/comment_service.dart';
import '../services/reaction_service.dart';
import '../models/firebase_paper.dart';

class PaperDetailScreen extends StatefulWidget {
  final String paperId;
  
  const PaperDetailScreen({required this.paperId});
  
  @override
  State<PaperDetailScreen> createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends State<PaperDetailScreen> {
  final paperService = FirebasePaperService();
  final commentService = CommentService();
  final reactionService = ReactionService();
  
  @override
  void initState() {
    super.initState();
    // Track view
    paperService.incrementViews(widget.paperId);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Paper Details')),
      body: StreamBuilder<FirebasePaper>(
        stream: paperService.getPaperStream(widget.paperId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          
          final paper = snapshot.data!;
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Paper info
                PaperHeader(paper: paper),
                
                // Reactions
                _buildReactions(paper),
                
                // Comments section
                _buildComments(paper),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildReactions(FirebasePaper paper) {
    return FutureBuilder<PaperReaction?>(
      future: reactionService.getUserReaction(
        paperId: paper.id,
        userId: currentUserId,
      ),
      builder: (context, snapshot) {
        final userReaction = snapshot.data;
        
        return Row(
          children: [
            // Like button
            IconButton(
              icon: Icon(
                userReaction?.type == 'like' 
                  ? Icons.favorite 
                  : Icons.favorite_border,
                color: userReaction?.type == 'like' ? Colors.red : null,
              ),
              onPressed: () async {
                await reactionService.toggleReaction(
                  paperId: paper.id,
                  userId: currentUserId,
                  type: 'like',
                );
                setState(() {});
              },
            ),
            Text('${paper.likesCount}'),
            
            // Bookmark button
            IconButton(
              icon: Icon(
                userReaction?.type == 'bookmark'
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              ),
              onPressed: () async {
                await reactionService.toggleReaction(
                  paperId: paper.id,
                  userId: currentUserId,
                  type: 'bookmark',
                );
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildComments(FirebasePaper paper) {
    return StreamBuilder<List<PaperComment>>(
      stream: commentService.getCommentsStream(paper.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();
        
        final comments = snapshot.data!;
        
        return Column(
          children: [
            Text('${comments.length} Comments'),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return CommentTile(
                  comment: comment,
                  onReply: () => _replyToComment(comment),
                  onLike: () => _likeComment(comment),
                );
              },
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _likeComment(PaperComment comment) async {
    final hasLiked = await commentService.hasUserLikedComment(
      paperId: widget.paperId,
      commentId: comment.id,
      userId: currentUserId,
    );
    
    if (hasLiked) {
      await commentService.unlikeComment(
        paperId: widget.paperId,
        commentId: comment.id,
        userId: currentUserId,
      );
    } else {
      await commentService.likeComment(
        paperId: widget.paperId,
        commentId: comment.id,
        userId: currentUserId,
      );
    }
  }
  
  void _replyToComment(PaperComment parentComment) {
    // Show reply dialog
    showDialog(
      context: context,
      builder: (context) => ReplyDialog(
        onSubmit: (content) async {
          final reply = PaperComment(
            id: '',
            paperId: widget.paperId,
            userId: currentUserId,
            userName: currentUserName,
            userPhotoUrl: currentUserPhoto,
            content: content,
            timestamp: DateTime.now(),
            likes: 0,
            likedBy: [],
            parentCommentId: parentComment.id,
          );
          
          await commentService.addComment(
            paperId: widget.paperId,
            comment: reply,
          );
        },
      ),
    );
  }
}
```

---

## Error Handling Best Practices

```dart
try {
  await paperService.createPaper(paper);
  // Success
} on FirebaseException catch (e) {
  // Firebase-specific errors
  if (e.code == 'permission-denied') {
    print('Permission denied');
  } else if (e.code == 'unavailable') {
    print('Network error');
  }
} catch (e) {
  // General errors
  print('Error: $e');
}
```

---

## Logging

All services include built-in logging using the `logging` package:

```dart
import 'package:logging/logging.dart';

// Enable logging in main.dart
Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) {
  print('${record.level.name}: ${record.time}: ${record.message}');
});
```

---

## Performance Tips

1. **Use Streams for Real-time Data**: Prefer `getPapersStream()` over `getPapers()` for live updates
2. **Implement Pagination**: Always use `limit` parameter to avoid large queries
3. **Cache User Reactions**: Store user's reaction state locally to reduce reads
4. **Batch Operations**: Use `WriteBatch` for multiple operations (already implemented in services)
5. **Optimize Storage**: Compress thumbnails before uploading (<200KB recommended)

---

## Security Notes

- All services require Firebase Authentication
- PDF uploads limited to authenticated users
- Comments/reactions require user to be logged in
- Implement Firestore security rules (see PHASE_1_PROGRESS.md)
- Validate file types before upload (PDF only for papers)

---

## Next Steps

1. Update existing providers to use these services
2. Replace Hive calls with Firebase calls
3. Test real-time updates
4. Run migration for existing users
5. Monitor Firebase usage metrics

---

**For Full Documentation**: See `PHASE_1_PROGRESS.md` and `SCALABLE_PLATFORM_IMPLEMENTATION_PLAN.md`
