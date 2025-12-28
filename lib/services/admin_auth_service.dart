import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin.dart';

/// Service for admin authentication using Firestore (not Firebase Auth)
class AdminAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _adminsCollection = 'admins';
  static const String _adminSessionKey = 'admin_session';

  /// Hash password using SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify password against hash
  bool verifyPassword(String password, String hash) {
    return hashPassword(password) == hash;
  }

  /// Login with username and password
  /// Returns Admin if successful, null otherwise
  Future<Admin?> login(String username, String password) async {
    try {
      debugPrint('🔐 Admin login attempt: $username');

      // Query Firestore for admin with this username
      final querySnapshot = await _firestore
          .collection(_adminsCollection)
          .where('username', isEqualTo: username.toLowerCase().trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ Admin not found: $username');
        return null;
      }

      final adminDoc = querySnapshot.docs.first;
      final admin = Admin.fromFirestore(adminDoc);

      // Verify password
      if (!verifyPassword(password, admin.passwordHash)) {
        debugPrint('❌ Invalid password for admin: $username');
        return null;
      }

      // Update last login time
      await adminDoc.reference.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Save session locally
      await _saveSession(admin);

      debugPrint('✅ Admin logged in: ${admin.username}');
      return admin;
    } catch (e) {
      debugPrint('❌ Admin login error: $e');
      return null;
    }
  }

  /// Logout admin
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminSessionKey);
    debugPrint('👋 Admin logged out');
  }

  /// Get current logged-in admin from session
  Future<Admin?> getCurrentAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_adminSessionKey);

      if (sessionData == null) return null;

      final sessionJson = jsonDecode(sessionData) as Map<String, dynamic>;
      final adminId = sessionJson['id'] as String?;

      if (adminId == null) return null;

      // Verify admin still exists in Firestore
      final adminDoc = await _firestore
          .collection(_adminsCollection)
          .doc(adminId)
          .get();

      if (!adminDoc.exists) {
        await logout();
        return null;
      }

      return Admin.fromFirestore(adminDoc);
    } catch (e) {
      debugPrint('❌ Error getting current admin: $e');
      return null;
    }
  }

  /// Check if user is currently logged in as admin
  Future<bool> isAdminLoggedIn() async {
    final admin = await getCurrentAdmin();
    return admin != null;
  }

  /// Save admin session locally
  Future<void> _saveSession(Admin admin) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = jsonEncode({
      'id': admin.id,
      'username': admin.username,
      'role': admin.role,
    });
    await prefs.setString(_adminSessionKey, sessionData);
  }

  /// Create a new admin (for setup/registration)
  Future<String?> createAdmin({
    required String username,
    required String password,
    String role = 'super_admin',
  }) async {
    try {
      // Check if username already exists
      final existing = await _firestore
          .collection(_adminsCollection)
          .where('username', isEqualTo: username.toLowerCase().trim())
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint('❌ Admin username already exists: $username');
        return null;
      }

      // Create admin document
      final docRef = _firestore.collection(_adminsCollection).doc();
      final admin = Admin(
        id: docRef.id,
        username: username.toLowerCase().trim(),
        passwordHash: hashPassword(password),
        role: role,
      );

      await docRef.set(admin.toFirestore());
      debugPrint('✅ Admin created: ${admin.username}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating admin: $e');
      return null;
    }
  }
}
