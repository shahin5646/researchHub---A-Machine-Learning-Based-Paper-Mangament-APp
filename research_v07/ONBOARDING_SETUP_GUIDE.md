# Quick Setup Guide - Role-Based Onboarding System

## Prerequisites
- Flutter project with Firebase initialized
- Firebase Authentication enabled
- Firestore database created

## Setup Steps

### 1. Deploy Firestore Indexes
```bash
# Navigate to project directory
cd e:\DefenseApp_Versions\October_Updates\Mobile_Versions\research_v07AF6\research_v07

# Deploy indexes
firebase deploy --only firestore:indexes --project your-project-id
```

Or manually create indexes in Firebase Console:
- Go to Firestore → Indexes
- Create composite index for `users`: hasPublicProfile (ASC) + displayName (ASC)
- Create composite index for `research_papers`: uploadedBy (ASC) + visibility (ASC) + uploadedAt (DESC)
- Create composite index for `research_papers`: visibility (ASC) + uploadedAt (DESC)

### 2. Deploy Security Rules
```bash
# Deploy rules
firebase deploy --only firestore:rules --project your-project-id
```

Or manually update in Firebase Console:
- Go to Firestore → Rules
- Copy content from `firestore_rules_onboarding.rules`
- Publish

### 3. Update Existing Users (Optional)
Run this script in Firebase Console or Functions to update existing users:

```javascript
// Cloud Function to migrate existing users
const admin = require('firebase-admin');
admin.initializeApp();

exports.migrateUsers = functions.https.onRequest(async (req, res) => {
  const usersRef = admin.firestore().collection('users');
  const snapshot = await usersRef.get();
  
  const batch = admin.firestore().batch();
  let count = 0;
  
  snapshot.forEach(doc => {
    if (!doc.data().hasOwnProperty('hasCompletedOnboarding')) {
      batch.update(doc.ref, {
        hasCompletedOnboarding: false,
        hasPublicProfile: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      count++;
    }
  });
  
  await batch.commit();
  res.json({ message: `Migrated ${count} users` });
});
```

### 4. Test the Flow

#### Test New User Onboarding:
1. Create a new account
2. Should be redirected to Role Selection screen
3. Select a role (Student/Researcher/Faculty)
4. Confirm selection
5. Should navigate to main app

#### Test Public Paper Upload:
1. Login as a Researcher or Faculty
2. Navigate to Upload Paper screen
3. Fill in paper details
4. Select visibility: "Public"
5. Upload paper
6. Check Firestore: user's `hasPublicProfile` should be `true`
7. Paper should appear in Research Feed

#### Test Public Profile:
1. Search for a user who has uploaded public papers
2. View their public profile
3. Should see:
   - Profile header with avatar
   - Role badge
   - Stats (papers, followers, following)
   - Publications tab with public papers
   - About tab with info

#### Test Private Paper Upload:
1. Upload a paper with visibility: "Private"
2. Check Firestore: user's `hasPublicProfile` should NOT change if it was false
3. Paper should NOT appear in Research Feed

### 5. Configure Feed to Show Public Papers

Update your Research Feed query to filter by visibility:

```dart
FirebaseFirestore.instance
  .collection('research_papers')
  .where('visibility', isEqualTo: 'public')
  .orderBy('uploadedAt', descending: true)
  .limit(50)
  .snapshots()
```

## Verification Checklist

- [ ] Firestore indexes deployed
- [ ] Security rules deployed
- [ ] New users go through onboarding
- [ ] Role selection persists in Firestore
- [ ] Public paper upload enables public profile
- [ ] Public profiles are searchable
- [ ] Research Feed shows only public papers
- [ ] Private papers stay private
- [ ] Follow/unfollow works
- [ ] Profile stats update correctly

## Troubleshooting

### Issue: "Missing index" error
**Solution**: Deploy Firestore indexes using the command above or create manually in console

### Issue: Users can't read public profiles
**Solution**: Check security rules allow reading when `hasPublicProfile == true`

### Issue: Onboarding skipped for existing users
**Solution**: Run migration script to set `hasCompletedOnboarding: false` for existing users

### Issue: Public profile not enabled after upload
**Solution**: Check that `PaperUploadService` is calling `enablePublicProfile()` for public papers

### Issue: Papers not showing in feed
**Solution**: Verify feed query filters by `visibility == 'public'`

## Additional Configuration

### Email Notifications (Optional)
Set up Cloud Functions to notify users when:
- Someone follows them
- Their public paper gets viewed/downloaded
- Someone comments on their paper

### Search Enhancement (Optional)
Integrate Algolia for better search:
- Index public profiles in Algolia
- Enable full-text search by name, institution, interests
- Add filters for role, department, etc.

### Analytics (Optional)
Track onboarding metrics:
- Role distribution (Student/Researcher/Faculty)
- Public vs Private paper ratio
- Profile view counts
- Follow graph analysis

## Support
For issues or questions, refer to:
- `ROLE_BASED_ONBOARDING_SYSTEM.md` - Complete feature documentation
- Firebase Console - Check logs and Firestore data
- Flutter logs - Check for runtime errors

## Next Steps
1. Test thoroughly in development
2. Deploy to staging environment
3. Monitor user feedback
4. Iterate on UI/UX based on usage patterns
5. Consider adding profile customization options
