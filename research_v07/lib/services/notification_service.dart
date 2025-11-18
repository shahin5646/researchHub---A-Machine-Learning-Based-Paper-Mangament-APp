import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'dart:async';

/// Service for handling Firebase Cloud Messaging notifications
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger('NotificationService');

  final StreamController<RemoteMessage> _notificationStreamController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get notificationStream =>
      _notificationStreamController.stream;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      _logger.info('Initializing notification service');

      // Request permission
      final settings = await _requestPermission();
      _logger.info(
          'Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          _logger.info('FCM Token obtained: ${token.substring(0, 20)}...');
          // Token will be saved to user document by caller
        }

        // Setup message handlers
        _setupMessageHandlers();

        _logger.info('Notification service initialized successfully');
      } else {
        _logger.warning('Notification permission denied');
      }
    } catch (e) {
      _logger.severe('Error initializing notification service: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings;
  }

  /// Get current FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      _logger.severe('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to user document
  Future<void> saveFCMToken(String userId) async {
    try {
      final token = await getFCMToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        _logger.info('FCM token saved for user: $userId');
      }
    } catch (e) {
      _logger.warning('Error saving FCM token: $e');
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle initial message if app was opened from terminated state
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleBackgroundMessage(message);
      }
    });

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _logger.info('FCM token refreshed');
      // Token refresh will be handled by app
    });
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.info('Foreground message received: ${message.messageId}');
    _logger.info('Notification: ${message.notification?.title}');

    // Add to stream for UI consumption
    _notificationStreamController.add(message);

    // Store notification in Firestore
    if (message.data['userId'] != null) {
      _storeNotification(message);
    }
  }

  /// Handle background message
  void _handleBackgroundMessage(RemoteMessage message) {
    _logger.info('Background message opened: ${message.messageId}');

    // Add to stream for navigation
    _notificationStreamController.add(message);
  }

  /// Store notification in Firestore
  Future<void> _storeNotification(RemoteMessage message) async {
    try {
      final userId = message.data['userId'];
      if (userId == null) return;

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.info('Notification stored in Firestore');
    } catch (e) {
      _logger.warning('Error storing notification: $e');
    }
  }

  /// Send notification to user (requires Cloud Functions)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Create notification document (trigger Cloud Function)
      await _firestore.collection('notification_queue').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.info('Notification queued for user: $userId');
    } catch (e) {
      _logger.severe('Error queuing notification: $e');
      rethrow;
    }
  }

  /// Send notification for new comment
  Future<void> notifyNewComment({
    required String paperOwnerId,
    required String commenterName,
    required String paperId,
    required String paperTitle,
  }) async {
    await sendNotificationToUser(
      userId: paperOwnerId,
      title: 'New Comment',
      body: '$commenterName commented on "$paperTitle"',
      data: {
        'type': 'comment',
        'paperId': paperId,
        'route': '/paper/$paperId',
      },
    );
  }

  /// Send notification for new reaction
  Future<void> notifyNewReaction({
    required String paperOwnerId,
    required String reacterName,
    required String reactionType,
    required String paperId,
    required String paperTitle,
  }) async {
    await sendNotificationToUser(
      userId: paperOwnerId,
      title: 'New Reaction',
      body: '$reacterName reacted with $reactionType to "$paperTitle"',
      data: {
        'type': 'reaction',
        'paperId': paperId,
        'reactionType': reactionType,
        'route': '/paper/$paperId',
      },
    );
  }

  /// Send notification for paper approval
  Future<void> notifyPaperApproved({
    required String userId,
    required String paperId,
    required String paperTitle,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Paper Approved',
      body: 'Your paper "$paperTitle" has been approved!',
      data: {
        'type': 'approval',
        'paperId': paperId,
        'route': '/paper/$paperId',
      },
    );
  }

  /// Send notification for paper rejection
  Future<void> notifyPaperRejected({
    required String userId,
    required String paperId,
    required String paperTitle,
    String? reason,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Paper Rejected',
      body:
          'Your paper "$paperTitle" was rejected${reason != null ? ': $reason' : ''}',
      data: {
        'type': 'rejection',
        'paperId': paperId,
        'reason': reason,
        'route': '/my-papers',
      },
    );
  }

  /// Get user notifications stream
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.warning('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      _logger.info('All notifications marked as read for user: $userId');
    } catch (e) {
      _logger.warning('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      _logger.warning('Error deleting notification: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      _logger.warning('Error getting unread count: $e');
      return 0;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      _logger.info('Subscribed to topic: $topic');
    } catch (e) {
      _logger.warning('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      _logger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.warning('Error unsubscribing from topic: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationStreamController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This function must be a top-level function
  // Cannot access instance members here
  print('Background message: ${message.messageId}');
}
