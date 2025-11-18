import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantUsernames;
  final Map<String, String?> participantPhotoUrls;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantUsernames,
    required this.participantPhotoUrls,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    required this.unreadCounts,
    required this.createdAt,
  });

  // Create from Firestore document
  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safely parse unreadCounts
    Map<String, int> parseUnreadCounts(dynamic unreadData) {
      if (unreadData == null) return {};
      if (unreadData is Map) {
        return unreadData.map((key, value) {
          if (value is int) {
            return MapEntry(key.toString(), value);
          } else if (value is num) {
            return MapEntry(key.toString(), value.toInt());
          } else {
            return MapEntry(key.toString(), 0);
          }
        });
      }
      return {};
    }

    return Conversation(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantNames:
          Map<String, String>.from(data['participantNames'] ?? {}),
      participantUsernames:
          Map<String, String?>.from(data['participantUsernames'] ?? {}),
      participantPhotoUrls:
          Map<String, String?>.from(data['participantPhotoUrls'] ?? {}),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      lastMessageTime:
          (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: parseUnreadCounts(data['unreadCounts']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantUsernames': participantUsernames,
      'participantPhotoUrls': participantPhotoUrls,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCounts': unreadCounts,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Get the other participant's info (for 1-on-1 chats)
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
  }

  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown User';
  }

  String? getOtherParticipantUsername(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantUsernames[otherId];
  }

  String? getOtherParticipantPhotoUrl(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantPhotoUrls[otherId];
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  // Create a copy with updated fields
  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    Map<String, String?>? participantUsernames,
    Map<String, String?>? participantPhotoUrls,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCounts,
    DateTime? createdAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantUsernames: participantUsernames ?? this.participantUsernames,
      participantPhotoUrls: participantPhotoUrls ?? this.participantPhotoUrls,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
