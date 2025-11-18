# Quick Integration Steps for Real-Time Social Media

## Step-by-Step: Make Your Research Feed Real-Time

### Step 1: Add Real-Time Comments (Easiest Integration)

Replace your existing `_showCommentsModal` method in `linkedin_style_papers_screen.dart`:

**FIND THIS:**
```dart
void _showCommentsModal(ResearchPaper paper) {
  final TextEditingController commentController = TextEditingController();
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // ... existing modal code
  );
}
```

**REPLACE WITH THIS:**
```dart
// Add import at top of file
import '../widgets/realtime_comments_widget.dart';

// Replace entire method
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
```

**Result:** Comments now update in real-time! When someone adds a comment, it appears instantly for all users. ✅

---

### Step 2: Add Real-Time Likes

**FIND THIS in `linkedin_style_papers_screen.dart`:**
```dart
void _toggleLike(ResearchPaper paper) async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final socialService = Provider.of<SocialService>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    await socialService.reactToPaper(
      paperId: paper.id,
      userId: currentUser.id,
      reactionType: ReactionType.like,
    );

    setState(() {}); // Refresh UI
  } catch (e) {
    // error handling
  }
}
```

**REPLACE WITH THIS:**
```dart
// Add import at top
import '../services/realtime_social_service.dart';

// Add field in class
final RealtimeSocialService _realtimeSocialService = RealtimeSocialService();

// Update method
void _toggleLike(ResearchPaper paper) async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    // Use real-time service
    await _realtimeSocialService.toggleLike(
      paperId: paper.id,
      userId: currentUser.id,
      userName: currentUser.displayName,
    );

    // No setState needed - Firebase updates automatically!
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  }
}
```

**Result:** Likes update instantly across all devices! No manual refresh needed. ✅

---

### Step 3: Add Real-Time Follow Button

**FIND THIS in `linkedin_style_papers_screen.dart`:**
```dart
void _toggleFollow(String authorId) async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final socialService = Provider.of<SocialService>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    final isFollowing = socialService.isFollowing(currentUser.id, authorId);

    if (isFollowing) {
      await socialService.unfollowUser(currentUser.id, authorId);
    } else {
      await socialService.followUser(currentUser.id, authorId);
    }

    setState(() {}); // Refresh UI
  } catch (e) {
    // error handling
  }
}
```

**REPLACE WITH THIS:**
```dart
void _toggleFollow(String authorId) async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    // Use real-time service
    await _realtimeSocialService.toggleFollow(
      currentUserId: currentUser.id,
      targetUserId: authorId,
    );

    // No setState needed!
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  }
}
```

**Result:** Follow button updates instantly! ✅

---

### Step 4: Show Real-Time Like Count (Optional but Recommended)

Replace your like button widget to show real-time counts:

**FIND WHERE YOU BUILD LIKE BUTTON:**
```dart
Icon(
  isLiked ? Icons.favorite : Icons.favorite_border,
  color: isLiked ? Colors.red : Colors.grey,
  size: 20,
),
Text('${paper.reactions.length}'),
```

**REPLACE WITH STREAMBUILDER:**
```dart
StreamBuilder<DocumentSnapshot>(
  stream: _realtimeSocialService.getPaperStream(paper.id),
  builder: (context, snapshot) {
    // Get real-time data
    final paperData = snapshot.hasData 
        ? snapshot.data!.data() as Map<String, dynamic>? 
        : null;
    
    final reactions = paperData?['reactions'] as Map<String, dynamic>? ?? {};
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final isLiked = currentUser != null && reactions.containsKey(currentUser.id);
    final likeCount = reactions.length;

    return Row(
      children: [
        Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.red : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text('$likeCount'), // Updates in real-time!
      ],
    );
  },
)
```

**Result:** Like count updates instantly as people like the paper! ✅

---

## Complete Example: Real-Time Paper Card

Here's a complete example of a paper card with all real-time features:

```dart
Widget _buildRealtimePaperCard(ResearchPaper paper) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final currentUser = authProvider.currentUser;

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Author Info + Follow Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(paper.author[0]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paper.author,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      paper.category,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Real-time Follow Button
              if (currentUser != null && paper.uploadedBy != currentUser.id)
                StreamBuilder<bool>(
                  stream: _realtimeSocialService.getFollowStatusStream(
                    currentUserId: currentUser.id,
                    targetUserId: paper.uploadedBy,
                  ),
                  builder: (context, snapshot) {
                    final isFollowing = snapshot.data ?? false;
                    return OutlinedButton(
                      onPressed: () => _toggleFollow(paper.uploadedBy),
                      child: Text(isFollowing ? 'Following' : 'Follow'),
                    );
                  },
                ),
            ],
          ),
        ),

        // Paper Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            paper.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action Buttons with Real-Time Counts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Like Button with Real-Time Count
              StreamBuilder<DocumentSnapshot>(
                stream: _realtimeSocialService.getPaperStream(paper.id),
                builder: (context, snapshot) {
                  final paperData = snapshot.hasData
                      ? snapshot.data!.data() as Map<String, dynamic>?
                      : null;

                  final reactions = paperData?['reactions'] as Map<String, dynamic>? ?? {};
                  final isLiked = currentUser != null && reactions.containsKey(currentUser.id);
                  final likeCount = reactions.length;

                  return TextButton.icon(
                    onPressed: () => _toggleLike(paper),
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    label: Text('$likeCount'),
                  );
                },
              ),

              // Comment Button with Real-Time Count
              StreamBuilder<DocumentSnapshot>(
                stream: _realtimeSocialService.getPaperStream(paper.id),
                builder: (context, snapshot) {
                  final paperData = snapshot.hasData
                      ? snapshot.data!.data() as Map<String, dynamic>?
                      : null;

                  final commentsCount = paperData?['commentsCount'] as int? ?? 0;

                  return TextButton.icon(
                    onPressed: () => _showCommentsModal(paper),
                    icon: const Icon(Icons.comment_outlined),
                    label: Text('$commentsCount'),
                  );
                },
              ),

              // Share Button
              TextButton.icon(
                onPressed: () => _sharePaper(paper),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

---

## Quick Test

1. **Add a comment** → Should appear instantly
2. **Like a paper** → Like count updates immediately
3. **Follow a user** → Button changes instantly
4. **Open on two devices** → Changes sync in real-time!

---

## What Makes It Real-Time?

### Before (Manual Refresh):
```dart
Future<List<ResearchPaper>> _loadPapers() async {
  return await paperService.getPapers();
}

FutureBuilder<List<ResearchPaper>>(
  future: _loadPapers(),
  builder: (context, snapshot) {
    // Only updates when future completes
  },
)
```

### After (Real-Time):
```dart
Stream<List<DocumentSnapshot>> _watchPapers() {
  return _realtimeSocialService.getPapersFeedStream(limit: 50);
}

StreamBuilder<List<DocumentSnapshot>>(
  stream: _watchPapers(),
  builder: (context, snapshot) {
    // Updates automatically when data changes!
  },
)
```

**Key Difference:** 
- `Future` = One-time data fetch
- `Stream` = Continuous real-time updates

---

## Troubleshooting

### Comments not showing?
- Check Firebase console → Firestore → papers → {paperId} → comments
- Ensure user is authenticated
- Check firestore rules allow read/write

### Likes not updating?
- Check if `reactions` map exists in Firebase
- Verify user ID is correct
- Check browser console for errors

### Follow not working?
- Ensure user profiles exist in Firestore
- Check `users/{userId}/following` and `users/{userId}/followers` collections
- Verify Firebase rules

---

## Summary

✅ **Step 1:** Replace `_showCommentsModal` with `RealtimeCommentsWidget`
✅ **Step 2:** Update `_toggleLike` to use `RealtimeSocialService`
✅ **Step 3:** Update `_toggleFollow` to use `RealtimeSocialService`
✅ **Step 4:** Wrap counts in `StreamBuilder` for real-time updates

**Result:** Your research feed now works exactly like Instagram, LinkedIn, Twitter with instant real-time updates! 🎉
