# Role-Based Onboarding & Public Profile System

## Overview
Complete implementation of role-based onboarding with automatic public profile generation for users who upload public research papers.

## Features Implemented

### 1. First-Time Onboarding
- **Role Selection Screen** (`lib/screens/onboarding/role_selection_screen.dart`)
  - Modern animated UI with gradient cards
  - Three roles: Student, Researcher, Faculty Member
  - Each role has distinct color scheme and icon
  - Smooth animations and transitions

- **Role Confirmation Screen** (`lib/screens/onboarding/role_confirmation_screen.dart`)
  - Detailed role description
  - Feature list for each role
  - Confirmation with success animation
  - Updates user profile in Firestore

### 2. User Roles

#### Student
- **Color**: Indigo (#4F46E5)
- **Icon**: School
- **Capabilities**:
  - Browse and search research papers
  - Download papers for offline reading
  - Bookmark papers for later
  - Follow researchers and get updates
  - Participate in discussions
  - Get personalized recommendations

#### Researcher
- **Color**: Cyan (#0891B2)
- **Icon**: Science
- **Capabilities**:
  - Upload research papers in real-time
  - Choose visibility: Public, Private, or Restricted
  - Auto-generated public profile for public papers
  - Collaborate with other researchers
  - Track views and engagement
  - All Student features

#### Faculty Member
- **Color**: Red (#DC2626)
- **Icon**: Account Balance
- **Capabilities**:
  - Complete faculty profile with publications
  - Upload and manage research papers
  - Mentor students and researchers
  - Create public profile visible to all
  - Manage publication visibility
  - Full Researcher and Student features

### 3. Visibility Options

When uploading papers, users can choose:

- **Public**: Paper is visible to all users
  - Automatically appears in Research Feed
  - User's profile becomes searchable
  - Auto-generates public profile
  
- **Private**: Paper is only visible to the uploader
  - Does not appear in feeds
  - No public profile generation
  
- **Restricted**: Paper visible to specific users/institutions
  - Controlled access
  - Conditional profile visibility

### 4. Public Profile System

#### Auto-Generation
- When a user uploads their first public paper:
  - `hasPublicProfile` flag is automatically set to `true`
  - Profile becomes searchable by all users
  - Appears in researcher directories
  
#### Public Profile Screen (`lib/screens/profile/public_user_profile_screen.dart`)
- **Header Section**:
  - Large avatar with role-specific gradient
  - Display name and username
  - Role badge with color coding
  - Bio (if provided)
  - Follow/Message action buttons
  
- **Stats Row**:
  - Public papers count
  - Followers count
  - Following count
  
- **Tabs**:
  - Publications: Lists all public papers with views/downloads
  - About: Institution, department, designation, research interests
  
- **Features**:
  - Real-time paper stream from Firestore
  - Follow/unfollow functionality
  - Message integration (prepared for future)
  - Responsive design with smooth animations

### 5. Database Structure

#### AppUser Model Updates
```dart
final bool hasCompletedOnboarding; // Tracks if user completed onboarding
final bool hasPublicProfile;       // Auto-enabled when uploading public paper
```

#### Firestore Collections
- `users/`: User profiles with role and visibility flags
- `research_papers/`: Papers with visibility field

### 6. Integration Points

#### Authentication Flow
```
Login/Register → Check hasCompletedOnboarding
  ├─ false → Show Role Selection → Role Confirmation → Update Profile
  └─ true → Navigate to Main App
```

#### Paper Upload Flow
```
Upload Paper → Select Visibility
  ├─ Public → Upload → Enable Public Profile → Show in Feed
  ├─ Private → Upload → No Profile Update
  └─ Restricted → Upload → Conditional Updates
```

### 7. Services Enhanced

#### UserProfileService (`lib/services/user_profile_service.dart`)
New methods added:
- `enablePublicProfile(uid)`: Sets hasPublicProfile to true
- `getPublicProfiles()`: Fetches all users with public profiles
- `searchPublicProfiles(query)`: Searches public profiles by name/username

#### PaperUploadService (`lib/providers/papers_provider.dart`)
Enhanced to:
- Check paper visibility after upload
- Auto-enable public profile for public papers
- Handle errors gracefully without failing upload

### 8. UI Components

#### Onboarding Screens
- Gradient backgrounds with role-specific colors
- Animated card selection
- Icon-based role representation
- Feature lists with checkmarks
- Success confirmation dialog

#### Public Profile Screen
- TabBar with Publications and About tabs
- Real-time paper streaming
- Follow/unfollow with optimistic UI updates
- Role-specific color theming
- Stats display with custom formatting

### 9. Navigation & Routes

Main app checks onboarding status in `lib/main.dart`:
```dart
if (auth.isLoggedIn && !auth.currentUser!.hasCompletedOnboarding) {
  return RoleSelectionScreen();
}
```

### 10. Search & Discovery

Users can be discovered through:
- Public profile search
- Paper author links
- Follower/following lists
- Research Feed (via public papers)

## Usage Flow

### For New Users:
1. Register/Login
2. Forced to select role (Student/Researcher/Faculty)
3. Confirm role selection
4. Navigate to main app with role-specific features

### For Researchers Uploading Papers:
1. Create paper with title, abstract, etc.
2. Select visibility: Public/Private/Restricted
3. Upload PDF and optional thumbnail
4. If Public → Profile automatically becomes public
5. Paper appears in Research Feed
6. Other users can find uploader's profile

### For Users Searching:
1. Search for researchers by name
2. View public profiles
3. See all public papers by researcher
4. Follow researchers
5. Send messages (prepared)

## Files Created/Modified

### New Files:
- `lib/screens/onboarding/role_selection_screen.dart`
- `lib/screens/onboarding/role_confirmation_screen.dart`
- `lib/screens/profile/public_user_profile_screen.dart`

### Modified Files:
- `lib/models/app_user.dart` - Added onboarding and public profile flags
- `lib/main.dart` - Added onboarding check in navigation
- `lib/services/user_profile_service.dart` - Added public profile methods
- `lib/providers/papers_provider.dart` - Added auto-enable public profile

## Firebase Requirements

### Firestore Indexes Needed:
```
Collection: users
- hasPublicProfile (ASC), displayName (ASC)

Collection: research_papers
- uploadedBy (ASC), visibility (ASC), uploadedAt (DESC)
```

### Security Rules Enhancement:
```javascript
match /users/{userId} {
  // Public profiles readable by all
  allow read: if resource.data.hasPublicProfile == true;
  // Own profile always readable/writable
  allow read, write: if request.auth.uid == userId;
}

match /research_papers/{paperId} {
  // Public papers readable by all
  allow read: if resource.data.visibility == 'public';
  // Own papers always readable
  allow read: if request.auth.uid == resource.data.uploadedBy;
  // Create if authenticated
  allow create: if request.auth != null;
}
```

## Future Enhancements

1. **Advanced Search**:
   - Filter by role, institution, research interests
   - Sort by paper count, followers, etc.

2. **Profile Customization**:
   - Cover photo
   - Custom themes
   - Featured papers

3. **Analytics Dashboard**:
   - Profile views tracking
   - Paper performance metrics
   - Follower growth charts

4. **Collaboration Features**:
   - Co-author invitations
   - Shared research projects
   - Group discussions

5. **Verification System**:
   - Verified researcher badges
   - Institution verification
   - ORCID integration

## Testing Checklist

- [ ] New user onboarding flow works
- [ ] Role selection persists correctly
- [ ] Public paper upload enables profile
- [ ] Private paper upload doesn't enable profile
- [ ] Public profiles are searchable
- [ ] Follow/unfollow works correctly
- [ ] Paper visibility filters work in feed
- [ ] Profile stats update in real-time
- [ ] Navigation between screens is smooth
- [ ] Error handling works gracefully

## Known Limitations

1. Search currently uses client-side filtering for complex queries
2. Large follower/following lists may have performance issues
3. No pagination on public papers in profile (shows all)
4. Message functionality prepared but not implemented

## Migration Notes

For existing users:
- `hasCompletedOnboarding` defaults to `false`
- Will be forced through onboarding on next login
- `hasPublicProfile` defaults to `false`
- Will be enabled when they upload first public paper

## Summary

This implementation provides a complete role-based system with automatic public profile generation, enabling researchers to showcase their work while maintaining privacy controls. The system integrates seamlessly with the existing paper upload flow and provides a professional, faculty-like profile for all users who choose to share their research publicly.
