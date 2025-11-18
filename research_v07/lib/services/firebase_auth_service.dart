import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Logger _logger = Logger('FirebaseAuthService');

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _logger.info('Attempting to sign up user: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Send email verification
      await credential.user?.sendEmailVerification();

      _logger.info('User signed up successfully: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      _logger.severe('Sign up error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.severe('Unexpected sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('Attempting to sign in user: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _logger.info('User signed in successfully: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      _logger.severe('Sign in error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.severe('Unexpected sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _logger.info('Signing out user');
      await _auth.signOut();
      _logger.info('User signed out successfully');
    } catch (e) {
      _logger.severe('Sign out error: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _logger.info('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      _logger.info('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      _logger.severe('Password reset error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.severe('Unexpected password reset error: $e');
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        _logger.info('Sending email verification');
        await user.sendEmailVerification();
        _logger.info('Email verification sent successfully');
      }
    } catch (e) {
      _logger.severe('Email verification error: $e');
      rethrow;
    }
  }

  // Reload user to get updated email verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      _logger.severe('Reload user error: $e');
    }
  }

  // Update user display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await reloadUser();
    } catch (e) {
      _logger.severe('Update display name error: $e');
      rethrow;
    }
  }

  // Update user photo URL
  Future<void> updatePhotoURL(String photoURL) async {
    try {
      await _auth.currentUser?.updatePhotoURL(photoURL);
      await reloadUser();
    } catch (e) {
      _logger.severe('Update photo URL error: $e');
      rethrow;
    }
  }

  // Update user email
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.updateEmail(newEmail);
      await reloadUser();
    } catch (e) {
      _logger.severe('Update email error: $e');
      rethrow;
    }
  }

  // Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      _logger.severe('Update password error: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      _logger.info('Deleting user account');
      await _auth.currentUser?.delete();
      _logger.info('User account deleted successfully');
    } catch (e) {
      _logger.severe('Delete account error: $e');
      rethrow;
    }
  }

  // Get error message from FirebaseAuthException
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      case 'requires-recent-login':
        return 'Please log in again to perform this action.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      _logger.info('Attempting Google Sign-In');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _logger.info('Google Sign-In cancelled by user');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      _logger.info('Google Sign-In successful: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.severe('Google Sign-In error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.severe('Unexpected Google Sign-In error: $e');
      rethrow;
    }
  }

  // Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _logger.info('Google Sign-Out successful');
    } catch (e) {
      _logger.severe('Google Sign-Out error: $e');
      rethrow;
    }
  }
}
