import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Get Google user email without signing in to Firebase
  // Returns the email if successful, null if cancelled
  Future<String?> getGoogleUserEmail() async {
    try {
      debugPrint('🔐 Getting Google user email...');
      
      // Sign out first to ensure fresh account picker
      await _googleSignIn.signOut();
      
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('❌ Google sign in cancelled by user');
        return null; // User cancelled
      }

      debugPrint('📧 Got Google email: ${googleUser.email}');
      return googleUser.email;
    } catch (e) {
      debugPrint('❌ Error getting Google email: $e');
      throw 'Failed to get Google account: ${e.toString()}';
    }
  }

  // Complete Google sign-in after email verification
  Future<UserCredential?> completeGoogleSignIn() async {
    try {
      debugPrint('🔐 Completing Google sign in...');
      
      // Get the current signed-in Google user
      final GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
      
      if (googleUser == null) {
        debugPrint('❌ No Google user found');
        throw 'No Google account selected. Please try again.';
      }

      // Get auth details from Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final UserCredential result = await _auth.signInWithCredential(credential);
      debugPrint('✅ Google sign in successful for: ${result.user?.email}');
      
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthError(e.code, e.message);
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
      throw 'Google sign in failed: ${e.toString()}';
    }
  }

  // Sign in with Google (legacy method - full flow in one step)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔐 Attempting Google sign in...');
      
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('❌ Google sign in cancelled by user');
        return null; // User cancelled
      }

      // Get auth details from Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final UserCredential result = await _auth.signInWithCredential(credential);
      debugPrint('✅ Google sign in successful for: ${result.user?.email}');
      
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthError(e.code, e.message);
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
      throw 'Google sign in failed: ${e.toString()}';
    }
  }

  // Sign out from Google only (not Firebase)
  Future<void> signOutGoogle() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        debugPrint('✅ Google sign out successful');
      }
    } catch (e) {
      debugPrint('❌ Google sign out error: $e');
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
      
      // Sign out from Google if was signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      await _auth.signOut();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Delete account and all user data
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user logged in';
      }
      
      debugPrint('🗑️ Deleting account for: ${user.email}');
      
      // Delete user data from Firestore
      final userId = user.uid;
      
      // Delete user profile
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete user's events
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('createdBy', isEqualTo: userId)
          .get();
      for (final doc in eventsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete user's connections (where user is requester or receiver)
      final sentConnections = await _firestore
          .collection('connections')
          .where('requesterId', isEqualTo: userId)
          .get();
      for (final doc in sentConnections.docs) {
        await doc.reference.delete();
      }
      
      final receivedConnections = await _firestore
          .collection('connections')
          .where('receiverId', isEqualTo: userId)
          .get();
      for (final doc in receivedConnections.docs) {
        await doc.reference.delete();
      }
      
      // Delete chat rooms where user is a participant
      final chatRooms = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: userId)
          .get();
      for (final doc in chatRooms.docs) {
        // Delete all messages in the chat room
        final messages = await doc.reference.collection('messages').get();
        for (final msg in messages.docs) {
          await msg.reference.delete();
        }
        await doc.reference.delete();
      }
      
      // Sign out from Google if was signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Finally delete the Firebase Auth account
      await user.delete();
      
      debugPrint('✅ Account and all data deleted successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException during delete: ${e.code} - ${e.message}');
      if (e.code == 'requires-recent-login') {
        throw 'Please sign out and sign in again before deleting your account.';
      }
      throw _handleAuthError(e.code, e.message);
    } catch (e) {
      debugPrint('❌ Delete account error: $e');
      throw 'Failed to delete account: ${e.toString()}';
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

