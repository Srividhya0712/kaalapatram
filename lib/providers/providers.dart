import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/event.dart';
import '../models/connection.dart';
import '../services/event_service.dart';
import '../services/connection_service.dart';
import '../services/user_profile_service.dart';

// ============================================================================
// FIREBASE AUTH PROVIDER
// ============================================================================

/// Stream provider for the current Firebase Auth user
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider for the current user UID
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.uid,
    loading: () => null,
    error: (_, __) => null,
  );
});

// ============================================================================
// SERVICE PROVIDERS
// ============================================================================

/// Provider for EventService
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService();
});

/// Provider for ConnectionService
final connectionServiceProvider = Provider<ConnectionService>((ref) {
  return ConnectionService();
});

/// Provider for UserProfileService
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

// ============================================================================
// USER PROFILE PROVIDERS
// ============================================================================

/// Stream provider for the current user's profile
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return UserProfile.fromFirestore(doc);
      });
});

/// Provider to get a specific user's profile by ID
final userProfileByIdProvider = StreamProvider.family<UserProfile?, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return UserProfile.fromFirestore(doc);
      });
});

// ============================================================================
// EVENTS PROVIDERS
// ============================================================================

/// Stream provider for the current user's events
final userEventsProvider = StreamProvider<List<Event>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('events')
      .where('createdBy', isEqualTo: userId)
      .orderBy('date')
      .snapshots()
      .map((snapshot) => 
          snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
});

/// Provider for events in a specific month
final eventsForMonthProvider = StreamProvider.family<List<Event>, DateTime>((ref, month) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  
  final startOfMonth = DateTime(month.year, month.month, 1);
  final endOfMonth = DateTime(month.year, month.month + 1, 0);
  
  final startDateString = _formatDateForFirestore(startOfMonth);
  final endDateString = _formatDateForFirestore(endOfMonth);
  
  return FirebaseFirestore.instance
      .collection('events')
      .where('createdBy', isEqualTo: userId)
      .where('date', isGreaterThanOrEqualTo: startDateString)
      .where('date', isLessThanOrEqualTo: endDateString)
      .orderBy('date')
      .snapshots()
      .map((snapshot) => 
          snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
});

/// Provider for a connected user's events (for connections calendar)
final connectedUserEventsProvider = StreamProvider.family<List<Event>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('events')
      .where('createdBy', isEqualTo: userId)
      .orderBy('date')
      .snapshots()
      .map((snapshot) => 
          snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
});

// ============================================================================
// CONNECTIONS PROVIDERS
// ============================================================================

/// Stream provider for the current user's accepted connections
final acceptedConnectionsProvider = StreamProvider<List<Connection>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('connections')
      .where('status', isEqualTo: 'accepted')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => Connection.fromJson(doc.data()))
            .where((connection) => 
                connection.requesterId == userId || connection.receiverId == userId)
            .toList();
      });
});

/// Stream provider for pending connection requests received by the current user
final pendingRequestsProvider = StreamProvider<List<Connection>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('connections')
      .where('receiverId', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => 
          snapshot.docs.map((doc) => Connection.fromJson(doc.data())).toList());
});

/// Stream provider for sent connection requests by the current user
final sentRequestsProvider = StreamProvider<List<Connection>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('connections')
      .where('requesterId', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) => 
          snapshot.docs.map((doc) => Connection.fromJson(doc.data())).toList());
});

/// Provider to get connected user IDs for the current user
final connectedUserIdsProvider = Provider<List<String>>((ref) {
  final connectionsAsync = ref.watch(acceptedConnectionsProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  return connectionsAsync.when(
    data: (connections) {
      if (userId == null) return [];
      return connections
          .map((c) => c.getOtherUserId(userId))
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

String _formatDateForFirestore(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
         '${date.month.toString().padLeft(2, '0')}-'
         '${date.day.toString().padLeft(2, '0')}';
}
