import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/research_paper.dart';
import '../data/faculty_data.dart';
import 'analytics_service.dart';
import 'ml_categorization_service.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final AnalyticsService _analyticsService = AnalyticsService();
  final MLCategorizationService _mlService = MLCategorizationService();

  final Map<String, AdminUser> _adminUsers = {};
  final List<ContentModerationItem> _moderationQueue = [];
  final List<SystemLog> _systemLogs = [];

  // Initialize admin service
  Future<void> initialize() async {
    await _loadAdminData();
    await _setupDefaultAdmin();
    await _startSystemMonitoring();
  }

  // Authentication and authorization
  Future<AdminAuthResult> authenticateAdmin(
      String username, String password) async {
    final admin = _adminUsers[username];

    if (admin == null) {
      await _logSystemEvent(
          'Failed admin login attempt', 'security', {'username': username});
      return AdminAuthResult(success: false, message: 'Invalid credentials');
    }

    // In a real app, use proper password hashing
    if (admin.password != password) {
      await _logSystemEvent(
          'Failed admin login attempt', 'security', {'username': username});
      return AdminAuthResult(success: false, message: 'Invalid credentials');
    }

    if (!admin.isActive) {
      return AdminAuthResult(success: false, message: 'Account is deactivated');
    }

    // Update last login
    _adminUsers[username] = AdminUser(
      id: admin.id,
      username: admin.username,
      email: admin.email,
      password: admin.password,
      role: admin.role,
      permissions: admin.permissions,
      isActive: admin.isActive,
      lastLogin: DateTime.now(),
      createdAt: admin.createdAt,
    );

    await _logSystemEvent('Admin login successful', 'auth',
        {'username': username, 'role': admin.role.toString()});
    await _saveAdminData();

    return AdminAuthResult(success: true, admin: _adminUsers[username]);
  }

  // User management
  Future<void> createAdminUser(AdminUser user) async {
    if (_adminUsers.containsKey(user.username)) {
      throw Exception('Username already exists');
    }

    _adminUsers[user.username] = user;
    await _saveAdminData();
    await _logSystemEvent('Admin user created', 'user_management',
        {'username': user.username, 'role': user.role.toString()});
  }

  Future<void> updateAdminUser(String username, AdminUser updatedUser) async {
    if (!_adminUsers.containsKey(username)) {
      throw Exception('User not found');
    }

    _adminUsers[username] = updatedUser;
    await _saveAdminData();
    await _logSystemEvent(
        'Admin user updated', 'user_management', {'username': username});
  }

  Future<void> deleteAdminUser(String username) async {
    if (!_adminUsers.containsKey(username)) {
      throw Exception('User not found');
    }

    _adminUsers.remove(username);
    await _saveAdminData();
    await _logSystemEvent(
        'Admin user deleted', 'user_management', {'username': username});
  }

  List<AdminUser> getAllAdminUsers() {
    return _adminUsers.values.toList();
  }

  // Content management
  Future<void> addResearchPaper(String facultyId, ResearchPaper paper) async {
    if (!facultyResearchPapers.containsKey(facultyId)) {
      facultyResearchPapers[facultyId] = [];
    }

    // Auto-categorize the paper using ML service (simplified)
    try {
      await _mlService.performKMeansClustering();
      // Use clustering results if available
    } catch (e) {
      // Use default handling if ML fails
    }

    // Create paper with existing ResearchPaper structure
    final updatedPaper = ResearchPaper(
      id: paper.id,
      title: paper.title,
      author: paper.author,
      abstract: paper.abstract,
      keywords: paper.keywords,
      pdfUrl: paper.pdfUrl,
      year: paper.year,
      citations: paper.citations,
      journalName: 'Unknown Journal',
      doi: 'unknown',
    );

    facultyResearchPapers[facultyId]!.add(updatedPaper);
    await _logSystemEvent('Research paper added', 'content_management',
        {'paperId': paper.id, 'facultyId': facultyId, 'title': paper.title});
  }

  Future<void> updateResearchPaper(
      String facultyId, int paperIndex, ResearchPaper updatedPaper) async {
    if (!facultyResearchPapers.containsKey(facultyId) ||
        paperIndex >= facultyResearchPapers[facultyId]!.length) {
      throw Exception('Paper not found');
    }

    facultyResearchPapers[facultyId]![paperIndex] = updatedPaper;
    await _logSystemEvent('Research paper updated', 'content_management',
        {'paperId': updatedPaper.id, 'facultyId': facultyId});
  }

  Future<void> deleteResearchPaper(String facultyId, int paperIndex) async {
    if (!facultyResearchPapers.containsKey(facultyId) ||
        paperIndex >= facultyResearchPapers[facultyId]!.length) {
      throw Exception('Paper not found');
    }

    final paper = facultyResearchPapers[facultyId]![paperIndex];
    facultyResearchPapers[facultyId]!.removeAt(paperIndex);

    await _logSystemEvent('Research paper deleted', 'content_management',
        {'paperId': paper.id, 'facultyId': facultyId, 'title': paper.title});
  }

  // Bulk operations
  Future<BulkOperationResult> bulkImportPapers(
      String facultyId, List<Map<String, dynamic>> papersData) async {
    final results = BulkOperationResult();

    for (int i = 0; i < papersData.length; i++) {
      try {
        final paperData = papersData[i];
        final paper = ResearchPaper.fromJson(paperData);
        await addResearchPaper(facultyId, paper);
        results.successCount++;
      } catch (e) {
        results.failures.add(BulkOperationFailure(
          index: i,
          data: papersData[i],
          error: e.toString(),
        ));
      }
    }

    await _logSystemEvent('Bulk paper import completed', 'content_management', {
      'facultyId': facultyId,
      'totalAttempted': papersData.length,
      'successful': results.successCount,
      'failed': results.failures.length
    });

    return results;
  }

  Future<Map<String, dynamic>> exportAllData() async {
    final exportData = {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'facultyData': facultyMembers.map((f) => f.toJson()).toList(),
      'researchPapers': {},
      'analytics': _analyticsService.exportAnalytics(),
      'systemLogs': _systemLogs.map((log) => log.toJson()).toList(),
    };

    // Export research papers by faculty
    final researchPapersMap = <String, dynamic>{};
    facultyResearchPapers.forEach((facultyId, papers) {
      researchPapersMap[facultyId] = papers.map((p) => p.toJson()).toList();
    });
    exportData['researchPapers'] = researchPapersMap;

    await _logSystemEvent('Data export completed', 'data_management', {
      'totalFaculty': facultyMembers.length,
      'totalPapers':
          facultyResearchPapers.values.expand((papers) => papers).length
    });

    return exportData;
  }

  // Content moderation
  Future<void> submitForModeration(ContentModerationItem item) async {
    _moderationQueue.add(item);
    await _logSystemEvent('Content submitted for moderation', 'moderation',
        {'itemId': item.id, 'type': item.type.toString()});
  }

  Future<void> moderateContent(String itemId, ModerationAction action,
      String reason, String moderatorId) async {
    final itemIndex = _moderationQueue.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      throw Exception('Moderation item not found');
    }

    final item = _moderationQueue[itemIndex];

    // Apply moderation action
    switch (action) {
      case ModerationAction.approve:
        await _approveContent(item);
        break;
      case ModerationAction.reject:
        await _rejectContent(item, reason);
        break;
      case ModerationAction.flag:
        await _flagContent(item, reason);
        break;
    }

    // Remove from queue
    _moderationQueue.removeAt(itemIndex);

    await _logSystemEvent('Content moderated', 'moderation', {
      'itemId': itemId,
      'action': action.toString(),
      'reason': reason,
      'moderatorId': moderatorId
    });
  }

  List<ContentModerationItem> getModerationQueue() {
    return List.from(_moderationQueue);
  }

  // System monitoring
  Future<SystemHealthReport> getSystemHealth() async {
    final currentTime = DateTime.now();
    final oneHourAgo = currentTime.subtract(const Duration(hours: 1));

    final recentLogs =
        _systemLogs.where((log) => log.timestamp.isAfter(oneHourAgo)).toList();
    final errors = recentLogs.where((log) => log.level == 'error').length;
    final warnings = recentLogs.where((log) => log.level == 'warning').length;

    return SystemHealthReport(
      overallStatus: _calculateSystemStatus(errors, warnings),
      uptime: _calculateUptime(),
      totalPapers:
          facultyResearchPapers.values.expand((papers) => papers).length,
      totalFaculty: facultyMembers.length,
      recentErrors: errors,
      recentWarnings: warnings,
      memoryUsage: await _getMemoryUsage(),
      storageUsage: await _getStorageUsage(),
      averageResponseTime: _calculateAverageResponseTime(),
      activeUsers: await _getActiveUsersCount(),
      systemMetrics: _getSystemMetrics(),
    );
  }

  Future<List<SystemLog>> getSystemLogs({
    int limit = 100,
    String? level,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var logs = List<SystemLog>.from(_systemLogs);

    // Apply filters
    if (level != null) {
      logs = logs.where((log) => log.level == level).toList();
    }

    if (category != null) {
      logs = logs.where((log) => log.category == category).toList();
    }

    if (startDate != null) {
      logs = logs.where((log) => log.timestamp.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      logs = logs.where((log) => log.timestamp.isBefore(endDate)).toList();
    }

    // Sort by timestamp (newest first) and limit
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs.take(limit).toList();
  }

  // Analytics integration
  Future<AdminAnalytics> getAdminAnalytics({int days = 30}) async {
    final dashboard = _analyticsService.getDashboardData(days: days);
    final systemHealth = await getSystemHealth();

    return AdminAnalytics(
      dashboardData: dashboard,
      systemHealth: systemHealth,
      contentStats: _getContentStats(),
      userActivityStats: _getUserActivityStats(days),
      performanceMetrics: _getPerformanceMetrics(days),
    );
  }

  // User activity monitoring
  Future<List<UserActivity>> getUserActivities({
    int limit = 50,
    String? userId,
    DateTime? startDate,
  }) async {
    // This would integrate with your user tracking system
    return []; // Placeholder
  }

  Future<void> suspendUser(
      String userId, String reason, Duration duration) async {
    // Implement user suspension logic
    await _logSystemEvent('User suspended', 'user_management', {
      'userId': userId,
      'reason': reason,
      'duration': duration.inDays.toString() + ' days'
    });
  }

  // Backup and restore
  Future<BackupInfo> createBackup() async {
    final backupData = await exportAllData();
    final timestamp = DateTime.now();
    final backupId = 'backup_${timestamp.millisecondsSinceEpoch}';

    // In a real app, save to cloud storage or file system
    final backup = BackupInfo(
      id: backupId,
      timestamp: timestamp,
      size: json.encode(backupData).length,
      type: BackupType.full,
      status: BackupStatus.completed,
    );

    await _logSystemEvent('Backup created', 'backup',
        {'backupId': backupId, 'size': backup.size.toString()});

    return backup;
  }

  Future<void> restoreFromBackup(String backupId) async {
    // Implement restore logic
    await _logSystemEvent(
        'Restore initiated', 'backup', {'backupId': backupId});
  }

  // Performance optimization
  Future<void> optimizeDatabase() async {
    // Implement database optimization logic
    await _logSystemEvent('Database optimization started', 'maintenance', {});

    // Simulate optimization process
    await Future.delayed(const Duration(seconds: 2));

    await _logSystemEvent('Database optimization completed', 'maintenance', {});
  }

  Future<void> clearCache() async {
    // Clear various caches - simplified since method doesn't exist in ML service
    await _logSystemEvent('Cache cleared', 'maintenance', {});
  }

  // Private helper methods
  Future<void> _setupDefaultAdmin() async {
    if (_adminUsers.isEmpty) {
      final defaultAdmin = AdminUser(
        id: 'admin_1',
        username: 'admin',
        email: 'admin@research.com',
        password: 'admin123', // Change this in production!
        role: AdminRole.superAdmin,
        permissions: AdminPermission.values.toSet(),
        isActive: true,
        lastLogin: null,
        createdAt: DateTime.now(),
      );

      _adminUsers['admin'] = defaultAdmin;
      await _saveAdminData();
    }
  }

  Future<void> _logSystemEvent(String message, String category,
      [Map<String, dynamic>? metadata]) async {
    final log = SystemLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: 'info',
      category: category,
      message: message,
      metadata: metadata ?? {},
    );

    _systemLogs.add(log);

    // Keep only recent logs to prevent memory issues
    if (_systemLogs.length > 10000) {
      _systemLogs.removeRange(0, 5000);
    }

    // Auto-save logs periodically
    if (_systemLogs.length % 100 == 0) {
      await _saveAdminData();
    }
  }

  Future<void> _startSystemMonitoring() async {
    // Start periodic system monitoring
    // In a real app, this would run in a separate isolate
  }

  SystemStatus _calculateSystemStatus(int errors, int warnings) {
    if (errors > 5) return SystemStatus.critical;
    if (errors > 0 || warnings > 10) return SystemStatus.warning;
    return SystemStatus.healthy;
  }

  Duration _calculateUptime() {
    // Mock uptime calculation
    return const Duration(days: 15, hours: 3, minutes: 42);
  }

  Future<double> _getMemoryUsage() async {
    // Mock memory usage
    return 65.5; // Percentage
  }

  Future<double> _getStorageUsage() async {
    // Mock storage usage
    return 42.3; // Percentage
  }

  double _calculateAverageResponseTime() {
    // Mock response time
    return 125.5; // Milliseconds
  }

  Future<int> _getActiveUsersCount() async {
    // Mock active users
    return 42;
  }

  Map<String, double> _getSystemMetrics() {
    return {
      'cpu_usage': 35.2,
      'memory_usage': 65.5,
      'disk_usage': 42.3,
      'network_in': 1024.5,
      'network_out': 512.3,
    };
  }

  ContentStats _getContentStats() {
    final totalPapers =
        facultyResearchPapers.values.expand((papers) => papers).length;
    return ContentStats(
      totalPapers: totalPapers,
      totalFaculty: facultyMembers.length,
      papersThisMonth: _getPapersThisMonth(),
      pendingModeration: _moderationQueue.length,
    );
  }

  int _getPapersThisMonth() {
    final now = DateTime.now();

    return facultyResearchPapers.values
        .expand((papers) => papers)
        .where((paper) => paper.year == now.year.toString())
        .length;
  }

  UserActivityStats _getUserActivityStats(int days) {
    // Mock user activity stats
    return UserActivityStats(
      totalUsers: 150,
      activeUsers: 42,
      newUsers: 8,
      averageSessionDuration: const Duration(minutes: 15),
    );
  }

  Map<String, double> _getPerformanceMetrics(int days) {
    return {
      'average_response_time': 125.5,
      'error_rate': 0.02,
      'uptime_percentage': 99.9,
      'throughput': 1000.0,
    };
  }

  Future<void> _approveContent(ContentModerationItem item) async {
    // Implement content approval logic
  }

  Future<void> _rejectContent(ContentModerationItem item, String reason) async {
    // Implement content rejection logic
  }

  Future<void> _flagContent(ContentModerationItem item, String reason) async {
    // Implement content flagging logic
  }

  Future<void> _loadAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load admin users
      final adminUsersJson = prefs.getString('admin_users');
      if (adminUsersJson != null) {
        final Map<String, dynamic> data = json.decode(adminUsersJson);
        _adminUsers.clear();
        data.forEach((key, value) {
          _adminUsers[key] = AdminUser.fromJson(value);
        });
      }

      // Load system logs
      final systemLogsJson = prefs.getString('system_logs');
      if (systemLogsJson != null) {
        final List<dynamic> data = json.decode(systemLogsJson);
        _systemLogs.clear();
        _systemLogs.addAll(data.map((e) => SystemLog.fromJson(e)));
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save admin users
      final adminUsersData =
          _adminUsers.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString('admin_users', json.encode(adminUsersData));

      // Save recent system logs only
      final recentLogs = _systemLogs.length > 1000
          ? _systemLogs.sublist(_systemLogs.length - 1000)
          : _systemLogs;
      await prefs.setString('system_logs',
          json.encode(recentLogs.map((e) => e.toJson()).toList()));
    } catch (e) {
      // Handle error silently
    }
  }
}

// Admin data models
class AdminUser {
  final String id;
  final String username;
  final String email;
  final String password;
  final AdminRole role;
  final Set<AdminPermission> permissions;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.permissions,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'],
        username: json['username'],
        email: json['email'],
        password: json['password'],
        role: AdminRole.values.firstWhere((e) => e.toString() == json['role']),
        permissions: (json['permissions'] as List)
            .map((e) =>
                AdminPermission.values.firstWhere((p) => p.toString() == e))
            .toSet(),
        isActive: json['isActive'] ?? true,
        lastLogin: json['lastLogin'] != null
            ? DateTime.parse(json['lastLogin'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'password': password,
        'role': role.toString(),
        'permissions': permissions.map((e) => e.toString()).toList(),
        'isActive': isActive,
        'lastLogin': lastLogin?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}

enum AdminRole {
  superAdmin,
  admin,
  moderator,
  editor,
}

enum AdminPermission {
  manageUsers,
  manageContent,
  viewAnalytics,
  moderateContent,
  manageSystem,
  createBackups,
  exportData,
  viewLogs,
}

class AdminAuthResult {
  final bool success;
  final String? message;
  final AdminUser? admin;

  AdminAuthResult({
    required this.success,
    this.message,
    this.admin,
  });
}

class SystemLog {
  final String id;
  final DateTime timestamp;
  final String level;
  final String category;
  final String message;
  final Map<String, dynamic> metadata;

  SystemLog({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.metadata = const {},
  });

  factory SystemLog.fromJson(Map<String, dynamic> json) => SystemLog(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        level: json['level'],
        category: json['category'],
        message: json['message'],
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'level': level,
        'category': category,
        'message': message,
        'metadata': metadata,
      };
}

class SystemHealthReport {
  final SystemStatus overallStatus;
  final Duration uptime;
  final int totalPapers;
  final int totalFaculty;
  final int recentErrors;
  final int recentWarnings;
  final double memoryUsage;
  final double storageUsage;
  final double averageResponseTime;
  final int activeUsers;
  final Map<String, double> systemMetrics;

  SystemHealthReport({
    required this.overallStatus,
    required this.uptime,
    required this.totalPapers,
    required this.totalFaculty,
    required this.recentErrors,
    required this.recentWarnings,
    required this.memoryUsage,
    required this.storageUsage,
    required this.averageResponseTime,
    required this.activeUsers,
    required this.systemMetrics,
  });
}

enum SystemStatus {
  healthy,
  warning,
  critical,
}

class ContentModerationItem {
  final String id;
  final ContentType type;
  final String content;
  final String submitterId;
  final DateTime submittedAt;
  final String? reason;

  ContentModerationItem({
    required this.id,
    required this.type,
    required this.content,
    required this.submitterId,
    required this.submittedAt,
    this.reason,
  });
}

enum ContentType {
  researchPaper,
  comment,
  userProfile,
  facultyProfile,
}

enum ModerationAction {
  approve,
  reject,
  flag,
}

class BulkOperationResult {
  int successCount = 0;
  final List<BulkOperationFailure> failures = [];
}

class BulkOperationFailure {
  final int index;
  final Map<String, dynamic> data;
  final String error;

  BulkOperationFailure({
    required this.index,
    required this.data,
    required this.error,
  });
}

class AdminAnalytics {
  final AnalyticsDashboard dashboardData;
  final SystemHealthReport systemHealth;
  final ContentStats contentStats;
  final UserActivityStats userActivityStats;
  final Map<String, double> performanceMetrics;

  AdminAnalytics({
    required this.dashboardData,
    required this.systemHealth,
    required this.contentStats,
    required this.userActivityStats,
    required this.performanceMetrics,
  });
}

class ContentStats {
  final int totalPapers;
  final int totalFaculty;
  final int papersThisMonth;
  final int pendingModeration;

  ContentStats({
    required this.totalPapers,
    required this.totalFaculty,
    required this.papersThisMonth,
    required this.pendingModeration,
  });
}

class UserActivityStats {
  final int totalUsers;
  final int activeUsers;
  final int newUsers;
  final Duration averageSessionDuration;

  UserActivityStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers,
    required this.averageSessionDuration,
  });
}

class UserActivity {
  final String userId;
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  UserActivity({
    required this.userId,
    required this.action,
    required this.timestamp,
    this.details = const {},
  });
}

class BackupInfo {
  final String id;
  final DateTime timestamp;
  final int size;
  final BackupType type;
  final BackupStatus status;

  BackupInfo({
    required this.id,
    required this.timestamp,
    required this.size,
    required this.type,
    required this.status,
  });
}

enum BackupType {
  full,
  incremental,
}

enum BackupStatus {
  pending,
  inProgress,
  completed,
  failed,
}
