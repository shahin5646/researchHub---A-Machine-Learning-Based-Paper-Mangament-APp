# Firebase Firestore Structure & Security Rules

## Security Rules

Add these rules to Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Helper function to check if user is owner
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    // Papers Collection
    match /papers/{paperId} {
      // Anyone can read public papers
      allow read: if resource.data.visibility == 'public' || isOwner(resource.data.uploadedBy);
      
      // Only authenticated users can create papers
      allow create: if isSignedIn() && request.auth.uid == request.resource.data.uploadedBy;
      
      // Only owner can update/delete their papers
      allow update, delete: if isOwner(resource.data.uploadedBy);
      
      // Comments subcollection
      match /comments/{commentId} {
        // Anyone can read comments on public papers
        allow read: if true;
        
        // Authenticated users can create comments
        allow create: if isSignedIn() && request.auth.uid == request.resource.data.userId;
        
        // Only comment owner can update/delete
        allow update, delete: if isOwner(resource.data.userId);
      }
    }
    
    // Users Collection
    match /users/{userId} {
      // Anyone can read public user profiles
      allow read: if true;
      
      // Only user can update their own profile
      allow write: if isOwner(userId);
      
      // Following subcollection
      match /following/{targetUserId} {
        allow read: if true;
        allow write: if isOwner(userId);
      }
      
      // Followers subcollection
      match /followers/{followerId} {
        allow read: if true;
        allow write: if isOwner(followerId);
      }
      
      // Bookmarks subcollection
      match /bookmarks/{paperId} {
        allow read, write: if isOwner(userId);
      }
    }
    
    // Notifications Collection
    match /notifications/{notificationId} {
      allow read: if isOwner(resource.data.userId);
      allow write: if isSignedIn();
    }
  }
}
```

## Sample Data Structure

See full details in REALTIME_SOCIAL_MEDIA_GUIDE.md

### Papers Example:
```
papers/paper_abc123
  ├── title, author, category
  ├── reactions: { userId: {type, timestamp} }
  ├── commentsCount, likesCount
  └── comments/comment_xyz789
        ├── content, userName
        └── timestamp, likes
```

### Users Example:
```
users/user_123
  ├── displayName, email, role
  ├── followersCount, followingCount
  ├── following/user_456
  ├── followers/user_789
  └── bookmarks/paper_abc123
```

## Required Indexes

Create in Firebase Console → Firestore → Indexes:

1. **Papers by visibility & date**: `visibility ASC, uploadedAt DESC`
2. **Papers by author & date**: `uploadedBy ASC, uploadedAt DESC`
3. **Comments by timestamp**: `timestamp ASC` (Collection group)

## Quick Start

1. Copy security rules to Firebase Console
2. Create indexes
3. Use RealtimeSocialService in your app
4. Real-time updates work automatically!

See QUICK_REALTIME_INTEGRATION.md for code examples.
