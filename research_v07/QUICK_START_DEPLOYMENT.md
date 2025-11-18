# Quick Start Guide - Deployment & Testing

## Prerequisites Setup

### 1. Install Firebase CLI (if not installed)
```powershell
npm install -g firebase-tools
```

### 2. Login to Firebase
```powershell
firebase login
```

### 3. Initialize Firebase in Project
```powershell
# Navigate to project directory
cd e:\DefenseApp_Versions\October_Updates\Mobile_Versions\research_v07AF6\research_v07

# Initialize Firestore
firebase init firestore
```

**During initialization:**
- Select your Firebase project
- Accept default file names (firestore.rules, firestore.indexes.json)
- Don't overwrite if files exist

## Deployment Steps

### Option 1: Automated Deployment (Recommended)
```powershell
# Run deployment script
.\deploy_firebase.ps1
```

The script will:
1. Check Firebase CLI installation
2. Deploy Firestore indexes
3. Deploy security rules
4. Guide you through the process

### Option 2: Manual Deployment

#### Deploy Indexes
```powershell
# Copy indexes
Copy-Item firestore_indexes_onboarding.json firestore.indexes.json

# Deploy
firebase deploy --only firestore:indexes
```

#### Deploy Rules
```powershell
# Copy rules
Copy-Item firestore_rules_onboarding.rules firestore.rules

# Deploy
firebase deploy --only firestore:rules
```

### Option 3: Firebase Console (No CLI needed)

#### Deploy Indexes Manually
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Firestore Database → Indexes
4. Click "Add Index"
5. Create these 3 indexes:

**Index 1: Public Profiles**
- Collection ID: `users`
- Fields to index:
  - `hasPublicProfile` - Ascending
  - `displayName` - Ascending
- Query scope: Collection
- Click "Create"

**Index 2: User Papers**
- Collection ID: `research_papers`
- Fields to index:
  - `uploadedBy` - Ascending
  - `visibility` - Ascending
  - `uploadedAt` - Descending
- Query scope: Collection
- Click "Create"

**Index 3: Public Feed**
- Collection ID: `research_papers`
- Fields to index:
  - `visibility` - Ascending
  - `uploadedAt` - Descending
- Query scope: Collection
- Click "Create"

#### Deploy Rules Manually
1. Go to Firestore Database → Rules
2. Copy entire content from `firestore_rules_onboarding.rules`
3. Paste into the editor
4. Click "Publish"

## Testing Implementation

### Quick Test: New User Onboarding

```powershell
# 1. Run the app
flutter run

# 2. Create new account
#    - Click "Sign Up"
#    - Enter name, email, password
#    - Submit

# 3. Verify onboarding
#    - Should see Role Selection Screen
#    - Select "Researcher"
#    - Confirm role
#    - Should navigate to main app

# 4. Check Firestore
#    - Open Firebase Console
#    - Firestore → users collection
#    - Find your user
#    - Verify: hasCompletedOnboarding = true
#    - Verify: hasPublicProfile = false (initially)
```

### Quick Test: Public Profile Generation

```dart
// 1. Login as researcher
// 2. Navigate to Upload Paper screen
// 3. Fill paper details:
//    - Title: "Test Paper"
//    - Abstract: "Test abstract"
//    - Visibility: "Public" ← Important!
// 4. Upload paper
// 5. Check Firestore:
//    - users/{userId}/hasPublicProfile should be TRUE
//    - research_papers/{paperId}/visibility should be "public"
```

### Quick Test: Profile Search

```dart
// In your app, add search functionality:

// Example search screen code:
final userService = UserProfileService();
final results = await userService.searchPublicProfiles('John');

// Display results in ListView
ListView.builder(
  itemCount: results.length,
  itemBuilder: (context, index) {
    final user = results[index];
    return ListTile(
      title: Text(user.displayName),
      subtitle: Text(user.role.name),
      onTap: () {
        // Navigate to public profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PublicUserProfileScreen(
              userId: user.uid,
              user: user,
            ),
          ),
        );
      },
    );
  },
);
```

## Verification Checklist

After deployment, verify:

- [ ] **Firebase CLI installed**: Run `firebase --version`
- [ ] **Logged into Firebase**: Run `firebase login:list`
- [ ] **Indexes deployed**: Check Firebase Console → Indexes
- [ ] **Rules deployed**: Check Firebase Console → Rules
- [ ] **App runs**: Run `flutter run`
- [ ] **Onboarding works**: Create new account
- [ ] **Role persists**: Check Firestore after role selection
- [ ] **Public profile enables**: Upload public paper
- [ ] **Search works**: Find users with public profiles
- [ ] **Feed shows public papers**: Only public papers visible

## Common Issues & Solutions

### Issue: "Firebase command not found"
```powershell
# Solution: Install Firebase CLI
npm install -g firebase-tools

# Verify installation
firebase --version
```

### Issue: "Not logged in to Firebase"
```powershell
# Solution: Login
firebase login

# Check login status
firebase login:list
```

### Issue: "Index already exists"
```
# Solution: Indexes may already exist
# Check Firebase Console → Indexes
# Delete old indexes if needed
```

### Issue: "Permission denied" during deployment
```
# Solution: Re-authenticate
firebase logout
firebase login
firebase use --add  # Select your project
```

### Issue: Onboarding not showing
```
# Check: Is hasCompletedOnboarding false in Firestore?
# Check: Is navigation logic correct in main.dart?
# Solution: Manually set field to false for testing:
# Firestore → users → {userId} → Edit → hasCompletedOnboarding = false
```

### Issue: Public profile not enabling
```
# Check console logs for:
# "Enabling public profile for: [userId]"
# "Public profile enabled successfully"

# If missing, check:
# 1. Is visibility = "public" in upload screen?
# 2. Is PaperUploadService calling enablePublicProfile()?
# 3. Do security rules allow updates?
```

## Quick Commands Reference

```powershell
# Install dependencies
flutter pub get

# Check Firebase status
firebase projects:list
firebase use

# Deploy indexes only
firebase deploy --only firestore:indexes

# Deploy rules only
firebase deploy --only firestore:rules

# Deploy both
firebase deploy --only firestore

# Run app
flutter run

# Run with verbose logging
flutter run --verbose

# Check for errors
flutter doctor
```

## Next Steps

1. ✅ Deploy Firestore configuration
2. ✅ Test onboarding flow
3. ✅ Test public paper upload
4. ✅ Test profile search
5. ⏭️ Implement search UI (if not present)
6. ⏭️ Add profile discovery page
7. ⏭️ Test on real devices

## Need Help?

- **Full Testing Guide**: See `TESTING_GUIDE.md`
- **Feature Documentation**: See `ROLE_BASED_ONBOARDING_SYSTEM.md`
- **Architecture**: See `SYSTEM_ARCHITECTURE_DIAGRAM.md`
- **Firebase Docs**: https://firebase.google.com/docs
- **Firestore Rules**: https://firebase.google.com/docs/firestore/security
