import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_task.dart';
import '../models/in_app_notification.dart';
import 'in_app_notification_service.dart';

/// Service for managing admin tasks
class AdminTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InAppNotificationService _notificationService = InAppNotificationService();
  
  static const String _tasksCollection = 'admin_tasks';
  static const String _adminsCollection = 'admins';

  /// Check if user is an admin
  Future<bool> isAdmin(String uid) async {
    final doc = await _firestore.collection(_adminsCollection).doc(uid).get();
    return doc.exists;
  }

  /// Create a new task and send notifications
  Future<String> createTask(AdminTask task) async {
    final docRef = _firestore.collection(_tasksCollection).doc();
    await docRef.set(task.toFirestore());
    
    // Send notification to perform head
    await _notificationService.sendNotification(
      userId: task.performHeadId,
      title: 'New Task Assigned',
      body: 'You have been assigned a new task: ${task.functionName} on ${task.englishDate.day}/${task.englishDate.month}/${task.englishDate.year}',
      type: NotificationType.taskAssigned,
      relatedTaskId: docRef.id,
    );
    
    // Send notification to assistant if assigned
    if (task.assistantId != null && task.assistantId!.isNotEmpty) {
      await _notificationService.sendNotification(
        userId: task.assistantId!,
        title: 'New Task Assigned (Assistant)',
        body: 'You have been assigned as assistant for: ${task.functionName}',
        type: NotificationType.taskAssigned,
        relatedTaskId: docRef.id,
      );
    }
    
    debugPrint('✅ Task created: ${docRef.id}');
    return docRef.id;
  }

  /// Get all tasks (for admin)
  Stream<List<AdminTask>> getAllTasks() {
    return _firestore
        .collection(_tasksCollection)
        .orderBy('englishDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminTask.fromFirestore(doc))
            .toList());
  }

  /// Get tasks filtered by username (for admin @mention filter)
  Stream<List<AdminTask>> getTasksByUsername(String username) {
    return _firestore
        .collection(_tasksCollection)
        .where('performHeadUsername', isEqualTo: username)
        .orderBy('englishDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminTask.fromFirestore(doc))
            .toList());
  }

  /// Get tasks assigned to a user (perform head or assistant)
  Stream<List<AdminTask>> getTasksForUser(String userId) {
    // Query for tasks where user is perform head or assistant
    return _firestore
        .collection(_tasksCollection)
        .where('performHeadId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminTask.fromFirestore(doc))
            .toList());
  }

  /// Get a single task by ID
  Future<AdminTask?> getTask(String taskId) async {
    final doc = await _firestore.collection(_tasksCollection).doc(taskId).get();
    if (!doc.exists) return null;
    return AdminTask.fromFirestore(doc);
  }

  /// Update task status (confirm/deny)
  Future<void> updateTaskStatus(String taskId, TaskStatus status, String adminId) async {
    await _firestore.collection(_tasksCollection).doc(taskId).update({
      'status': status.name,
    });
    
    // Get task details to notify admin
    final task = await getTask(taskId);
    if (task != null) {
      await _notificationService.sendNotification(
        userId: task.createdByAdminId,
        title: 'Task ${status == TaskStatus.confirmed ? 'Confirmed' : 'Denied'}',
        body: '${task.performHeadUsername} has ${status.name} the task: ${task.functionName}',
        type: status == TaskStatus.confirmed 
            ? NotificationType.taskConfirmed 
            : NotificationType.taskDenied,
        relatedTaskId: taskId,
      );
    }
    
    debugPrint('✅ Task status updated: $taskId -> ${status.name}');
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection(_tasksCollection).doc(taskId).delete();
    debugPrint('🗑️ Task deleted: $taskId');
  }

  /// Get upcoming tasks (sorted by date ascending)
  List<AdminTask> filterUpcoming(List<AdminTask> tasks) {
    return tasks
        .where((t) => t.isUpcoming)
        .toList()
      ..sort((a, b) => a.englishDate.compareTo(b.englishDate));
  }

  /// Get completed tasks (sorted by date descending)
  List<AdminTask> filterCompleted(List<AdminTask> tasks) {
    return tasks
        .where((t) => t.isCompleted)
        .toList()
      ..sort((a, b) => b.englishDate.compareTo(a.englishDate));
  }
}
