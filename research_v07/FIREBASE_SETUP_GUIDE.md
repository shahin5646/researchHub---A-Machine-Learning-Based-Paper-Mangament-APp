# Firebase Setup Guide

## ✅ Completed Steps

1. ✅ Added Firebase dependencies to `pubspec.yaml`
2. ✅ Created `firebase_options.dart` template file
3. ✅ Updated `main.dart` to initialize Firebase

## 🔧 Required Steps to Complete Setup

### Step 1: Authenticate with Firebase CLI

Open PowerShell and run:
```bash
firebase login
```
This will open a browser window for you to sign in with your Google account.

### Step 2: Configure Firebase with FlutterFire CLI

Navigate to your project directory and run:
```bash
cd e:\DefenseApp_Versions\October_Updates\Mobile_Versions\research_v07AF6\research_v07
flutterfire configure --project=research-hub-d9034
```

This command will:
- Connect to your Firebase project `research-hub-d9034`
- Generate proper API keys for all platforms
- Update `firebase_options.dart` with actual configuration
- Configure Android (`google-services.json`) and iOS (`GoogleService-Info.plist`) automatically

### Step 3: Verify Platform-Specific Setup

#### Android Setup
The FlutterFire CLI should automatically:
- Add `google-services.json` to `android/app/`
- Update `android/build.gradle` with Google Services plugin
- Update `android/app/build.gradle` with the plugin

If not, manually add to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

And to `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

#### iOS Setup
The FlutterFire CLI should automatically:
- Add `GoogleService-Info.plist` to `ios/Runner/`
- Update iOS project settings

### Step 4: Enable Firebase Services

Go to [Firebase Console](https://console.firebase.google.com/project/research-hub-d9034):

1. **Authentication**
   - Navigate to Authentication → Sign-in method
   - Enable Email/Password authentication
   - Enable Google Sign-In (optional)

2. **Firestore Database**
   - Navigate to Firestore Database
   - Create database (start in test mode for development)
   - Set up security rules

3. **Storage**
   - Navigate to Storage
   - Set up Cloud Storage bucket
   - Configure security rules

4. **Cloud Messaging (Optional)**
   - Navigate to Cloud Messaging
   - Get server key for notifications

### Step 5: Update Security Rules

#### Firestore Rules (Basic)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /papers/{paperId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == request.resource.data.authorId;
    }
  }
}
```

#### Storage Rules (Basic)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /papers/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 📱 Testing Firebase Connection

After completing the setup, run:
```bash
flutter run
```

Check the console for: `Firebase initialized successfully`

## 🔥 Firebase Services Available

Your app now has access to:
- 🔐 **Firebase Authentication** - User sign up/sign in
- 📦 **Cloud Firestore** - Real-time database
- 📁 **Cloud Storage** - File storage for PDFs and images
- 🔔 **Cloud Messaging** - Push notifications

## 📝 Next Steps

1. Implement authentication in your `AuthProvider`
2. Replace local `PaperService` methods with Firestore calls
3. Update file uploads to use Firebase Storage
4. Set up push notifications for social features

## 🆘 Troubleshooting

If you see "Default FirebaseOptions have not been configured":
- Run `flutterfire configure` again
- Make sure you're in the correct project directory
- Verify `firebase_options.dart` has actual API keys (not placeholders)

If authentication fails:
- Check Firebase Console → Authentication is enabled
- Verify your app's SHA-1 key is registered (Android)
- Verify bundle ID matches (iOS)

For SHA-1 fingerprint (Android):
```bash
cd android
./gradlew signingReport
```
