import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';

class EventService {
  static const String _collectionName = 'events';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get events collection reference
  CollectionReference get _eventsCollection => 
      _firestore.collection(_collectionName);

  // Stream of events for the current user
  Stream<List<Event>> getEventsStream() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _eventsCollection
        .where('createdBy', isEqualTo: userId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList());
  }

  // Get events for a specific date range
  Stream<List<Event>> getEventsForDateRange(DateTime startDate, DateTime endDate) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    final startDateString = _formatDateForFirestore(startDate);
    final endDateString = _formatDateForFirestore(endDate);

    return _eventsCollection
        .where('createdBy', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDateString)
        .where('date', isLessThanOrEqualTo: endDateString)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList());
  }

  // Get events for a specific user (for connections calendar)
  Stream<List<Event>> getUserEvents(String userId) {
    return _eventsCollection
        .where('createdBy', isEqualTo: userId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList());
  }

  // Get events for a specific month
  Stream<List<Event>> getEventsForMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    return getEventsForDateRange(startOfMonth, endOfMonth);
  }

  // Get event for a specific date
  Stream<Event?> getEventForDate(DateTime date) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }

    final dateString = _formatDateForFirestore(date);

    return _eventsCollection
        .where('createdBy', isEqualTo: userId)
        .where('date', isEqualTo: dateString)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Event.fromFirestore(snapshot.docs.first);
        });
  }

  // Create a new event
  Future<String> createEvent(Event event) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Ensure the event is created by the current user
    final eventWithUser = event.copyWith(createdBy: userId);
    
    try {
      final docRef = await _eventsCollection.add(eventWithUser.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Update an existing event
  Future<void> updateEvent(Event event) async {
    if (event.id == null) {
      throw Exception('Event ID is required for update');
    }

    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Verify the event belongs to the current user
      final doc = await _eventsCollection.doc(event.id).get();
      if (!doc.exists) {
        throw Exception('Event not found');
      }

      final eventData = doc.data() as Map<String, dynamic>;
      if (eventData['createdBy'] != userId) {
        throw Exception('Unauthorized to update this event');
      }

      // Update the event
      await _eventsCollection.doc(event.id).update(event.toMap());
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Verify the event belongs to the current user
      final doc = await _eventsCollection.doc(eventId).get();
      if (!doc.exists) {
        throw Exception('Event not found');
      }

      final eventData = doc.data() as Map<String, dynamic>;
      if (eventData['createdBy'] != userId) {
        throw Exception('Unauthorized to delete this event');
      }

      // Delete the event
      await _eventsCollection.doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Check if an event exists for a specific date
  Future<bool> hasEventForDate(DateTime date) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    final dateString = _formatDateForFirestore(date);

    try {
      final snapshot = await _eventsCollection
          .where('createdBy', isEqualTo: userId)
          .where('date', isEqualTo: dateString)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get all dates that have events for a specific month (for highlighting)
  Future<Set<DateTime>> getEventDatesForMonth(DateTime month) async {
    final userId = _currentUserId;
    if (userId == null) return {};

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    final startDateString = _formatDateForFirestore(startOfMonth);
    final endDateString = _formatDateForFirestore(endOfMonth);

    try {
      final snapshot = await _eventsCollection
          .where('createdBy', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDateString)
          .where('date', isLessThanOrEqualTo: endDateString)
          .get();

      return snapshot.docs
          .map((doc) => Event.fromFirestore(doc).date)
          .toSet();
    } catch (e) {
      return {};
    }
  }

  // Batch operations for better performance
  Future<void> createMultipleEvents(List<Event> events) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final batch = _firestore.batch();

    for (final event in events) {
      final eventWithUser = event.copyWith(createdBy: userId);
      final docRef = _eventsCollection.doc();
      batch.set(docRef, eventWithUser.toMap());
    }

    try {
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create multiple events: $e');
    }
  }

  // Helper method to format date for Firestore (ISO string)
  String _formatDateForFirestore(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  // Get events count for analytics
  Future<int> getEventsCount() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    try {
      final snapshot = await _eventsCollection
          .where('createdBy', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
