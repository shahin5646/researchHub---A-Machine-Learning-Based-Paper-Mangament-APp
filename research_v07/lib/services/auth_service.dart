import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersBoxName = 'users';
  static const String _sessionsBoxName = 'sessions';
  static const String _currentUserKey = 'current_user_id';

  late Box<Map<dynamic, dynamic>> _usersBox;
  late Box<Map<dynamic, dynamic>> _sessionsBox;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserRoleAdapter());
    }

    _usersBox = await Hive.openBox<Map<dynamic, dynamic>>(_usersBoxName);
    _sessionsBox = await Hive.openBox<Map<dynamic, dynamic>>(_sessionsBoxName);

    // Create default admin user if no users exist
    if (_usersBox.isEmpty) {
      await _createDefaultUsers();
    }
  }

  Future<void> _createDefaultUsers() async {
    // Create default admin user
    final adminUser = User(
      id: 'admin_001',
      username: 'admin',
      email: 'admin@research.com',
      displayName: 'System Administrator',
      role: UserRole.admin,
      bio: 'System administrator for the research platform',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isVerified: true,
    );

    // Create sample professor
    final professor = User(
      id: 'prof_001',
      username: 'dr_smith',
      email: 'smith@university.edu',
      displayName: 'Dr. John Smith',
      role: UserRole.professor,
      bio: 'Professor of Computer Science specializing in Machine Learning',
      department: 'Computer Science',
      institution: 'State University',
      interests: ['Machine Learning', 'AI', 'Data Science'],
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isVerified: true,
    );

    // Create sample student
    final student = User(
      id: 'student_001',
      username: 'alice_johnson',
      email: 'alice@student.edu',
      displayName: 'Alice Johnson',
      role: UserRole.student,
      bio: 'Graduate student researching Natural Language Processing',
      department: 'Computer Science',
      institution: 'State University',
      interests: ['NLP', 'Deep Learning', 'Research'],
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await _saveUser(adminUser);
    await _saveUser(professor);
    await _saveUser(student);

    // Create default credentials (in real app, use proper password hashing)
    await _saveCredentials('admin', 'admin123');
    await _saveCredentials('dr_smith', 'password123');
    await _saveCredentials('alice_johnson', 'student123');
  }

  Future<void> _saveUser(User user) async {
    await _usersBox.put(user.id, user.toJson());
  }

  Future<void> _saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    // In production, use proper password hashing (bcrypt, etc.)
    final hashedPassword = _simpleHash(password);
    await prefs.setString('cred_$username', hashedPassword);
  }

  String _simpleHash(String password) {
    // Simple hash for demo - use proper hashing in production
    return base64.encode(utf8.encode(password + 'salt123'));
  }

  Future<AuthResult> login(String username, String password) async {
    try {
      // Find user by username
      User? user;
      for (var userMap in _usersBox.values) {
        final userData = User.fromJson(Map<String, dynamic>.from(userMap));
        if (userData.username == username) {
          user = userData;
          break;
        }
      }

      if (user == null) {
        return AuthResult(success: false, message: 'User not found');
      }

      // Check password
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString('cred_$username');
      final inputHash = _simpleHash(password);

      if (storedHash != inputHash) {
        return AuthResult(success: false, message: 'Invalid password');
      }

      // Create session
      final session = UserSession(
        userId: user.id,
        token: _generateToken(),
        loginTime: DateTime.now(),
        expiryTime: DateTime.now().add(const Duration(days: 30)),
        rememberMe: true,
      );

      await _sessionsBox.put(session.token, session.toJson());
      await prefs.setString(_currentUserKey, user.id);

      // Update last login
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
      await _saveUser(updatedUser);

      return AuthResult(success: true, user: updatedUser, session: session);
    } catch (e) {
      return AuthResult(success: false, message: 'Login failed: $e');
    }
  }

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? bio,
    String? department,
    String? institution,
    List<String>? interests,
  }) async {
    try {
      // Check if username already exists
      for (var userMap in _usersBox.values) {
        final userData = User.fromJson(Map<String, dynamic>.from(userMap));
        if (userData.username == username || userData.email == email) {
          return AuthResult(
              success: false, message: 'Username or email already exists');
        }
      }

      // Create new user
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: email,
        displayName: displayName,
        role: role,
        bio: bio,
        department: department,
        institution: institution,
        interests: interests ?? [],
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _saveUser(user);
      await _saveCredentials(username, password);

      return AuthResult(
          success: true, user: user, message: 'Registration successful');
    } catch (e) {
      return AuthResult(success: false, message: 'Registration failed: $e');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserKey);

      if (userId == null) return null;

      final userMap = _usersBox.get(userId);
      if (userMap == null) return null;

      return User.fromJson(Map<String, dynamic>.from(userMap));
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);

    // Clear all sessions for this user
    final userId = prefs.getString(_currentUserKey);
    if (userId != null) {
      final sessionsToRemove = <String>[];
      for (var entry in _sessionsBox.toMap().entries) {
        final session =
            UserSession.fromJson(Map<String, dynamic>.from(entry.value));
        if (session.userId == userId) {
          sessionsToRemove.add(entry.key);
        }
      }

      for (var key in sessionsToRemove) {
        await _sessionsBox.delete(key);
      }
    }
  }

  Future<void> updateUser(User user) async {
    await _saveUser(user);
  }

  Future<List<User>> getAllUsers() async {
    return _usersBox.values
        .map((userMap) => User.fromJson(Map<String, dynamic>.from(userMap)))
        .toList();
  }

  Future<User?> getUserById(String id) async {
    final userMap = _usersBox.get(id);
    if (userMap == null) return null;
    return User.fromJson(Map<String, dynamic>.from(userMap));
  }

  String _generateToken() {
    final random = Random();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(List.generate(
        32, (index) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
}

class AuthResult {
  final bool success;
  final String? message;
  final User? user;
  final UserSession? session;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.session,
  });
}

// Custom Hive adapter for UserRole enum
class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 1;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.student;
      case 1:
        return UserRole.professor;
      case 2:
        return UserRole.researcher;
      case 3:
        return UserRole.admin;
      case 4:
        return UserRole.guest;
      default:
        return UserRole.student;
    }
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    switch (obj) {
      case UserRole.student:
        writer.writeByte(0);
        break;
      case UserRole.professor:
        writer.writeByte(1);
        break;
      case UserRole.researcher:
        writer.writeByte(2);
        break;
      case UserRole.admin:
        writer.writeByte(3);
        break;
      case UserRole.guest:
        writer.writeByte(4);
        break;
    }
  }
}

// Riverpod providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = ref.read(authServiceProvider);
  return await authService.getCurrentUser();
});

final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final authService = ref.read(authServiceProvider);
  return await authService.isLoggedIn();
});
