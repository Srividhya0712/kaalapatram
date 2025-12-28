import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/in_app_notification.dart';

/// Service for managing in-app notifications
class InAppNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _notificationsCollection = 'notifications';

  /// Send a notification to a user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedTaskId,
  }) async {
    final notification = InAppNotification(
      userId: userId,
      title: title,
      body: body,
      type: type,
      relatedTaskId: relatedTaskId,
    );

    await _firestore.collection(_notificationsCollection).add(notification.toFirestore());
    debugPrint('📬 Notification sent to $userId: $title');
  }

  /// Get notifications for a user
  Stream<List<InAppNotification>> getNotifications(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InAppNotification.fromFirestore(doc))
            .toList());
  }

  /// Get unread notification count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(_notificationsCollection).doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
    debugPrint('✅ Marked ${snapshot.docs.length} notifications as read');
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection(_notificationsCollection).doc(notificationId).delete();
  }

  /// Delete all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    debugPrint('🗑️ Cleared ${snapshot.docs.length} notifications');
  }
}
