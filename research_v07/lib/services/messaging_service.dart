import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../models/user_profile.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or create a conversation between two users
  Future<String> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    String? currentUserUsername,
    String? otherUserUsername,
    String? currentUserPhotoUrl,
    String? otherUserPhotoUrl,
  }) async {
    try {
      // Check if conversation already exists
      final existingConversations = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: currentUserId)
          .get();

      for (var doc in existingConversations.docs) {
        final conversation = Conversation.fromFirestore(doc);
        if (conversation.participantIds.contains(otherUserId)) {
          return doc.id;
        }
      }

      // Create new conversation
      final conversationData = {
        'participantIds': [currentUserId, otherUserId],
        'participantNames': {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        'participantUsernames': {
          currentUserId: currentUserUsername,
          otherUserId: otherUserUsername,
        },
        'participantPhotoUrls': {
          currentUserId: currentUserPhotoUrl,
          otherUserId: otherUserPhotoUrl,
        },
        'lastMessage': '',
        'lastMessageSenderId': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': {
          currentUserId: 0,
          otherUserId: 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef =
          await _firestore.collection('conversations').add(conversationData);
      return docRef.id;
    } catch (e) {
      print('Error getting or creating conversation: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderUsername,
    String? senderPhotoUrl,
    required String content,
    String? imageUrl,
    required String recipientId,
  }) async {
    try {
      final messageData = {
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'senderUsername': senderUsername,
        'senderPhotoUrl': senderPhotoUrl,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'imageUrl': imageUrl,
      };

      // Add message to messages collection
      await _firestore.collection('messages').add(messageData);

      // Update conversation's last message
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': content,
        'lastMessageSenderId': senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts.$recipientId': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages stream for a conversation
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  // Get conversations stream for a user
  Stream<List<Conversation>> getConversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromFirestore(doc))
          .toList();
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      // Get all unread messages in this conversation that were sent by the other user
      final unreadMessages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      // Update each message to mark as read
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Reset unread count for this user in the conversation
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCounts.$userId': 0,
      });
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }

  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation
      final messages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Delete the conversation
      batch.delete(_firestore.collection('conversations').doc(conversationId));

      await batch.commit();
    } catch (e) {
      print('Error deleting conversation: $e');
      rethrow;
    }
  }

  // Get total unread message count for a user
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final conversation = Conversation.fromFirestore(doc);
        totalUnread += conversation.getUnreadCount(userId);
      }
      return totalUnread;
    });
  }

  // Search users for messaging (excluding current user)
  Future<List<UserProfile>> searchUsers(
      String query, String currentUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .where((user) => user.id != currentUserId)
          .toList();

      // Also search by username if query starts with @
      if (query.startsWith('@')) {
        final usernameQuery = query.substring(1).toLowerCase();
        final usernameSnapshot = await _firestore
            .collection('users')
            .where('username', isGreaterThanOrEqualTo: usernameQuery)
            .where('username', isLessThanOrEqualTo: '$usernameQuery\uf8ff')
            .limit(20)
            .get();

        final usernameUsers = usernameSnapshot.docs
            .map((doc) => UserProfile.fromFirestore(doc))
            .where((user) => user.id != currentUserId)
            .toList();

        // Merge results (remove duplicates)
        final userIds = users.map((u) => u.id).toSet();
        for (var user in usernameUsers) {
          if (!userIds.contains(user.id)) {
            users.add(user);
            userIds.add(user.id);
          }
        }
      }

      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
