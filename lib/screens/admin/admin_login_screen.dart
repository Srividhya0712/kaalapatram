import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_auth_provider.dart';
import 'admin_dashboard_screen.dart';

/// Admin login screen with username/password authentication (no Firebase Auth)
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;

  // Theme colors
  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    // Check if already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isLoggedIn = ref.read(isAdminLoggedInProvider);
      if (isLoggedIn) {
        _navigateToDashboard();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear any previous error
    ref.read(adminAuthProvider.notifier).clearError();

    final success = await ref.read(adminAuthProvider.notifier).login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      _navigateToDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthProvider);

    return Scaffold(
      backgroundColor: burgundy,
      appBar: AppBar(
        backgroundColor: burgundy,
        foregroundColor: gold,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                // Admin icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: gold, width: 3),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 50,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'Super Admin',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login with admin credentials',
                  style: TextStyle(
                    fontSize: 14,
                    color: gold.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Error message
                if (authState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Username field
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: gold,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF3D1A1A),
                    labelText: 'Username',
                    labelStyle: TextStyle(color: gold.withAlpha(180)),
                    prefixIcon: const Icon(Icons.person, color: gold),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: gold),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: gold.withAlpha(128)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: gold, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: gold,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF3D1A1A),
                    labelText: 'Password',
                    labelStyle: TextStyle(color: gold.withAlpha(180)),
                    prefixIcon: const Icon(Icons.lock, color: gold),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: gold,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: gold),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: gold.withAlpha(128)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: gold, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: burgundy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: burgundy,
                            ),
                          )
                        : const Text(
                            'Login as Admin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Footer note
                Text(
                  'Only authorized administrators can access this panel.\nNo email verification required.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: gold.withAlpha(128),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
