import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/admin_task.dart';
import '../services/admin_task_service.dart';

/// Screen showing tasks assigned to the current user
class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  final AdminTaskService _taskService = AdminTaskService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  List<AdminTask> _myTasks = [];
  bool _isLoading = true;

  // Theme colors
  static const Color goldColor = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    if (_currentUserId == null) return;
    
    _taskService.getTasksForUser(_currentUserId!).listen((tasks) {
      if (mounted) {
        setState(() {
          _myTasks = tasks;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _confirmTask(AdminTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Task'),
        content: Text('Are you sure you want to confirm the task "${task.functionName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && task.id != null) {
      await _taskService.updateTaskStatus(task.id!, TaskStatus.confirmed, _currentUserId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task confirmed!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _denyTask(AdminTask task) async {
    final denied = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deny Task'),
        content: Text('Are you sure you want to deny the task "${task.functionName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deny'),
          ),
        ],
      ),
    );

    if (denied == true && task.id != null) {
      await _taskService.updateTaskStatus(task.id!, TaskStatus.denied, _currentUserId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task denied'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _callClient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: goldColor,
        foregroundColor: Colors.white,
        title: const Text('My Tasks'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: goldColor))
          : _myTasks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myTasks.length,
                  itemBuilder: (context, index) => _buildTaskCard(_myTasks[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No tasks assigned to you',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new assignments',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(AdminTask task) {
    final statusColor = _getStatusColor(task.status);
    final isPending = task.status == TaskStatus.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: goldColor.withAlpha(26),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.functionName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(task.englishDate),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(task.time, style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    task.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tamil Date
                Row(
                  children: [
                    const Icon(Icons.date_range, size: 18, color: goldColor),
                    const SizedBox(width: 8),
                    Text(task.tamilDate, style: const TextStyle(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),

                // City
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(task.city, style: const TextStyle(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),

                // Client Contact
                GestureDetector(
                  onTap: () => _callClient(task.clientContact),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        task.clientContact,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.green,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Budget
                Row(
                  children: [
                    const Icon(Icons.currency_rupee, size: 18, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      '₹${task.budget.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Details
                if (task.details.isNotEmpty) ...[
                  const Text(
                    'Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(task.details),
                  const SizedBox(height: 12),
                ],

                // Transport
                if (task.transport.isNotEmpty) ...[
                  const Text(
                    'Transport:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(task.transport),
                ],
              ],
            ),
          ),

          // Action buttons (only for pending tasks)
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _denyTask(task),
                      icon: const Icon(Icons.close),
                      label: const Text('Deny'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmTask(task),
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.confirmed:
        return Colors.green;
      case TaskStatus.denied:
        return Colors.red;
    }
  }
}
