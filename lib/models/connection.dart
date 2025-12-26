import 'package:cloud_firestore/cloud_firestore.dart';

enum ConnectionStatus {
  pending,
  accepted,
  declined,
}

class Connection {
  final String id;
  final String requesterId; // User who sent the request
  final String receiverId; // User who received the request
  final String requesterUsername;
  final String receiverUsername;
  final ConnectionStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Connection({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.requesterUsername,
    required this.receiverUsername,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'receiverId': receiverId,
      'requesterUsername': requesterUsername,
      'receiverUsername': receiverUsername,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Helper to safely parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id']?.toString() ?? '',
      requesterId: json['requesterId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      requesterUsername: json['requesterUsername']?.toString() ?? '',
      receiverUsername: json['receiverUsername']?.toString() ?? '',
      status: ConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConnectionStatus.pending,
      ),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Connection copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    String? requesterUsername,
    String? receiverUsername,
    ConnectionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Connection(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      receiverId: receiverId ?? this.receiverId,
      requesterUsername: requesterUsername ?? this.requesterUsername,
      receiverUsername: receiverUsername ?? this.receiverUsername,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods to get the other user's info based on current user
  String getOtherUserUsername(String currentUserId) {
    return currentUserId == requesterId ? receiverUsername : requesterUsername;
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == requesterId ? receiverId : requesterId;
  }

  // Check if current user is the requester
  bool isRequester(String currentUserId) {
    return currentUserId == requesterId;
  }

  // Check if connection is active (accepted)
  bool get isActive => status == ConnectionStatus.accepted;
}
