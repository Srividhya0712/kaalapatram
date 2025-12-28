import 'package:cloud_firestore/cloud_firestore.dart';

// Message status for WhatsApp-style sending feedback
enum MessageStatus { sending, sent, delivered, read, failed }

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final MessageStatus status;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeletedForAll;
  final List<String> deletedForUsers;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.status = MessageStatus.sent,
    this.isEdited = false,
    this.editedAt,
    this.isDeletedForAll = false,
    this.deletedForUsers = const [],
  });

  // Create a copy with updated status or message
  ChatMessage copyWith({
    MessageStatus? status,
    String? message,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeletedForAll,
    List<String>? deletedForUsers,
  }) {
    return ChatMessage(
      id: id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderName,
      message: message ?? this.message,
      timestamp: timestamp,
      isRead: isRead,
      status: status ?? this.status,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeletedForAll: isDeletedForAll ?? this.isDeletedForAll,
      deletedForUsers: deletedForUsers ?? this.deletedForUsers,
    );
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      chatRoomId: data['chatRoomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      status: MessageStatus.sent, // Messages from Firestore are already sent
      isEdited: data['isEdited'] ?? false,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      isDeletedForAll: data['isDeletedForAll'] ?? false,
      deletedForUsers: List<String>.from(data['deletedForUsers'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'isEdited': isEdited,
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
      'isDeletedForAll': isDeletedForAll,
      'deletedForUsers': deletedForUsers,
    };
  }

  /// Check if message can be edited (within 10 minutes of sending)
  bool get canEdit {
    final now = DateTime.now();
    final elapsed = now.difference(timestamp);
    return elapsed.inMinutes < 10;
  }

  /// Check if message is deleted for a specific user
  bool isDeletedFor(String userId) {
    return isDeletedForAll || deletedForUsers.contains(userId);
  }

  /// Get display text (handles deleted messages)
  String getDisplayText(String currentUserId) {
    if (isDeletedForAll) {
      return 'This message was deleted';
    }
    if (deletedForUsers.contains(currentUserId)) {
      return ''; // Message won't be shown at all
    }
    return message;
  }
}

class ChatRoom {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final Map<String, int> unreadCounts;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessage = '',
    DateTime? lastMessageTime,
    this.lastMessageSenderId = '',
    Map<String, int>? unreadCounts,
  }) : lastMessageTime = lastMessageTime ?? DateTime.now(),
       unreadCounts = unreadCounts ?? {};

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCounts': unreadCounts,
    };
  }

  String getOtherUserId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String getOtherUserName(String currentUserId) {
    final otherUserId = getOtherUserId(currentUserId);
    return participantNames[otherUserId] ?? 'Unknown';
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }
}
