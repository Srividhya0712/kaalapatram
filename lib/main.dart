import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/onboarding_screen.dart';
import 'providers/theme_provider.dart';

// Global navigator key for handling navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  bool firebaseInitialized = false;
  String? errorMessage;
  bool hasSeenOnboarding = false;
  
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');
    
    // Check if user has seen onboarding
    final prefs = await SharedPreferences.getInstance();
    hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    debugPrint('📱 Has seen onboarding: $hasSeenOnboarding');
  } catch (e) {
    errorMessage = e.toString();
    debugPrint('❌ Firebase initialization failed: $e');
    firebaseInitialized = false;
  }
  
  runApp(
    ProviderScope(
      child: KaalapatramApp(
        firebaseInitialized: firebaseInitialized,
        errorMessage: errorMessage,
        hasSeenOnboarding: hasSeenOnboarding,
      ),
    ),
  );
}

// App Theme Colors
class AppColors {
  // Primary Gold Theme
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFF5E6A3);
  static const Color darkGold = Color(0xFFB8960C);
  
  // Secondary Colors for visual distinction
  static const Color connectionsTeal = Color(0xFF26A69A);
  static const Color connectionsLight = Color(0xFFB2DFDB);
  
  // Surface Colors
  static const Color surfaceLight = Color(0xFFFFF9E6);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color onSurfaceLight = Color(0xFF1A1A1A);
  static const Color onSurfaceDark = Color(0xFFF5F5F5);
}

class KaalapatramApp extends StatefulWidget {
  final bool firebaseInitialized;
  final String? errorMessage;
  final bool hasSeenOnboarding;
  
  const KaalapatramApp({
    super.key, 
    required this.firebaseInitialized,
    this.errorMessage,
    required this.hasSeenOnboarding,
  });

  @override
  State<KaalapatramApp> createState() => _KaalapatramAppState();
}

class _KaalapatramAppState extends State<KaalapatramApp> {
  late bool _hasSeenOnboarding;
  
  @override
  void initState() {
    super.initState();
    _hasSeenOnboarding = widget.hasSeenOnboarding;
    
    // Listen to auth state changes and navigate accordingly
    if (widget.firebaseInitialized) {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        debugPrint('🔄 Auth state changed: ${user?.email ?? 'null'}');
        
        if (navigatorKey.currentState != null && _hasSeenOnboarding) {
          if (user != null) {
            debugPrint('👤 User logged in - navigating to MainNavigation');
            navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainNavigation()),
              (route) => false,
            );
          } else {
            debugPrint('🚪 User logged out - navigating to LoginScreen');
            navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _hasSeenOnboarding = true;
    });
    
    // Navigate to the appropriate screen after onboarding
    if (navigatorKey.currentState != null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (route) => false,
        );
      } else {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  ThemeData _buildLightTheme() {
    final baseTheme = ThemeData.light(useMaterial3: true);
    
    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGold,
        primary: AppColors.primaryGold,
        primaryContainer: AppColors.lightGold,
        secondary: AppColors.connectionsTeal,
        secondaryContainer: AppColors.connectionsLight,
        surface: Colors.white,
        onSurface: AppColors.onSurfaceLight,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: AppColors.onSurfaceLight,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: AppColors.onSurfaceLight,
        ),
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceLight,
        ),
        bodyLarge: GoogleFonts.poppins(color: AppColors.onSurfaceLight),
        bodyMedium: GoogleFonts.poppins(color: AppColors.onSurfaceLight),
      ),
      scaffoldBackgroundColor: AppColors.surfaceLight,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: AppColors.primaryGold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGold,
          side: const BorderSide(color: AppColors.primaryGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withAlpha(26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryGold,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: AppColors.darkGold,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    
    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGold,
        primary: AppColors.primaryGold,
        primaryContainer: AppColors.darkGold,
        secondary: AppColors.connectionsTeal,
        secondaryContainer: const Color(0xFF004D40),
        surface: const Color(0xFF1E1E1E),
        onSurface: AppColors.onSurfaceDark,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: AppColors.onSurfaceDark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: AppColors.onSurfaceDark,
        ),
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceDark,
        ),
        bodyLarge: GoogleFonts.poppins(color: AppColors.onSurfaceDark),
        bodyMedium: GoogleFonts.poppins(color: AppColors.onSurfaceDark),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: AppColors.primaryGold,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryGold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: AppColors.primaryGold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGold,
          side: const BorderSide(color: AppColors.primaryGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withAlpha(26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF2C2C2C),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: AppColors.primaryGold,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: AppColors.primaryGold,
        contentTextStyle: GoogleFonts.poppins(color: Colors.black),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _getInitialScreen() {
    if (!widget.firebaseInitialized) {
      return FirebaseErrorScreen(errorMessage: widget.errorMessage);
    }
    
    // Show onboarding for first-time users
    if (!_hasSeenOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }
    
    // Check current auth state
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('🔍 Initial auth check: ${currentUser?.email ?? 'not logged in'}');
    
    if (currentUser != null) {
      return const MainNavigation();
    }
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaalapatram - காலப்பட்டிரம்',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      themeMode: ThemeMode.light, // Always use light mode
      home: _getInitialScreen(),
    );
  }
}

class FirebaseErrorScreen extends StatelessWidget {
  final String? errorMessage;
  
  const FirebaseErrorScreen({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Error'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 100,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Firebase Configuration Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please ensure that google-services.json is properly configured in your Android project.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withAlpha(77)),
                  ),
                  child: Text(
                    'Error: $errorMessage',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
