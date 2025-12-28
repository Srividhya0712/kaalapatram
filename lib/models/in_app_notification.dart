import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of in-app notifications
enum NotificationType { taskAssigned, taskConfirmed, taskDenied, general }

/// Model for in-app notifications stored in Firestore
class InAppNotification {
  final String? id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedTaskId;
  final bool isRead;
  final DateTime createdAt;

  InAppNotification({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedTaskId,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory InAppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InAppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: _parseType(data['type']),
      relatedTaskId: data['relatedTaskId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'relatedTaskId': relatedTaskId,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'taskAssigned':
        return NotificationType.taskAssigned;
      case 'taskConfirmed':
        return NotificationType.taskConfirmed;
      case 'taskDenied':
        return NotificationType.taskDenied;
      default:
        return NotificationType.general;
    }
  }

  InAppNotification copyWith({bool? isRead}) {
    return InAppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      relatedTaskId: relatedTaskId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
