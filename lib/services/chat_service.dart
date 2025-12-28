import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _chatRoomsCollection = 'chatRooms';
  static const String _messagesCollection = 'messages';

  // Get or create chat room between two users
  Future<ChatRoom> getOrCreateChatRoom({
    required String user1Id,
    required String user1Name,
    required String user2Id,
    required String user2Name,
  }) async {
    // Create a consistent room ID by sorting user IDs
    final sortedIds = [user1Id, user2Id]..sort();
    final roomId = '${sortedIds[0]}_${sortedIds[1]}';

    final roomDoc = await _firestore
        .collection(_chatRoomsCollection)
        .doc(roomId)
        .get();

    if (roomDoc.exists) {
      return ChatRoom.fromFirestore(roomDoc);
    }

    // Create new chat room
    final chatRoom = ChatRoom(
      id: roomId,
      participants: [user1Id, user2Id],
      participantNames: {
        user1Id: user1Name,
        user2Id: user2Name,
      },
    );

    await _firestore
        .collection(_chatRoomsCollection)
        .doc(roomId)
        .set(chatRoom.toFirestore());

    return chatRoom;
  }

  // Get chat rooms for a user
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromFirestore(doc))
            .toList());
  }

  // Get messages in a chat room
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // Send a message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String message,
    required String receiverId,
  }) async {
    final messageDoc = _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .doc();

    final chatMessage = ChatMessage(
      id: messageDoc.id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
    );

    await messageDoc.set(chatMessage.toFirestore());

    // Update chat room with last message
    await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });
  }

  // Update/Edit a message (only allowed within 10 minutes)
  Future<bool> updateMessage({
    required String chatRoomId,
    required String messageId,
    required String newMessage,
    required String senderId,
  }) async {
    // Get the message to verify ownership and time
    final messageDoc = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .doc(messageId)
        .get();

    if (!messageDoc.exists) return false;

    final messageData = messageDoc.data()!;
    
    // Verify sender owns this message
    if (messageData['senderId'] != senderId) return false;

    // Check if within 10 minutes
    final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();
    if (timestamp != null) {
      final elapsed = DateTime.now().difference(timestamp);
      if (elapsed.inMinutes >= 10) return false;
    }

    // Update the message
    await messageDoc.reference.update({
      'message': newMessage,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });

    // Update lastMessage in chat room if this was the last message
    final chatRoomDoc = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .get();
    
    if (chatRoomDoc.exists) {
      final roomData = chatRoomDoc.data()!;
      final lastMessageTime = (roomData['lastMessageTime'] as Timestamp?)?.toDate();
      if (lastMessageTime != null && timestamp != null) {
        // If this message was sent around the same time as last message, update it
        if (lastMessageTime.difference(timestamp).inSeconds.abs() < 5) {
          await chatRoomDoc.reference.update({'lastMessage': newMessage});
        }
      }
    }

    return true;
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .update({
      'unreadCounts.$userId': 0,
    });
  }

  // Get total unread count for a user
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final room = ChatRoom.fromFirestore(doc);
        total += room.getUnreadCount(userId);
      }
      return total;
    });
  }

  // Delete a chat room (for cleanup)
  Future<void> deleteChatRoom(String chatRoomId) async {
    // Delete all messages first
    final messages = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .get();

    for (final doc in messages.docs) {
      await doc.reference.delete();
    }

    // Delete the chat room
    await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .delete();
  }

  /// Delete message for everyone (only sender can do this)
  Future<bool> deleteMessageForEveryone({
    required String chatRoomId,
    required String messageId,
    required String senderId,
  }) async {
    final messageDoc = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .doc(messageId)
        .get();

    if (!messageDoc.exists) return false;

    final messageData = messageDoc.data()!;
    
    // Only sender can delete for everyone
    if (messageData['senderId'] != senderId) return false;

    // Update message as deleted for all
    await messageDoc.reference.update({
      'isDeletedForAll': true,
      'message': 'This message was deleted',
    });

    // Update lastMessage in chat room if this was the last message
    final chatRoomDoc = await _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .get();
    
    if (chatRoomDoc.exists) {
      final roomData = chatRoomDoc.data()!;
      final lastMessage = roomData['lastMessage'] as String?;
      if (lastMessage == messageData['message']) {
        await chatRoomDoc.reference.update({
          'lastMessage': 'This message was deleted',
        });
      }
    }

    return true;
  }

  /// Delete message for current user only
  Future<void> deleteMessageForMe({
    required String chatRoomId,
    required String messageId,
    required String userId,
  }) async {
    final messageRef = _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .doc(messageId);

    await messageRef.update({
      'deletedForUsers': FieldValue.arrayUnion([userId]),
    });
  }
}
