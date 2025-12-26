import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String username;
  final String email;
  final String profession;
  final String bio;
  final String photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.username,
    this.email = '',
    this.profession = '',
    this.bio = '',
    this.photoUrl = '',
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'profession': profession,
      'bio': bio,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: data['uid']?.toString() ?? doc.id,
      username: data['username']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      profession: data['profession']?.toString() ?? '',
      bio: data['bio']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString() ?? '',
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      profession: data['profession']?.toString() ?? '',
      bio: data['bio']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString() ?? '',
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  UserProfile copyWith({
    String? uid,
    String? username,
    String? email,
    String? profession,
    String? bio,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      profession: profession ?? this.profession,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get initials from username for avatar placeholder
  String get initials {
    if (username.isEmpty) return '?';
    final parts = username.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username[0].toUpperCase();
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, username: $username, profession: $profession)';
  }
}
