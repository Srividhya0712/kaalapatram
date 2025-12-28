import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of an admin task
enum TaskStatus { pending, confirmed, denied }

/// Model for admin-assigned tasks to perform heads
class AdminTask {
  final String? id;
  final DateTime englishDate;
  final String tamilDate;
  final String time;
  final String functionName;
  final String city;
  final String clientContact;
  final double budget;
  final String performHeadUsername;
  final String performHeadId;
  final String headContact;
  final String? assistantUsername;
  final String? assistantId;
  final String? assistantContact;
  final String details;
  final String transport;
  final TaskStatus status;
  final DateTime createdAt;
  final String createdByAdminId;

  AdminTask({
    this.id,
    required this.englishDate,
    required this.tamilDate,
    required this.time,
    required this.functionName,
    required this.city,
    required this.clientContact,
    required this.budget,
    required this.performHeadUsername,
    required this.performHeadId,
    required this.headContact,
    this.assistantUsername,
    this.assistantId,
    this.assistantContact,
    required this.details,
    required this.transport,
    this.status = TaskStatus.pending,
    DateTime? createdAt,
    required this.createdByAdminId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AdminTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminTask(
      id: doc.id,
      englishDate: (data['englishDate'] as Timestamp).toDate(),
      tamilDate: data['tamilDate'] ?? '',
      time: data['time'] ?? '',
      functionName: data['functionName'] ?? '',
      city: data['city'] ?? '',
      clientContact: data['clientContact'] ?? '',
      budget: (data['budget'] ?? 0).toDouble(),
      performHeadUsername: data['performHeadUsername'] ?? '',
      performHeadId: data['performHeadId'] ?? '',
      headContact: data['headContact'] ?? '',
      assistantUsername: data['assistantUsername'],
      assistantId: data['assistantId'],
      assistantContact: data['assistantContact'],
      details: data['details'] ?? '',
      transport: data['transport'] ?? '',
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdByAdminId: data['createdByAdminId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'englishDate': Timestamp.fromDate(englishDate),
      'tamilDate': tamilDate,
      'time': time,
      'functionName': functionName,
      'city': city,
      'clientContact': clientContact,
      'budget': budget,
      'performHeadUsername': performHeadUsername,
      'performHeadId': performHeadId,
      'headContact': headContact,
      'assistantUsername': assistantUsername,
      'assistantId': assistantId,
      'assistantContact': assistantContact,
      'details': details,
      'transport': transport,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'createdByAdminId': createdByAdminId,
    };
  }

  static TaskStatus _parseStatus(String? status) {
    switch (status) {
      case 'confirmed':
        return TaskStatus.confirmed;
      case 'denied':
        return TaskStatus.denied;
      default:
        return TaskStatus.pending;
    }
  }

  AdminTask copyWith({
    TaskStatus? status,
  }) {
    return AdminTask(
      id: id,
      englishDate: englishDate,
      tamilDate: tamilDate,
      time: time,
      functionName: functionName,
      city: city,
      clientContact: clientContact,
      budget: budget,
      performHeadUsername: performHeadUsername,
      performHeadId: performHeadId,
      headContact: headContact,
      assistantUsername: assistantUsername,
      assistantId: assistantId,
      assistantContact: assistantContact,
      details: details,
      transport: transport,
      status: status ?? this.status,
      createdAt: createdAt,
      createdByAdminId: createdByAdminId,
    );
  }

  /// Check if task is upcoming (date is today or in future)
  bool get isUpcoming => englishDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));

  /// Check if task is completed (date is in past)
  bool get isCompleted => !isUpcoming;
}
