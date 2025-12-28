// Admin Setup Script
// Run this once to create your admin account in Firestore
//
// Usage:
// 1. Run: flutter run -t lib/scripts/setup_admin.dart
// 2. Enter username and password
// 3. Click "Create Admin Account"

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (same as main.dart)
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Firebase error: $e');
  }
  
  runApp(const AdminSetupApp());
}

class AdminSetupApp extends StatelessWidget {
  const AdminSetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Setup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF800020)),
      ),
      home: const AdminSetupScreen(),
    );
  }
}

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _result;
  String? _passwordHash;

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _showHash() {
    if (_passwordController.text.isNotEmpty) {
      setState(() {
        _passwordHash = hashPassword(_passwordController.text);
      });
    }
  }

  Future<void> _createAdmin() async {
    if (_usernameController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _result = '❌ Please enter both username and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final username = _usernameController.text.trim().toLowerCase();
      
      // Check if username exists
      final existing = await firestore
          .collection('admins')
          .where('username', isEqualTo: username)
          .get();

      if (existing.docs.isNotEmpty) {
        setState(() {
          _result = '❌ Admin username already exists!';
          _isLoading = false;
        });
        return;
      }

      // Create admin
      final docRef = firestore.collection('admins').doc();
      await docRef.set({
        'username': username,
        'passwordHash': hashPassword(_passwordController.text),
        'role': 'super_admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _result = '✅ Admin created successfully!\n\n'
            'Admin ID: ${docRef.id}\n'
            'Username: $username\n\n'
            'You can now login with these credentials.';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF800020),
      appBar: AppBar(
        title: const Text('Admin Setup', style: TextStyle(color: Color(0xFFD4AF37))),
        backgroundColor: const Color(0xFF800020),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.admin_panel_settings, size: 80, color: Color(0xFFD4AF37)),
            const SizedBox(height: 16),
            const Text(
              'Create Super Admin',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Username field
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                prefixIcon: const Icon(Icons.person, color: Color(0xFFD4AF37)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Password field
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => _showHash(),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                prefixIcon: const Icon(Icons.lock, color: Color(0xFFD4AF37)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Show password hash
            if (_passwordHash != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SHA-256 Hash:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    SelectableText(
                      _passwordHash!,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Create button
            ElevatedButton(
              onPressed: _isLoading ? null : _createAdmin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF800020),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF800020))
                  : const Text('Create Admin Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            
            // Result message
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _result!.startsWith('✅') ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _result!.startsWith('✅') ? Colors.green : Colors.red),
                ),
                child: Text(
                  _result!,
                  style: TextStyle(color: _result!.startsWith('✅') ? Colors.green.shade100 : Colors.red.shade100),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
