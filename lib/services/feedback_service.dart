import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum FeedbackType { bug, feature, general, other }

class FeedbackItem {
  final String? id;
  final String userId;
  final String userEmail;
  final String userName;
  final FeedbackType type;
  final String subject;
  final String description;
  final String? deviceInfo;
  final String? appVersion;
  final DateTime createdAt;
  final String status; // pending, reviewed, resolved

  FeedbackItem({
    this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.type,
    required this.subject,
    required this.description,
    this.deviceInfo,
    this.appVersion,
    DateTime? createdAt,
    this.status = 'pending',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'type': type.name,
      'subject': subject,
      'description': description,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status,
    };
  }

  factory FeedbackItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      type: FeedbackType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => FeedbackType.other,
      ),
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      deviceInfo: data['deviceInfo'],
      appVersion: data['appVersion'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }
}

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit feedback
  Future<void> submitFeedback(FeedbackItem feedback) async {
    try {
      debugPrint('📝 Submitting feedback: ${feedback.subject}');
      await _firestore.collection('feedback').add(feedback.toFirestore());
      debugPrint('✅ Feedback submitted successfully');
    } catch (e) {
      debugPrint('❌ Failed to submit feedback: $e');
      throw 'Failed to submit feedback: $e';
    }
  }

  // Get user's feedback history
  Stream<List<FeedbackItem>> getUserFeedback(String userId) {
    return _firestore
        .collection('feedback')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FeedbackItem.fromFirestore(doc)).toList();
    });
  }

  // Get all feedback (admin only)
  Stream<List<FeedbackItem>> getAllFeedback() {
    return _firestore
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FeedbackItem.fromFirestore(doc)).toList();
    });
  }

  // Update feedback status (admin only)
  Future<void> updateFeedbackStatus(String feedbackId, String status) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).update({
        'status': status,
      });
    } catch (e) {
      throw 'Failed to update feedback status: $e';
    }
  }
}
