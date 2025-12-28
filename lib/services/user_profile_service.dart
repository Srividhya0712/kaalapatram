import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static const String _profileKey = 'user_profile';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save profile to SharedPreferences
  Future<void> saveProfileLocally(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profileMap = profile.toFirestore();
    // Convert Timestamp to ISO string for local storage
    if (profileMap['createdAt'] is Timestamp) {
      profileMap['createdAt'] = (profileMap['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (profileMap['updatedAt'] is Timestamp) {
      profileMap['updatedAt'] = (profileMap['updatedAt'] as Timestamp).toDate().toIso8601String();
    }
    final profileJson = jsonEncode(profileMap);
    await prefs.setString(_profileKey, profileJson);
  }

  // Get profile from SharedPreferences
  Future<UserProfile?> getProfileLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);
    
    if (profileJson != null) {
      final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
      // Convert ISO string back to DateTime if needed
      if (profileMap['createdAt'] is String) {
        profileMap['createdAt'] = DateTime.parse(profileMap['createdAt']);
      }
      if (profileMap['updatedAt'] is String) {
        profileMap['updatedAt'] = DateTime.parse(profileMap['updatedAt']);
      }
      return UserProfile(
        uid: profileMap['uid'] ?? '',
        username: profileMap['username'] ?? '',
        email: profileMap['email'] ?? '',
        profession: profileMap['profession'] ?? '',
        bio: profileMap['bio'] ?? '',
        photoUrl: profileMap['photoUrl'] ?? '',
        createdAt: profileMap['createdAt'] is DateTime 
            ? profileMap['createdAt'] 
            : DateTime.now(),
        updatedAt: profileMap['updatedAt'] is DateTime 
            ? profileMap['updatedAt'] 
            : null,
      );
    }
    return null;
  }

  // Save profile to Firestore
  Future<void> saveProfileToFirestore(UserProfile profile) async {
    await _firestore
        .collection('users')
        .doc(profile.uid)
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  // Get profile from Firestore
  Future<UserProfile?> getProfileFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final existingUser = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    
    return existingUser.docs.isEmpty;
  }

  // Check if email is already registered (for Google Sign-In validation)
  Future<bool> isEmailRegistered(String email) async {
    final existingUser = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
    
    return existingUser.docs.isNotEmpty;
  }

  // Create and save new profile (both locally and Firestore)
  Future<void> createProfile({
    required String username,
    required String uid,
    required String email,
    String profession = '',
    String bio = '',
    String photoUrl = '',
  }) async {
    try {
      // Check if username is already taken
      final existingUser = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .get();
      
      if (existingUser.docs.isNotEmpty) {
        throw Exception('Username already taken');
      }

      final profile = UserProfile(
        uid: uid,
        username: username,
        email: email,
        profession: profession,
        bio: bio,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(profile.toFirestore());
      await saveProfileLocally(profile);
    } catch (e) {
      throw Exception('Failed to create profile: $e');
    }
  }

  // Update profile
  Future<void> updateProfile(UserProfile profile) async {
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    await saveProfileToFirestore(updatedProfile);
    await saveProfileLocally(updatedProfile);
  }

  // Update specific profile fields
  Future<void> updateProfileFields({
    required String uid,
    String? username,
    String? profession,
    String? bio,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (username != null) updates['username'] = username;
    if (profession != null) updates['profession'] = profession;
    if (bio != null) updates['bio'] = bio;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    await _firestore.collection('users').doc(uid).update(updates);
    
    // Sync to local storage
    final updatedProfile = await getProfileFromFirestore(uid);
    if (updatedProfile != null) {
      await saveProfileLocally(updatedProfile);
    }
  }

  // Clear local profile (for logout)
  Future<void> clearLocalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }

  // Check if profile exists locally
  Future<bool> hasLocalProfile() async {
    final profile = await getProfileLocally();
    return profile != null;
  }

  // Sync profile from Firestore to local storage
  Future<UserProfile?> syncProfile(String uid) async {
    final firestoreProfile = await getProfileFromFirestore(uid);
    if (firestoreProfile != null) {
      await saveProfileLocally(firestoreProfile);
    }
    return firestoreProfile;
  }

  // Search users by username or email
  Future<List<UserProfile>> searchUsers({
    required String query,
    required String currentUserId,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) return [];

    final queryLower = query.toLowerCase();
    
    // Search by username (prefix match)
    final usernameResults = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: queryLower)
        .where('username', isLessThanOrEqualTo: '$queryLower\uf8ff')
        .limit(limit)
        .get();

    // Search by email (prefix match)
    final emailResults = await _firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: queryLower)
        .where('email', isLessThanOrEqualTo: '$queryLower\uf8ff')
        .limit(limit)
        .get();

    // Combine and deduplicate results
    final uniqueProfiles = <String, UserProfile>{};
    
    for (final doc in usernameResults.docs) {
      if (doc.id != currentUserId && !uniqueProfiles.containsKey(doc.id)) {
        uniqueProfiles[doc.id] = UserProfile.fromFirestore(doc);
      }
    }
    
    for (final doc in emailResults.docs) {
      if (doc.id != currentUserId && !uniqueProfiles.containsKey(doc.id)) {
        uniqueProfiles[doc.id] = UserProfile.fromFirestore(doc);
      }
    }

    return uniqueProfiles.values.toList();
  }
}
