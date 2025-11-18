import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/app_user.dart';
import '../models/user.dart'; // For UserRole enum
import '../services/firebase_auth_service.dart';
import '../services/user_profile_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final UserProfileService _profileService = UserProfileService();

  AppUser? _currentUserProfile;
  firebase_auth.User? _firebaseUser;
  bool _isInitialized = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUserProfile;
  firebase_auth.User? get firebaseUser => _firebaseUser;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      debugPrint('🔐 Initializing auth...');

      // Check if there's already a logged-in user
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        debugPrint('👤 Found existing user: ${currentUser.email}');
        _firebaseUser = currentUser;
        _currentUserProfile =
            await _profileService.getUserProfile(currentUser.uid);
        debugPrint('✅ Restored session for user: ${currentUser.email}');
      } else {
        debugPrint('⚠️ No existing user session found');
      }

      // Mark as initialized and notify AFTER checking current user
      _isInitialized = true;
      debugPrint('✅ Auth initialization complete. isLoggedIn: $isLoggedIn');
      notifyListeners();

      // Listen to auth state changes for future updates
      _authService.authStateChanges.listen((firebase_auth.User? user) async {
        debugPrint('🔄 Auth state changed: ${user?.email ?? "logged out"}');
        _firebaseUser = user;
        if (user != null) {
          // Load user profile from Firestore
          _currentUserProfile = await _profileService.getUserProfile(user.uid);
        } else {
          _currentUserProfile = null;
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('❌ Error initializing auth: $e');
      _errorMessage = e.toString();
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _errorMessage = null;
      final credential = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      if (credential?.user != null) {
        _firebaseUser = credential!.user;
        _currentUserProfile =
            await _profileService.getUserProfile(_firebaseUser!.uid);
        notifyListeners();
        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      debugPrint('Login error: $_errorMessage');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Login error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? department,
    String? institution,
    String? designation,
    String? bio,
    UserRole role = UserRole.student,
    List<String> interests = const [],
  }) async {
    try {
      _errorMessage = null;

      // Create Firebase Auth account
      final credential = await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: name,
      );

      if (credential?.user != null) {
        // Create user profile in Firestore
        final newUser = AppUser.fromFirebaseUser(
          credential!.user!.uid,
          email,
          name,
          isEmailVerified: false,
          role: role,
        );

        final userWithDetails = newUser.copyWith(
          department: department,
          institution: institution,
          designation: designation,
          bio: bio,
          interests: interests,
        );

        await _profileService.createUserProfile(userWithDetails);

        // Send email verification
        await credential.user!.sendEmailVerification();

        // Sign out immediately after registration to prevent auto-login
        await _authService.signOut();

        // Don't set _firebaseUser or _currentUserProfile to prevent auto-navigation
        notifyListeners();
        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      debugPrint('Registration error: $_errorMessage');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Registration error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
      _currentUserProfile = null;
      _firebaseUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      if (_firebaseUser == null) return false;

      _errorMessage = null;
      await _profileService.updateUserProfile(_firebaseUser!.uid, updates);

      // Reload user profile
      _currentUserProfile =
          await _profileService.getUserProfile(_firebaseUser!.uid);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Update profile error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _errorMessage = null;
      await _authService.sendPasswordResetEmail(email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      _errorMessage = null;
      await _authService.sendEmailVerification();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      _firebaseUser = _authService.currentUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Reload user error: $e');
    }
  }

  // Social features
  Future<bool> followUser(String userId) async {
    try {
      if (_firebaseUser == null) return false;

      await _profileService.followUser(_firebaseUser!.uid, userId);
      _currentUserProfile =
          await _profileService.getUserProfile(_firebaseUser!.uid);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Follow user error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> unfollowUser(String userId) async {
    try {
      if (_firebaseUser == null) return false;

      await _profileService.unfollowUser(_firebaseUser!.uid, userId);
      _currentUserProfile =
          await _profileService.getUserProfile(_firebaseUser!.uid);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Unfollow user error: $e');
      notifyListeners();
      return false;
    }
  }

  bool isFollowing(String userId) {
    return _currentUserProfile?.following.contains(userId) ?? false;
  }

  // Bookmark management
  Future<bool> bookmarkPaper(String paperId) async {
    try {
      if (_firebaseUser == null) return false;

      await _profileService.bookmarkPaper(_firebaseUser!.uid, paperId);
      _currentUserProfile =
          await _profileService.getUserProfile(_firebaseUser!.uid);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Bookmark paper error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> unbookmarkPaper(String paperId) async {
    try {
      if (_firebaseUser == null) return false;

      await _profileService.unbookmarkPaper(_firebaseUser!.uid, paperId);
      _currentUserProfile =
          await _profileService.getUserProfile(_firebaseUser!.uid);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Unbookmark paper error: $e');
      notifyListeners();
      return false;
    }
  }

  bool isPaperBookmarked(String paperId) {
    return _currentUserProfile?.bookmarkedPapers.contains(paperId) ?? false;
  }

  Future<List<AppUser>> getFollowers([String? userId]) async {
    final uid = userId ?? _firebaseUser?.uid;
    if (uid == null) return [];
    return await _profileService.getFollowers(uid);
  }

  Future<List<AppUser>> getFollowing([String? userId]) async {
    final uid = userId ?? _firebaseUser?.uid;
    if (uid == null) return [];
    return await _profileService.getFollowing(uid);
  }

  Future<List<AppUser>> searchUsers(String query) async {
    return await _profileService.searchUsers(query);
  }

  Future<AppUser?> getUserById(String userId) async {
    return await _profileService.getUserProfile(userId);
  }

  Future<bool> signInWithGoogle() async {
    try {
      _errorMessage = null;
      final credential = await _authService.signInWithGoogle();

      if (credential?.user != null) {
        _firebaseUser = credential!.user;

        // Check if user profile exists, if not create one
        var userProfile =
            await _profileService.getUserProfile(_firebaseUser!.uid);

        if (userProfile == null) {
          // Create new profile for Google sign-in user
          final newUser = AppUser.fromFirebaseUser(
            _firebaseUser!.uid,
            _firebaseUser!.email ?? '',
            _firebaseUser!.displayName ?? 'User',
            isEmailVerified: _firebaseUser!.emailVerified,
            role: UserRole.student,
          );
          await _profileService.createUserProfile(newUser);
          _currentUserProfile = newUser;
        } else {
          _currentUserProfile = userProfile;
        }

        notifyListeners();
        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = _authService.getErrorMessage(e);
      debugPrint('Google Sign-In error: $_errorMessage');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Google Sign-In error: $e');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
