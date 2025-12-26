import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/connection.dart';
import '../models/user_profile.dart';

class ConnectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a connection request
  Future<void> sendConnectionRequest({
    required UserProfile requester,
    required UserProfile receiver,
  }) async {
    // Check if connection already exists
    final existingConnection = await _getExistingConnection(
      requester.uid,
      receiver.uid,
    );

    if (existingConnection != null) {
      throw Exception('Connection request already exists');
    }

    final connectionId = _firestore.collection('connections').doc().id;
    final connection = Connection(
      id: connectionId,
      requesterId: requester.uid,
      receiverId: receiver.uid,
      requesterUsername: requester.username,
      receiverUsername: receiver.username,
      status: ConnectionStatus.pending,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('connections')
        .doc(connectionId)
        .set(connection.toJson());
  }

  // Accept a connection request
  Future<void> acceptConnectionRequest(String connectionId) async {
    await _firestore.collection('connections').doc(connectionId).update({
      'status': ConnectionStatus.accepted.name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Decline a connection request
  Future<void> declineConnectionRequest(String connectionId) async {
    await _firestore.collection('connections').doc(connectionId).update({
      'status': ConnectionStatus.declined.name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Remove/Delete a connection
  Future<void> removeConnection(String connectionId) async {
    await _firestore.collection('connections').doc(connectionId).delete();
  }

  // Get all connections for a user (sent and received)
  Stream<List<Connection>> getUserConnections(String userId) {
    return _firestore
        .collection('connections')
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .asyncMap((sentSnapshot) async {
      final receivedSnapshot = await _firestore
          .collection('connections')
          .where('receiverId', isEqualTo: userId)
          .get();

      final allDocs = [...sentSnapshot.docs, ...receivedSnapshot.docs];
      return allDocs.map((doc) {
        final data = doc.data();
        return Connection.fromJson(data);
      }).toList();
    });
  }

  // Get pending connection requests received by user
  Stream<List<Connection>> getPendingRequests(String userId) {
    return _firestore
        .collection('connections')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: ConnectionStatus.pending.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Connection.fromJson(data);
      }).toList();
    });
  }

  // Get accepted connections for a user
  Stream<List<Connection>> getAcceptedConnections(String userId) {
    return _firestore
        .collection('connections')
        .where('status', isEqualTo: ConnectionStatus.accepted.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return Connection.fromJson(data);
          })
          .where((connection) =>
              connection.requesterId == userId || connection.receiverId == userId)
          .toList();
    });
  }

  // Get sent requests by user
  Stream<List<Connection>> getSentRequests(String userId) {
    return _firestore
        .collection('connections')
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Connection.fromJson(data);
      }).toList();
    });
  }

  // Check if users are connected
  Future<bool> areUsersConnected(String userId1, String userId2) async {
    final connection = await _getExistingConnection(userId1, userId2);
    return connection?.status == ConnectionStatus.accepted;
  }

  // Get connection status between two users
  Future<ConnectionStatus?> getConnectionStatus(String userId1, String userId2) async {
    final connection = await _getExistingConnection(userId1, userId2);
    return connection?.status;
  }

  // Search users by name or email (excluding current user)
  Future<List<UserProfile>> searchUsers({
    required String query,
    required String currentUserId,
  }) async {
    if (query.trim().isEmpty) return [];

    final queryLower = query.toLowerCase();
    
    // Search by username (case-insensitive prefix match)
    final usersSnapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: queryLower)
        .where('username', isLessThanOrEqualTo: '$queryLower\uf8ff')
        .limit(20)
        .get();

    // Combine results and remove duplicates, excluding current user
    final uniqueUsers = <String, UserProfile>{};

    for (final doc in usersSnapshot.docs) {
      if (doc.id != currentUserId && !uniqueUsers.containsKey(doc.id)) {
        try {
          uniqueUsers[doc.id] = UserProfile.fromFirestore(doc);
        } catch (e) {
          // Skip users with invalid data
          continue;
        }
      }
    }

    return uniqueUsers.values.toList();
  }

  // Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  // Helper method to get existing connection between two users
  Future<Connection?> _getExistingConnection(String userId1, String userId2) async {
    // Check if user1 sent request to user2
    final sentQuery = await _firestore
        .collection('connections')
        .where('requesterId', isEqualTo: userId1)
        .where('receiverId', isEqualTo: userId2)
        .limit(1)
        .get();

    if (sentQuery.docs.isNotEmpty) {
      return Connection.fromJson(sentQuery.docs.first.data());
    }

    // Check if user2 sent request to user1
    final receivedQuery = await _firestore
        .collection('connections')
        .where('requesterId', isEqualTo: userId2)
        .where('receiverId', isEqualTo: userId1)
        .limit(1)
        .get();

    if (receivedQuery.docs.isNotEmpty) {
      return Connection.fromJson(receivedQuery.docs.first.data());
    }

    return null;
  }

  // Get connected user IDs for a user (for calendar access)
  Future<List<String>> getConnectedUserIds(String userId) async {
    final connections = await getAcceptedConnections(userId).first;
    return connections
        .map((connection) => connection.getOtherUserId(userId))
        .toList();
  }
}
