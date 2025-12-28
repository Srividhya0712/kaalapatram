import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin user model for Firestore-based authentication
class Admin {
  final String id;
  final String username;
  final String passwordHash;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  Admin({
    required this.id,
    required this.username,
    required this.passwordHash,
    this.role = 'super_admin',
    DateTime? createdAt,
    this.lastLoginAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Admin.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Admin(
      id: doc.id,
      username: data['username'] ?? '',
      passwordHash: data['passwordHash'] ?? '',
      role: data['role'] ?? 'super_admin',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'passwordHash': passwordHash,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastLoginAt != null) 'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
    };
  }

  Admin copyWith({DateTime? lastLoginAt}) {
    return Admin(
      id: id,
      username: username,
      passwordHash: passwordHash,
      role: role,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
