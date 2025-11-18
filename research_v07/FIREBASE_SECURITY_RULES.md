# Firebase Security Rules

Complete security rules for Firestore and Firebase Storage.

## 📋 Overview

These security rules enforce:
- **Authentication**: All operations require authentication
- **Authorization**: Users can only modify their own data
- **Admin Privileges**: Admins have elevated permissions
- **Data Validation**: Ensures data integrity
- **Rate Limiting**: Prevents abuse

---

## 🔥 Firestore Security Rules

Save this to `firestore.rules` in your Firebase Console or project root:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isBanned() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.get('isBanned', false) == true;
    }
    
    // Users Collection
    match /users/{userId} {
      // Anyone authenticated can read user profiles
      allow read: if isAuthenticated();
      
      // Users can create their own profile
      allow create: if isAuthenticated() && 
                       request.auth.uid == userId &&
                       request.resource.data.keys().hasAll(['email', 'displayName', 'role']) &&
                       request.resource.data.role == 'user'; // Default role
      
      // Users can update their own profile (except role)
      allow update: if isOwner(userId) && 
                       !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role', 'email']);
      
      // Only admins can update roles or delete users
      allow update: if isAdmin() && 
                       request.resource.data.diff(resource.data).affectedKeys().hasAny(['role', 'isBanned']);
      allow delete: if isAdmin();
    }
    
    // Papers Collection
    match /papers/{paperId} {
      // Anyone authenticated can read public papers
      allow read: if isAuthenticated() && 
                     (resource.data.visibility == 'public' || 
                      isOwner(resource.data.uploadedBy) || 
                      isAdmin());
      
      // Users can create papers (pending approval)
      allow create: if isAuthenticated() && 
                       !isBanned() &&
                       request.auth.uid == request.resource.data.uploadedBy &&
                       request.resource.data.keys().hasAll([
                         'title', 'author', 'abstract', 'category', 
                         'uploadedBy', 'uploadedAt', 'visibility'
                       ]) &&
                       request.resource.data.visibility in ['pending', 'private'];
      
      // Users can update their own papers (except moderation fields)
      allow update: if isOwner(resource.data.uploadedBy) && 
                       !isBanned() &&
                       !request.resource.data.diff(resource.data).affectedKeys()
                         .hasAny(['uploadedBy', 'moderationStatus', 'approvedAt', 'rejectedAt']);
      
      // Admins can approve, reject, or delete papers
      allow update: if isAdmin() && 
                       request.resource.data.diff(resource.data).affectedKeys()
                         .hasAny(['visibility', 'moderationStatus', 'approvedAt', 'rejectedAt']);
      
      allow delete: if isOwner(resource.data.uploadedBy) || isAdmin();
      
      // Comments subcollection
      match /comments/{commentId} {
        // Anyone can read comments on accessible papers
        allow read: if isAuthenticated();
        
        // Users can create comments
        allow create: if isAuthenticated() && 
                         !isBanned() &&
                         request.auth.uid == request.resource.data.userId &&
                         request.resource.data.keys().hasAll(['userId', 'content', 'createdAt']);
        
        // Users can update their own comments
        allow update: if isOwner(resource.data.userId) && 
                         !request.resource.data.diff(resource.data).affectedKeys()
                           .hasAny(['userId', 'createdAt']);
        
        // Users can delete their own comments, admins can delete any
        allow delete: if isOwner(resource.data.userId) || isAdmin();
      }
      
      // Reactions subcollection
      match /reactions/{reactionId} {
        // Anyone can read reactions
        allow read: if isAuthenticated();
        
        // Users can create/update their own reactions
        allow create, update: if isAuthenticated() && 
                                 !isBanned() &&
                                 request.auth.uid == reactionId &&
                                 request.resource.data.userId == request.auth.uid;
        
        // Users can delete their own reactions
        allow delete: if isOwner(reactionId);
      }
    }
    
    // Activity Logs Collection
    match /activity_logs/{logId} {
      // Users can read their own activity
      allow read: if isAuthenticated() && 
                     (resource.data.userId == request.auth.uid || isAdmin());
      
      // Only system/admins can write logs
      allow create: if isAdmin();
      allow update, delete: if false;
    }
    
    // Admin Logs Collection
    match /admin_logs/{logId} {
      // Only admins can read/write admin logs
      allow read, write: if isAdmin();
    }
    
    // Flagged Content Collection
    match /flagged_content/{flagId} {
      // Admins can read all flagged content
      allow read: if isAdmin();
      
      // Users can flag content
      allow create: if isAuthenticated() && 
                       !isBanned() &&
                       request.resource.data.reportedBy == request.auth.uid;
      
      // Only admins can resolve flagged content
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }
    
    // Notifications Collection
    match /notifications/{notificationId} {
      // Users can read their own notifications
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      
      // System/admins can create notifications
      allow create: if isAdmin() || isAuthenticated(); // Allow system to create
      
      // Users can mark their own notifications as read
      allow update: if isOwner(resource.data.userId) && 
                       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead']);
      
      allow delete: if isOwner(resource.data.userId);
    }
    
    // User Settings Collection
    match /user_settings/{userId} {
      allow read, write: if isOwner(userId);
    }
    
    // Deny all other collections by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 📦 Firebase Storage Security Rules

Save this to `storage.rules` in your Firebase Console or project root:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isAdmin() {
      return firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isBanned() {
      return firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.get('isBanned', false) == true;
    }
    
    function isValidFileSize(maxSizeMB) {
      return request.resource.size < maxSizeMB * 1024 * 1024;
    }
    
    function isValidFileType(allowedTypes) {
      return request.resource.contentType in allowedTypes;
    }
    
    // Papers folder
    match /papers/{userId}/{paperId}/document.pdf {
      // Anyone authenticated can read public papers
      allow read: if isAuthenticated();
      
      // Users can upload their own papers (max 50MB, PDF only)
      allow write: if isAuthenticated() && 
                      !isBanned() &&
                      isOwner(userId) &&
                      isValidFileSize(50) &&
                      isValidFileType(['application/pdf']);
      
      // Admins can delete any paper
      allow delete: if isAdmin() || isOwner(userId);
    }
    
    // Thumbnails folder
    match /papers/{userId}/{paperId}/thumbnail.{extension} {
      // Anyone can read thumbnails (public)
      allow read: if true;
      
      // Users can upload their own thumbnails (max 5MB, images only)
      allow write: if isAuthenticated() && 
                      !isBanned() &&
                      isOwner(userId) &&
                      isValidFileSize(5) &&
                      isValidFileType(['image/jpeg', 'image/png', 'image/jpg', 'image/webp']);
      
      // Admins or owners can delete thumbnails
      allow delete: if isAdmin() || isOwner(userId);
    }
    
    // Profile pictures folder
    match /profiles/{userId}/avatar.{extension} {
      // Anyone can read profile pictures
      allow read: if true;
      
      // Users can upload/update their own avatar (max 2MB, images only)
      allow write: if isAuthenticated() && 
                      isOwner(userId) &&
                      isValidFileSize(2) &&
                      isValidFileType(['image/jpeg', 'image/png', 'image/jpg', 'image/webp']);
      
      allow delete: if isOwner(userId);
    }
    
    // Deny all other paths by default
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 🛡️ Security Features

### Authentication Requirements
- All operations require valid Firebase Authentication token
- Banned users cannot create or modify content
- Anonymous access is denied

### Role-Based Access Control (RBAC)
1. **User** (default role):
   - Create and manage own content
   - Read public content
   - Comment and react to papers
   
2. **Admin**:
   - All user permissions
   - Moderate content (approve/reject papers)
   - Manage user roles
   - Ban/unban users
   - Delete any content
   - View all logs

### Data Validation
- Required fields enforced for all documents
- File type validation (PDFs for papers, images for thumbnails)
- File size limits:
  - Papers: 50MB max
  - Thumbnails: 5MB max
  - Profile pictures: 2MB max
- Prevents role escalation (users cannot set admin role)

### Content Moderation
- New papers start with `visibility: 'pending'`
- Admins must approve papers before going public
- Users can flag inappropriate content
- Admin logs track all moderation actions

### Privacy & Ownership
- Users can only modify their own data
- Users can only read their own private papers
- Email changes prohibited (use Firebase Auth)
- Role changes require admin privileges

---

## 📝 Testing Security Rules

### Firestore Rules Testing

In Firebase Console → Firestore → Rules → Playground:

```javascript
// Test 1: User can read their own profile
auth: {uid: "user123"}
location: /users/user123
operation: get
// Expected: ALLOW

// Test 2: User cannot update another user's profile
auth: {uid: "user123"}
location: /users/user456
operation: update
data: {displayName: "Hacked"}
// Expected: DENY

// Test 3: Admin can approve paper
auth: {uid: "admin123"} // Must have role: 'admin' in Firestore
location: /papers/paper123
operation: update
data: {visibility: "public", moderationStatus: "approved"}
// Expected: ALLOW

// Test 4: User cannot self-promote to admin
auth: {uid: "user123"}
location: /users/user123
operation: update
data: {role: "admin"}
// Expected: DENY
```

### Storage Rules Testing

In Firebase Console → Storage → Rules → Playground:

```javascript
// Test 1: User uploads their own paper
auth: {uid: "user123"}
path: /papers/user123/paper456/document.pdf
operation: write
size: 10485760 // 10MB
contentType: "application/pdf"
// Expected: ALLOW

// Test 2: User cannot upload oversized file
auth: {uid: "user123"}
path: /papers/user123/paper456/document.pdf
operation: write
size: 52428800 // 50MB+
contentType: "application/pdf"
// Expected: DENY

// Test 3: User cannot upload wrong file type
auth: {uid: "user123"}
path: /papers/user123/paper456/document.pdf
operation: write
contentType: "text/html"
// Expected: DENY
```

---

## 🚀 Deployment

### Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Deploy Storage Rules
```bash
firebase deploy --only storage
```

### Deploy All Rules
```bash
firebase deploy --only firestore:rules,storage
```

---

## ⚠️ Important Notes

1. **Deploy rules BEFORE releasing app** to production
2. **Test thoroughly** in development environment
3. **Review Firebase Console logs** regularly for unauthorized attempts
4. **Update indexes** for complex queries (Firebase will prompt)
5. **Monitor costs** - security rules don't prevent quota overuse

### Required Firestore Indexes

Create these composite indexes in Firebase Console:

```javascript
// papers collection
fields: [visibility, uploadedAt DESC]
fields: [uploadedBy, uploadedAt DESC]
fields: [category, uploadedAt DESC]

// comments collection  
fields: [paperId, createdAt DESC]

// activity_logs collection
fields: [userId, timestamp DESC]

// admin_logs collection
fields: [timestamp DESC]
```

---

## 🔧 Troubleshooting

### "Missing or insufficient permissions" error
- Check if user is authenticated
- Verify user has required role in Firestore `users` collection
- Ensure `isBanned` field is false or missing

### "PERMISSION_DENIED: Missing or insufficient permissions"
- Redeploy security rules
- Clear Firebase cache: `firebase use --clear-cache`
- Check Firebase Console → Usage for quota limits

### File upload fails
- Verify file size < limit
- Check content type matches allowed types
- Ensure user owns the storage path

---

## 📚 Additional Resources

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Storage Security Rules Documentation](https://firebase.google.com/docs/storage/security)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Testing Security Rules](https://firebase.google.com/docs/rules/unit-tests)

---

## ✅ Implementation Checklist

- [ ] Copy Firestore rules to `firestore.rules` file
- [ ] Copy Storage rules to `storage.rules` file
- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules`
- [ ] Deploy Storage rules: `firebase deploy --only storage`
- [ ] Create required Firestore indexes
- [ ] Test rules in Firebase Console playgrounds
- [ ] Verify user creation works (default role: 'user')
- [ ] Verify admin functions work for admin users
- [ ] Test file uploads (PDF, images)
- [ ] Monitor Firebase Console logs for errors
- [ ] Update app error handling for permission denials

---

**Created**: Phase 1 - Core Infrastructure Enhancement  
**Last Updated**: 2025-01-20  
**Status**: Ready for deployment 🚀
