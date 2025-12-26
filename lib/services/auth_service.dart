import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Attempting sign in for: $email');
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('✅ Sign in successful for: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthError(e.code, e.message);
    } catch (e) {
      debugPrint('❌ Unknown error during sign in: $e');
      throw 'Sign in failed: ${e.toString()}';
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📝 Creating account for: $email');
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('✅ Account created for: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthError(e.code, e.message);
    } catch (e) {
      debugPrint('❌ Unknown error during registration: $e');
      throw 'Registration failed: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Signing out user: ${_auth.currentUser?.email}');
      await _auth.signOut();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      debugPrint('📧 Sending password reset to: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('✅ Password reset email sent');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthError(e.code, e.message);
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      throw 'Failed to send reset email: ${e.toString()}';
    }
  }

  // Handle Firebase Auth error codes and return user-friendly messages
  String _handleAuthError(String code, String? message) {
    debugPrint('🔍 Handling auth error code: $code');
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address. Please enter a valid email.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid email or password. Please check and try again.';
      default:
        return message ?? 'Authentication failed. Please try again.';
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Validate password confirmation
  static bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }
}
