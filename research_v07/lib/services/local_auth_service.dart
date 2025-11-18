import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_models.dart';

class LocalAuthService {
  static const String _usersBoxName = 'users';
  static const String _currentUserKey = 'current_user_id';

  late Box<User> _usersBox;
  User? _currentUser;

  // Singleton pattern
  static final LocalAuthService _instance = LocalAuthService._internal();
  factory LocalAuthService() => _instance;
  LocalAuthService._internal();

  // Initialize the service
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(UserRoleAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(UserPreferencesAdapter());
    }

    _usersBox = await Hive.openBox<User>(_usersBoxName);
    await _loadCurrentUser();
  }

  // Load current user from preferences
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString(_currentUserKey);
    if (currentUserId != null) {
      _currentUser = _usersBox.get(currentUserId);
    }
  }

  // Hash password for storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate unique user ID
  String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Register new user
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? department,
    String? affiliation,
    List<String> researchInterests = const [],
  }) async {
    try {
      // Check if email already exists
      final existingUser =
          _usersBox.values.where((user) => user.email == email).firstOrNull;
      if (existingUser != null) {
        return AuthResult(success: false, message: 'Email already registered');
      }

      // Create new user
      final userId = _generateUserId();
      final hashedPassword = _hashPassword(password);
      final now = DateTime.now();

      final user = User(
        id: userId,
        name: name,
        email: email,
        password: hashedPassword,
        role: role,
        department: department,
        affiliation: affiliation,
        researchInterests: researchInterests,
        preferences: UserPreferences(),
        createdAt: now,
        lastLoginAt: now,
      );

      // Save user to Hive
      await _usersBox.put(userId, user);

      // Set as current user
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, userId);

      return AuthResult(
          success: true, user: user, message: 'Registration successful');
    } catch (e) {
      return AuthResult(success: false, message: 'Registration failed: $e');
    }
  }

  // Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Find user by email
      final user =
          _usersBox.values.where((user) => user.email == email).firstOrNull;
      if (user == null) {
        return AuthResult(success: false, message: 'User not found');
      }

      // Check password
      final hashedPassword = _hashPassword(password);
      if (user.password != hashedPassword) {
        return AuthResult(success: false, message: 'Invalid password');
      }

      // Check if user is active
      if (!user.isActive) {
        return AuthResult(success: false, message: 'Account is deactivated');
      }

      // Update last login
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
      await _usersBox.put(user.id, updatedUser);

      // Set as current user
      _currentUser = updatedUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, user.id);

      return AuthResult(
          success: true, user: updatedUser, message: 'Login successful');
    } catch (e) {
      return AuthResult(success: false, message: 'Login failed: $e');
    }
  }

  // Logout user
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Get current user
  User? get currentUser => _currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    try {
      await _usersBox.put(updatedUser.id, updatedUser);
      if (_currentUser?.id == updatedUser.id) {
        _currentUser = updatedUser;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user by ID
  User? getUserById(String userId) {
    return _usersBox.get(userId);
  }

  // Get all users (for admin purposes)
  List<User> getAllUsers() {
    return _usersBox.values.toList();
  }

  // Follow/Unfollow functionality
  Future<bool> followUser(String userIdToFollow) async {
    if (_currentUser == null) return false;

    try {
      final userToFollow = getUserById(userIdToFollow);
      if (userToFollow == null) return false;

      // Add to current user's following list
      final updatedFollowing = List<String>.from(_currentUser!.following);
      if (!updatedFollowing.contains(userIdToFollow)) {
        updatedFollowing.add(userIdToFollow);
        final updatedCurrentUser =
            _currentUser!.copyWith(following: updatedFollowing);
        await updateProfile(updatedCurrentUser);

        // Add current user to target user's followers list
        final updatedFollowers = List<String>.from(userToFollow.followers);
        if (!updatedFollowers.contains(_currentUser!.id)) {
          updatedFollowers.add(_currentUser!.id);
          final updatedTargetUser =
              userToFollow.copyWith(followers: updatedFollowers);
          await _usersBox.put(userIdToFollow, updatedTargetUser);
        }

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unfollowUser(String userIdToUnfollow) async {
    if (_currentUser == null) return false;

    try {
      final userToUnfollow = getUserById(userIdToUnfollow);
      if (userToUnfollow == null) return false;

      // Remove from current user's following list
      final updatedFollowing = List<String>.from(_currentUser!.following);
      if (updatedFollowing.contains(userIdToUnfollow)) {
        updatedFollowing.remove(userIdToUnfollow);
        final updatedCurrentUser =
            _currentUser!.copyWith(following: updatedFollowing);
        await updateProfile(updatedCurrentUser);

        // Remove current user from target user's followers list
        final updatedFollowers = List<String>.from(userToUnfollow.followers);
        if (updatedFollowers.contains(_currentUser!.id)) {
          updatedFollowers.remove(_currentUser!.id);
          final updatedTargetUser =
              userToUnfollow.copyWith(followers: updatedFollowers);
          await _usersBox.put(userIdToUnfollow, updatedTargetUser);
        }

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if current user is following another user
  bool isFollowing(String userId) {
    if (_currentUser == null) return false;
    return _currentUser!.following.contains(userId);
  }

  // Get followers of a user
  List<User> getFollowers(String userId) {
    final user = getUserById(userId);
    if (user == null) return [];

    return user.followers
        .map((followerId) => getUserById(followerId))
        .where((user) => user != null)
        .cast<User>()
        .toList();
  }

  // Get users that a user is following
  List<User> getFollowing(String userId) {
    final user = getUserById(userId);
    if (user == null) return [];

    return user.following
        .map((followingId) => getUserById(followingId))
        .where((user) => user != null)
        .cast<User>()
        .toList();
  }

  // Search users
  List<User> searchUsers(String query) {
    if (query.isEmpty) return [];

    return _usersBox.values
        .where((user) =>
            user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase()) ||
            (user.department?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (user.affiliation?.toLowerCase().contains(query.toLowerCase()) ??
                false))
        .toList();
  }

  // Delete account
  Future<bool> deleteAccount(String userId) async {
    try {
      await _usersBox.delete(userId);
      if (_currentUser?.id == userId) {
        await logout();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Authentication result class
class AuthResult {
  final bool success;
  final User? user;
  final String message;

  AuthResult({
    required this.success,
    this.user,
    required this.message,
  });
}
