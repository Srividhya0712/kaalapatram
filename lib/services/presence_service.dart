import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to track user online/offline status and typing indicators
/// Uses Firestore for real-time presence (no separate WebSocket server needed)
class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _heartbeatTimer;
  Timer? _typingTimer;
  String? _currentUserId;
  String? _currentChatRoomId;
  
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _typingTimeout = Duration(seconds: 3);
  static const Duration _offlineThreshold = Duration(seconds: 60);

  /// Initialize presence tracking for a user
  Future<void> initializePresence(String userId) async {
    _currentUserId = userId;
    
    try {
      // Set user as online
      await _setOnline(userId);
      
      // Start heartbeat to keep presence updated
      _startHeartbeat(userId);
      
      debugPrint('✅ Presence initialized for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to initialize presence: $e');
    }
  }

  /// Set user as online with timestamp
  Future<void> _setOnline(String userId) async {
    await _firestore.collection('presence').doc(userId).set({
      'online': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'typing': null, // chatRoomId if typing, null if not
    }, SetOptions(merge: true));
  }

  /// Start heartbeat to keep presence updated
  void _startHeartbeat(String userId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _setOnline(userId);
    });
  }

  /// Set user as offline
  Future<void> setOffline() async {
    if (_currentUserId == null) return;
    
    _heartbeatTimer?.cancel();
    _typingTimer?.cancel();
    
    try {
      await _firestore.collection('presence').doc(_currentUserId).update({
        'online': false,
        'lastSeen': FieldValue.serverTimestamp(),
        'typing': null,
      });
      debugPrint('👋 User set as offline');
    } catch (e) {
      debugPrint('❌ Failed to set offline: $e');
    }
  }

  /// Check if a user is online
  Stream<bool> isUserOnline(String userId) {
    return _firestore
        .collection('presence')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      
      final data = snapshot.data();
      if (data == null) return false;
      
      final isOnline = data['online'] as bool? ?? false;
      final lastSeen = data['lastSeen'] as Timestamp?;
      
      if (!isOnline) return false;
      
      // Check if lastSeen is within threshold (handles stale connections)
      if (lastSeen != null) {
        final timeSinceLastSeen = DateTime.now().difference(lastSeen.toDate());
        return timeSinceLastSeen < _offlineThreshold;
      }
      
      return isOnline;
    });
  }

  /// Get last seen timestamp for a user
  Stream<DateTime?> getLastSeen(String userId) {
    return _firestore
        .collection('presence')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      final data = snapshot.data();
      final lastSeen = data?['lastSeen'] as Timestamp?;
      return lastSeen?.toDate();
    });
  }

  /// Start typing indicator for a chat room
  Future<void> startTyping(String chatRoomId) async {
    if (_currentUserId == null) return;
    
    _currentChatRoomId = chatRoomId;
    
    try {
      await _firestore.collection('presence').doc(_currentUserId).update({
        'typing': chatRoomId,
        'typingStarted': FieldValue.serverTimestamp(),
      });
      
      // Auto-stop typing after timeout
      _typingTimer?.cancel();
      _typingTimer = Timer(_typingTimeout, () {
        stopTyping();
      });
    } catch (e) {
      debugPrint('❌ Failed to set typing: $e');
    }
  }

  /// Stop typing indicator
  Future<void> stopTyping() async {
    if (_currentUserId == null) return;
    
    _typingTimer?.cancel();
    _currentChatRoomId = null;
    
    try {
      await _firestore.collection('presence').doc(_currentUserId).update({
        'typing': null,
        'typingStarted': null,
      });
    } catch (e) {
      debugPrint('❌ Failed to stop typing: $e');
    }
  }

  /// Check if a user is typing in a specific chat room
  Stream<bool> isUserTyping(String userId, String chatRoomId) {
    return _firestore
        .collection('presence')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      
      final data = snapshot.data();
      if (data == null) return false;
      
      final typing = data['typing'] as String?;
      final typingStarted = data['typingStarted'] as Timestamp?;
      
      if (typing != chatRoomId) return false;
      
      // Check if typing indicator is stale
      if (typingStarted != null) {
        final timeSinceTyping = DateTime.now().difference(typingStarted.toDate());
        return timeSinceTyping < const Duration(seconds: 10);
      }
      
      return typing == chatRoomId;
    });
  }

  /// Get presence data for multiple users
  Stream<Map<String, PresenceData>> getMultipleUsersPresence(List<String> userIds) {
    if (userIds.isEmpty) return Stream.value({});
    
    return _firestore
        .collection('presence')
        .where(FieldPath.documentId, whereIn: userIds.take(10).toList()) // Firestore limit
        .snapshots()
        .map((snapshot) {
      final Map<String, PresenceData> presenceMap = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lastSeen = data['lastSeen'] as Timestamp?;
        final isOnline = data['online'] as bool? ?? false;
        
        // Check if online status is stale
        bool effectivelyOnline = false;
        if (isOnline && lastSeen != null) {
          final timeSinceLastSeen = DateTime.now().difference(lastSeen.toDate());
          effectivelyOnline = timeSinceLastSeen < _offlineThreshold;
        }
        
        presenceMap[doc.id] = PresenceData(
          userId: doc.id,
          isOnline: effectivelyOnline,
          lastSeen: lastSeen?.toDate(),
          typingInChatRoom: data['typing'] as String?,
        );
      }
      
      return presenceMap;
    });
  }

  /// Dispose of the service
  void dispose() {
    _heartbeatTimer?.cancel();
    _typingTimer?.cancel();
  }
}

/// Data class for user presence
class PresenceData {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? typingInChatRoom;

  PresenceData({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
    this.typingInChatRoom,
  });
  
  String get lastSeenFormatted {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'Long time ago';
    }
  }
}
