import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../models/app_user.dart';
import '../models/firebase_paper.dart';
import '../models/user.dart';

/// Firebase-based admin service for user and content management
class FirebaseAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('FirebaseAdminService');

  /// Check if user has admin privileges
  Future<bool> isAdmin(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      final role = userData?['role'] as String?;
      return role == 'admin';
    } catch (e) {
      _logger.severe('Error checking admin status: $e');
      return false;
    }
  }

  /// Get all users with pagination (admin only)
  Future<List<AppUser>> getAllUsers({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      _logger.info('Fetching all users (limit: $limit)');

      Query query = _firestore.collection('users').limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.severe('Error fetching users: $e');
      return [];
    }
  }

  /// Update user role (admin only)
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      _logger.info('Updating user role: $userId to ${newRole.toString()}');

      await _firestore.collection('users').doc(userId).update({
        'role': newRole.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.info('User role updated successfully');
    } catch (e) {
      _logger.severe('Error updating user role: $e');
      rethrow;
    }
  }

  /// Ban user (admin only)
  Future<void> banUser(String userId, {String? reason}) async {
    try {
      _logger.info('Banning user: $userId');

      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'bannedAt': FieldValue.serverTimestamp(),
        'banReason': reason ?? 'No reason provided',
      });

      _logger.info('User banned successfully');
    } catch (e) {
      _logger.severe('Error banning user: $e');
      rethrow;
    }
  }

  /// Unban user (admin only)
  Future<void> unbanUser(String userId) async {
    try {
      _logger.info('Unbanning user: $userId');

      await _firestore.collection('users').doc(userId).update({
        'isBanned': false,
        'bannedAt': FieldValue.delete(),
        'banReason': FieldValue.delete(),
      });

      _logger.info('User unbanned successfully');
    } catch (e) {
      _logger.severe('Error unbanning user: $e');
      rethrow;
    }
  }

  /// Get pending papers for moderation (admin only)
  Future<List<FirebasePaper>> getPendingPapers({int limit = 20}) async {
    try {
      _logger.info('Fetching pending papers');

      final snapshot = await _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'pending')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching pending papers: $e');
      return [];
    }
  }

  /// Approve paper (admin only)
  Future<void> approvePaper(String paperId) async {
    try {
      _logger.info('Approving paper: $paperId');

      await _firestore.collection('papers').doc(paperId).update({
        'visibility': 'public',
        'approvedAt': FieldValue.serverTimestamp(),
        'moderationStatus': 'approved',
      });

      _logger.info('Paper approved successfully');
    } catch (e) {
      _logger.severe('Error approving paper: $e');
      rethrow;
    }
  }

  /// Reject paper (admin only)
  Future<void> rejectPaper(String paperId, {String? reason}) async {
    try {
      _logger.info('Rejecting paper: $paperId');

      await _firestore.collection('papers').doc(paperId).update({
        'visibility': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason ?? 'Did not meet quality standards',
        'moderationStatus': 'rejected',
      });

      _logger.info('Paper rejected successfully');
    } catch (e) {
      _logger.severe('Error rejecting paper: $e');
      rethrow;
    }
  }

  /// Delete paper permanently (admin only)
  Future<void> deletePaper(String paperId, String adminUserId) async {
    try {
      _logger.info('Admin deleting paper: $paperId');

      // Create audit log
      await _firestore.collection('admin_logs').add({
        'action': 'delete_paper',
        'paperId': paperId,
        'adminUserId': adminUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Delete paper
      await _firestore.collection('papers').doc(paperId).delete();

      _logger.info('Paper deleted successfully');
    } catch (e) {
      _logger.severe('Error deleting paper: $e');
      rethrow;
    }
  }

  /// Get user activity logs
  Future<List<Map<String, dynamic>>> getUserActivityLogs(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('activity_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _logger.severe('Error fetching activity logs: $e');
      return [];
    }
  }

  /// Get admin action logs
  Future<List<Map<String, dynamic>>> getAdminLogs({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('admin_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _logger.severe('Error fetching admin logs: $e');
      return [];
    }
  }

  /// Get system statistics (admin dashboard)
  Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      _logger.info('Fetching system statistics');

      // Get counts
      final usersCount = await _firestore.collection('users').count().get();
      final papersCount = await _firestore.collection('papers').count().get();
      final pendingPapersCount = await _firestore
          .collection('papers')
          .where('visibility', isEqualTo: 'pending')
          .count()
          .get();

      // Get recent activity
      final recentPapers = await _firestore
          .collection('papers')
          .orderBy('uploadedAt', descending: true)
          .limit(10)
          .get();

      final recentUsers = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return {
        'totalUsers': usersCount.count ?? 0,
        'totalPapers': papersCount.count ?? 0,
        'pendingPapers': pendingPapersCount.count ?? 0,
        'recentPapersCount': recentPapers.docs.length,
        'recentUsersCount': recentUsers.docs.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.severe('Error fetching system statistics: $e');
      return {};
    }
  }

  /// Log admin action for audit trail
  Future<void> logAdminAction({
    required String adminUserId,
    required String action,
    String? targetUserId,
    String? targetPaperId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('admin_logs').add({
        'adminUserId': adminUserId,
        'action': action,
        'targetUserId': targetUserId,
        'targetPaperId': targetPaperId,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.warning('Error logging admin action: $e');
    }
  }

  /// Search users by email or display name (admin only)
  Future<List<AppUser>> searchUsers(String query) async {
    try {
      _logger.info('Searching users: $query');

      // Search by email
      final emailResults = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      // Search by display name
      final nameResults = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      final users = <AppUser>[];
      final seenIds = <String>{};

      for (var doc in [...emailResults.docs, ...nameResults.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          users.add(AppUser.fromFirestore(doc));
        }
      }

      return users;
    } catch (e) {
      _logger.severe('Error searching users: $e');
      return [];
    }
  }

  /// Get all papers by a specific user (admin only)
  Future<List<FirebasePaper>> getUserPapers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('papers')
          .where('uploadedBy', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FirebasePaper.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching user papers: $e');
      return [];
    }
  }

  /// Get flagged content (admin only)
  Future<List<Map<String, dynamic>>> getFlaggedContent() async {
    try {
      final snapshot = await _firestore
          .collection('flagged_content')
          .orderBy('flaggedAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      _logger.severe('Error fetching flagged content: $e');
      return [];
    }
  }

  /// Resolve flagged content (admin only)
  Future<void> resolveFlaggedContent(
    String flagId, {
    required String resolution,
    required String adminUserId,
  }) async {
    try {
      await _firestore.collection('flagged_content').doc(flagId).update({
        'status': 'resolved',
        'resolution': resolution,
        'resolvedBy': adminUserId,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      _logger.info('Flagged content resolved: $flagId');
    } catch (e) {
      _logger.severe('Error resolving flagged content: $e');
      rethrow;
    }
  }
}
