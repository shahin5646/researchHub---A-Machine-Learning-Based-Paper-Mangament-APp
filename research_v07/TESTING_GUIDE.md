# Testing Guide - Role-Based Onboarding & Public Profiles

## Prerequisites
- Firebase project configured
- Firestore database created
- Firebase CLI installed (`npm install -g firebase-tools`)
- Logged into Firebase CLI (`firebase login`)

## Step 1: Deploy Firestore Indexes

### Option A: Using Firebase CLI (Recommended)
```bash
# Navigate to project root
cd e:\DefenseApp_Versions\October_Updates\Mobile_Versions\research_v07AF6\research_v07

# Initialize Firebase (if not done)
firebase init

# Deploy indexes
firebase deploy --only firestore:indexes
```

### Option B: Manual Creation in Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to Firestore Database → Indexes
4. Create these composite indexes:

**Index 1: Public Profiles Search**
- Collection: `users`
- Fields:
  - `hasPublicProfile` (Ascending)
  - `displayName` (Ascending)
- Query scope: Collection

**Index 2: User Papers by Visibility**
- Collection: `research_papers`
- Fields:
  - `uploadedBy` (Ascending)
  - `visibility` (Ascending)
  - `uploadedAt` (Descending)
- Query scope: Collection

**Index 3: Public Papers Feed**
- Collection: `research_papers`
- Fields:
  - `visibility` (Ascending)
  - `uploadedAt` (Descending)
- Query scope: Collection

## Step 2: Deploy Security Rules

### Option A: Using Firebase CLI (Recommended)
```bash
# Deploy security rules
firebase deploy --only firestore:rules
```

### Option B: Manual Update in Firebase Console
1. Go to Firestore Database → Rules
2. Copy content from `firestore_rules_onboarding.rules`
3. Click "Publish"

**Key Rules to Add:**
```javascript
// Users collection
match /users/{userId} {
  // Public profiles readable by all
  allow read: if resource.data.hasPublicProfile == true;
  // Own profile always readable/writable
  allow read, write: if request.auth.uid == userId;
}

// Research papers collection
match /research_papers/{paperId} {
  // Public papers readable by all
  allow read: if resource.data.visibility == 'public';
  // Own papers always readable
  allow read: if request.auth.uid == resource.data.uploadedBy;
  // Create if authenticated
  allow create: if request.auth != null;
}
```

## Step 3: Run the App

```bash
# Make sure you're in project directory
cd e:\DefenseApp_Versions\October_Updates\Mobile_Versions\research_v07AF6\research_v07

# Run on your device/emulator
flutter run
```

## Step 4: Test New User Onboarding

### Test Case 1: Complete Onboarding Flow
1. **Create New Account**
   - Open app
   - Click "Sign Up"
   - Enter: name, email, password
   - Submit registration

2. **Verify Onboarding Screen Appears**
   - After registration, should immediately see Role Selection Screen
   - Should NOT go to main app

3. **Test Role Selection**
   - Verify 3 role cards appear: Student, Researcher, Faculty Member
   - Tap each card to select
   - Verify visual feedback (gradient, checkmark)
   - Verify "Continue" button activates only when role selected

4. **Test Role Confirmation**
   - Click "Continue"
   - Should navigate to Role Confirmation Screen
   - Verify role-specific gradient background
   - Verify feature list displays correctly
   - Verify "Confirm & Continue" button

5. **Complete Onboarding**
   - Click "Confirm & Continue"
   - Should show success animation
   - Should navigate to main app
   - Should NOT show onboarding again on next login

6. **Verify Database Update**
   - Open Firebase Console → Firestore
   - Find user document in `users` collection
   - Verify:
     - `role` matches selection (e.g., "researcher")
     - `hasCompletedOnboarding` is `true`
     - `hasPublicProfile` is `false` (initially)

### Expected Results:
- ✅ Onboarding shown immediately after registration
- ✅ Role selection works smoothly
- ✅ Confirmation screen displays correctly
- ✅ Database updated with role and onboarding flag
- ✅ Main app loads after confirmation
- ✅ Onboarding NOT shown on subsequent logins

## Step 5: Test Public Paper Upload

### Test Case 2: Upload Public Paper as Researcher
1. **Login as Researcher**
   - Use account created in Test Case 1 (with Researcher role)
   - Or create new account and select "Researcher"

2. **Navigate to Upload Paper**
   - Find "Upload Paper" button/screen in app
   - Should be accessible to Researcher/Faculty roles

3. **Fill Paper Details**
   - Title: "Test Public Research Paper"
   - Abstract: "This is a test paper to verify public profile generation"
   - Keywords: "test, public, research"
   - Category: "Computer Science"
   - **Visibility: Select "Public"** ⚠️ Important!

4. **Upload Paper**
   - Select PDF file
   - Click "Upload"
   - Wait for upload to complete

5. **Verify Database Updates**
   - Open Firebase Console → Firestore
   - Check `research_papers` collection:
     - New paper document created
     - `visibility` field is `"public"`
     - `uploadedBy` matches user ID
   - Check `users` collection:
     - Find your user document
     - **Verify `hasPublicProfile` is now `true`** ✅
     - This should happen automatically!

### Expected Results:
- ✅ Paper uploaded successfully
- ✅ Paper saved with `visibility: "public"`
- ✅ User's `hasPublicProfile` automatically set to `true`
- ✅ Paper appears in Research Feed

### Test Case 3: Upload Private Paper
1. **Upload Another Paper**
   - Same user as above
   - Fill paper details
   - **Visibility: Select "Private"** ⚠️

2. **Verify Behavior**
   - Paper uploads successfully
   - `hasPublicProfile` remains `true` (doesn't revert)
   - Private paper does NOT appear in public feed

### Expected Results:
- ✅ Private paper uploaded
- ✅ Private paper hidden from others
- ✅ Public profile flag unchanged

## Step 6: Test Profile Search & Discovery

### Test Case 4: Search for Public Profiles
1. **Prepare Test Data**
   - Have at least 2-3 users with public papers uploaded
   - Users should have `hasPublicProfile = true`

2. **Implement Search UI** (if not already done)
   ```dart
   // Add to your search screen or create new search screen
   final results = await UserProfileService().searchPublicProfiles(query);
   ```

3. **Test Search**
   - Open search/discover screen
   - Enter user's name in search box
   - Verify only users with `hasPublicProfile = true` appear
   - Users without public papers should NOT appear

4. **View Public Profile**
   - Tap on a user from search results
   - Should navigate to `PublicUserProfileScreen`
   - Verify:
     - Avatar/name displays correctly
     - Role badge shows correct role
     - Stats show: Papers count, Followers, Following
     - Publications tab shows only PUBLIC papers
     - About tab shows institution/department info

5. **Test Follow/Unfollow**
   - Click "Follow" button
   - Verify button changes to "Following"
   - Verify follower count increases
   - Click "Following" to unfollow
   - Verify button changes back to "Follow"

### Expected Results:
- ✅ Search finds users with public profiles
- ✅ Users without public papers not found
- ✅ Public profile displays correctly
- ✅ Only public papers visible in Publications tab
- ✅ Follow/unfollow works correctly

## Step 7: Test Research Feed Visibility

### Test Case 5: Public Papers in Feed
1. **Open Research Feed/Home Screen**
   - Should show feed of research papers

2. **Verify Public Papers Visible**
   - Papers with `visibility: "public"` should appear
   - Papers should show author information
   - Clicking author should navigate to their public profile (if has public profile)

3. **Verify Private Papers Hidden**
   - Your own private papers should appear in "My Papers"
   - Private papers should NOT appear in public feed
   - Other users cannot see your private papers

### Expected Results:
- ✅ Feed shows only public papers
- ✅ Private papers hidden from others
- ✅ Author profiles accessible from papers

## Step 8: Test Edge Cases

### Test Case 6: Student Role Limitations
1. **Create Student Account**
   - Register new user
   - Select "Student" role

2. **Verify Limitations**
   - Upload Paper option should be hidden/disabled
   - Student cannot upload papers
   - Student CAN view all public papers
   - Student CAN follow researchers
   - Student does NOT get public profile

### Test Case 7: Existing Users (Migration)
1. **Login with Old Account** (if any exist)
   - Account created before onboarding feature
   - Should have `hasCompletedOnboarding = false`

2. **Verify Forced Onboarding**
   - Should be redirected to Role Selection Screen
   - Must complete onboarding to access app

## Quick Test Commands

### Check Firebase Connection
```bash
# Test Firestore connection
flutter run --dart-define=FLUTTER_WEB_USE_SKIA=true

# Check Firebase initialization
# Should see "Firebase initialized successfully" in logs
```

### View Firebase Data
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# List projects
firebase projects:list

# Use your project
firebase use your-project-id

# Export Firestore data (optional)
firebase firestore:export gs://your-bucket/exports
```

### Debug Mode
```bash
# Run with debug logging
flutter run --debug

# Check logs for:
# "Enabling public profile for: [userId]"
# "Public profile enabled successfully"
# "Firebase initialized successfully"
```

## Troubleshooting

### Issue: Onboarding Not Showing
**Check:**
- Is user's `hasCompletedOnboarding` false in Firestore?
- Is navigation logic correct in `main.dart`?
- Are there any errors in console?

### Issue: Public Profile Not Enabling
**Check:**
- Is paper visibility set to "public"?
- Check logs for "Enabling public profile for:" message
- Verify `enablePublicProfile()` is being called in `papers_provider.dart`
- Check Firestore security rules allow update

### Issue: Search Returns No Results
**Check:**
- Are Firestore indexes deployed?
- Do users have `hasPublicProfile = true`?
- Check security rules allow reading public profiles
- Check search query syntax

### Issue: Papers Not Showing in Feed
**Check:**
- Is paper `visibility` field set to "public"?
- Is feed query filtering by visibility?
- Check Firestore indexes for papers collection

## Success Checklist

- [ ] Dependencies installed (`flutter pub get`)
- [ ] Firestore indexes deployed
- [ ] Security rules deployed
- [ ] App runs without errors
- [ ] New user onboarding works
- [ ] Role selection persists
- [ ] Public paper upload enables profile
- [ ] Private papers stay private
- [ ] Public profiles searchable
- [ ] Follow/unfollow works
- [ ] Feed shows only public papers
- [ ] Student role limitations enforced

## Next Steps After Testing

1. **UI/UX Improvements**
   - Add search screen if not present
   - Add profile discovery page
   - Enhance paper cards with author links

2. **Features to Add**
   - Profile customization (cover photo, bio editing)
   - Advanced search filters
   - Notifications on follows
   - Message system integration

3. **Performance**
   - Implement pagination for large paper lists
   - Cache frequently accessed profiles
   - Optimize image loading

4. **Analytics**
   - Track onboarding completion rate
   - Monitor role distribution
   - Track public vs private paper ratio

## Support Resources

- **Documentation**: See `ROLE_BASED_ONBOARDING_SYSTEM.md`
- **Architecture**: See `SYSTEM_ARCHITECTURE_DIAGRAM.md`
- **Setup Guide**: See `ONBOARDING_SETUP_GUIDE.md`
- **Firebase Console**: https://console.firebase.google.com/
- **Firestore Rules**: https://firebase.google.com/docs/firestore/security/get-started
