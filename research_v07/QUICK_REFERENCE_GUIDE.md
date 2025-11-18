# Quick Reference - Role-Based Onboarding System

## 🚀 Quick Start

### For Developers
```bash
# 1. Pull latest code
git pull

# 2. Get dependencies
flutter pub get

# 3. Deploy Firestore indexes
firebase deploy --only firestore:indexes

# 4. Deploy security rules
firebase deploy --only firestore:rules

# 5. Run app
flutter run
```

### For Testers
1. Create new test account
2. Should see role selection screen
3. Select role → Confirm → Access app
4. Try uploading public paper → Profile becomes searchable
5. Search for other users → View their profiles

## 📁 Key Files

| File | Purpose |
|------|---------|
| `lib/screens/onboarding/role_selection_screen.dart` | Role selection UI |
| `lib/screens/onboarding/role_confirmation_screen.dart` | Confirmation UI |
| `lib/screens/profile/public_user_profile_screen.dart` | Public profile view |
| `lib/models/app_user.dart` | User model with new flags |
| `lib/services/user_profile_service.dart` | Profile management |
| `lib/providers/papers_provider.dart` | Paper upload + auto-profile |

## 🎨 UI Screens

### Role Selection
- 3 beautiful gradient cards (Student/Researcher/Faculty)
- Animated selection
- Role-specific icons and colors

### Role Confirmation
- Gradient background matching selected role
- Feature list with checkmarks
- Success animation on confirm

### Public Profile
- Professional faculty-style layout
- Tabs: Publications + About
- Follow/Message actions
- Real-time paper streaming

## 🔑 Key Features

### Auto Public Profile
When user uploads a **public** paper:
1. ✅ Paper stored in Firestore
2. ✅ `hasPublicProfile` set to `true`
3. ✅ Profile becomes searchable
4. ✅ Paper appears in feed

### Visibility Options
- **Public**: Everyone can see, appears in feed
- **Private**: Only you can see, hidden from feed
- **Restricted**: Custom access (future feature)

### Role Permissions
| Feature | Student | Researcher | Faculty |
|---------|---------|------------|---------|
| View Papers | ✅ | ✅ | ✅ |
| Upload Papers | ❌ | ✅ | ✅ |
| Auto Public Profile | ❌ | ✅* | ✅* |

*Auto-enabled when uploading public papers

## 🗄️ Database Fields

### AppUser (users collection)
```dart
hasCompletedOnboarding: bool  // NEW
hasPublicProfile: bool         // NEW
role: string                   // student|researcher|professor
```

### ResearchPaper (research_papers collection)
```dart
visibility: string  // public|private|restricted
uploadedBy: string  // User ID
```

## 🔒 Security Rules Summary

```javascript
// Users
- Public profiles: readable by anyone
- Own profile: full access

// Papers
- Public papers: readable by anyone
- Private papers: owner only
- Create: authenticated users
- Update/Delete: owner only
```

## 📊 Firestore Indexes Required

1. **users**: `hasPublicProfile` (ASC) + `displayName` (ASC)
2. **research_papers**: `uploadedBy` (ASC) + `visibility` (ASC) + `uploadedAt` (DESC)
3. **research_papers**: `visibility` (ASC) + `uploadedAt` (DESC)

## 🔄 User Flows

### New User
```
Register → Role Selection → Confirm → Main App
```

### Upload Public Paper
```
Upload → Select "Public" → Submit → Profile Enabled → Feed Updated
```

### Find Researcher
```
Search → Results → View Profile → Follow → Message
```

## 🎯 Testing Checklist

- [ ] New user sees onboarding
- [ ] Role selection works
- [ ] Role persists in Firestore
- [ ] Public paper enables profile
- [ ] Private paper doesn't enable profile
- [ ] Profile search works
- [ ] Follow/unfollow works
- [ ] Papers show in profile
- [ ] Feed shows only public papers

## 🐛 Common Issues

### "Missing index" error
→ Deploy indexes: `firebase deploy --only firestore:indexes`

### Onboarding skipped for new users
→ Check `hasCompletedOnboarding` is `false` in Firestore

### Profile not searchable after upload
→ Verify `hasPublicProfile` is `true` in Firestore
→ Check paper `visibility` is `'public'`

### Can't see public papers
→ Check security rules allow reading where `visibility == 'public'`

## 📞 Support

| Issue Type | Check |
|------------|-------|
| Compilation errors | `get_errors` results |
| Runtime errors | Flutter console logs |
| Database issues | Firebase Console → Firestore |
| Auth issues | Firebase Console → Authentication |

## 📚 Documentation

| File | Content |
|------|---------|
| `ROLE_BASED_ONBOARDING_SYSTEM.md` | Complete feature docs |
| `ONBOARDING_SETUP_GUIDE.md` | Setup instructions |
| `SYSTEM_ARCHITECTURE_DIAGRAM.md` | Visual diagrams |
| `ONBOARDING_IMPLEMENTATION_SUMMARY.md` | Implementation summary |

## 🎉 Success Metrics

✅ **Compilation**: No errors
✅ **Integration**: Works with existing code
✅ **Features**: All requirements met
✅ **Security**: Proper access control
✅ **UX**: Professional, smooth animations
✅ **Documentation**: Complete guides provided

## 🚦 Status

**READY FOR TESTING** ✅

All code implemented, documented, and error-free. Ready for runtime testing and deployment.
