import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool showSignupMessage;
  final String? googleDisplayName;
  final String? googleEmail;
  
  const RegisterScreen({
    super.key, 
    this.showSignupMessage = false,
    this.googleDisplayName,
    this.googleEmail,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _professionController = TextEditingController();
  final _bioController = TextEditingController();
  final _authService = AuthService();
  final _profileService = UserProfileService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _usernameAvailable = true;
  bool _checkingUsername = false;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill email from Google Sign-In
    if (widget.googleEmail != null) {
      _emailController.text = widget.googleEmail!;
    }
    
    // Generate username from Google display name
    if (widget.googleDisplayName != null) {
      _generateAndSetUsername(widget.googleDisplayName!);
    }
    
    // Show signup message if redirected from Google Sign-In
    if (widget.showSignupMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Please sign up first!')),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      });
    }
  }

  /// Generates a unique username from Google display name
  Future<void> _generateAndSetUsername(String displayName) async {
    String baseUsername = _sanitizeUsername(displayName);
    
    if (baseUsername.length < 3) {
      baseUsername = 'user${Random().nextInt(9999)}';
    }
    
    String candidateUsername = baseUsername;
    int attempts = 0;
    
    while (attempts < 10) {
      final isAvailable = await _profileService.isUsernameAvailable(candidateUsername);
      if (isAvailable) {
        if (mounted) {
          setState(() {
            _usernameController.text = candidateUsername;
            _usernameAvailable = true;
          });
        }
        return;
      }
      // Append random numbers if username is taken
      candidateUsername = '${baseUsername}_${Random().nextInt(999)}';
      attempts++;
    }
    
    // Fallback: use base username with timestamp
    candidateUsername = '${baseUsername}_${DateTime.now().millisecondsSinceEpoch % 10000}';
    if (mounted) {
      setState(() {
        _usernameController.text = candidateUsername;
      });
      _checkUsernameAvailability(candidateUsername);
    }
  }

  /// Sanitizes display name to create valid username
  String _sanitizeUsername(String displayName) {
    final sanitized = displayName
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    // Limit to 15 characters
    return sanitized.length > 15 ? sanitized.substring(0, 15) : sanitized;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _professionController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.trim().length < 3) {
      setState(() {
        _usernameAvailable = true;
        _checkingUsername = false;
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
    });

    try {
      final isAvailable = await _profileService.isUsernameAvailable(username.trim());
      if (mounted) {
        setState(() {
          _usernameAvailable = isAvailable;
          _checkingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingUsername = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _errorMessage = null;
    });
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_usernameAvailable) {
      setState(() {
        _errorMessage = 'Username is already taken. Please choose another.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('📝 Starting registration...');
      
      // Step 1: Create Firebase Auth account
      final credential = await _authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (credential?.user == null) {
        throw Exception('Failed to create account');
      }

      debugPrint('✅ Firebase Auth user created: ${credential!.user!.uid}');

      // Step 2: Create Firestore profile
      await _profileService.createProfile(
        uid: credential.user!.uid,
        username: _usernameController.text.trim().toLowerCase(),
        email: _emailController.text.trim().toLowerCase(),
        profession: _professionController.text.trim(),
        bio: _bioController.text.trim(),
      );

      debugPrint('✅ Firestore profile created');

      // Step 3: Send verification email
      try {
        await credential.user!.sendEmailVerification();
        debugPrint('✅ Verification email sent');
      } catch (e) {
        debugPrint('⚠️ Verification email failed: $e');
      }

      // Step 4: Navigate to verification screen
      if (mounted) {
        debugPrint('🔄 Navigating to verification screen...');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      
      // Clean up: if profile creation failed but auth succeeded, delete auth user
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && e.toString().contains('profile')) {
          await user.delete();
        }
      } catch (_) {}
      
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('email-already-in-use')) {
          errorMsg = 'This email is already registered. Please sign in.';
        } else if (errorMsg.contains('Username already taken')) {
          errorMsg = 'This username is already taken. Please choose another.';
        } else if (errorMsg.contains('weak-password')) {
          errorMsg = 'Password is too weak. Please use a stronger password.';
        }
        
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Join Kaalapatram',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your account to start managing your work calendar',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(179),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => setState(() => _errorMessage = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                
                // Username Field with availability check
                TextFormField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  autocorrect: false,
                  onChanged: (value) {
                    // Debounce username check
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_usernameController.text == value) {
                        _checkUsernameAvailability(value);
                      }
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Username *',
                    hintText: 'Choose a unique username',
                    prefixIcon: const Icon(Icons.person_outlined),
                    suffixIcon: _checkingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _usernameController.text.length >= 3
                            ? Icon(
                                _usernameAvailable ? Icons.check_circle : Icons.cancel,
                                color: _usernameAvailable ? Colors.green : Colors.red,
                              )
                            : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                      return 'Only letters, numbers, and underscores allowed';
                    }
                    if (!_usernameAvailable) {
                      return 'Username is already taken';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!AuthService.isValidEmail(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Profession Field
                TextFormField(
                  controller: _professionController,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Profession',
                    hintText: 'What do you do? (Optional)',
                    prefixIcon: Icon(Icons.work_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Bio Field
                TextFormField(
                  controller: _bioController,
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself (Optional)',
                    prefixIcon: Icon(Icons.info_outlined),
                    alignLabelWithHint: true,
                  ),
                  maxLength: 150,
                ),
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    hintText: 'Min 6 characters',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword 
                          ? Icons.visibility_outlined 
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  onFieldSubmitted: (_) => _signUp(),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword 
                          ? Icons.visibility_outlined 
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Sign Up Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Creating Account...'),
                            ],
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(179)),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
