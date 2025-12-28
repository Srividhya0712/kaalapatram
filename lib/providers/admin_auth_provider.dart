import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin.dart';
import '../services/admin_auth_service.dart';

/// State class for admin authentication
class AdminAuthState {
  final Admin? admin;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  AdminAuthState({
    this.admin,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });

  AdminAuthState copyWith({
    Admin? admin,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) {
    return AdminAuthState(
      admin: admin ?? this.admin,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  /// Initial state
  factory AdminAuthState.initial() => AdminAuthState();

  /// Loading state
  factory AdminAuthState.loading() => AdminAuthState(isLoading: true);

  /// Logged in state
  factory AdminAuthState.loggedIn(Admin admin) => AdminAuthState(
        admin: admin,
        isLoggedIn: true,
      );

  /// Error state
  factory AdminAuthState.error(String message) => AdminAuthState(error: message);
}

/// Notifier for admin authentication state
class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final AdminAuthService _authService;

  AdminAuthNotifier(this._authService) : super(AdminAuthState.initial()) {
    // Check for existing session on startup
    _checkSession();
  }

  /// Check if admin is already logged in (from session)
  Future<void> _checkSession() async {
    state = AdminAuthState.loading();
    final admin = await _authService.getCurrentAdmin();
    if (admin != null) {
      state = AdminAuthState.loggedIn(admin);
    } else {
      state = AdminAuthState.initial();
    }
  }

  /// Login with username and password
  Future<bool> login(String username, String password) async {
    state = AdminAuthState.loading();

    final admin = await _authService.login(username, password);

    if (admin != null) {
      state = AdminAuthState.loggedIn(admin);
      return true;
    } else {
      state = AdminAuthState.error('Invalid username or password');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    state = AdminAuthState.initial();
  }

  /// Clear error
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Provider for AdminAuthService
final adminAuthServiceProvider = Provider<AdminAuthService>((ref) {
  return AdminAuthService();
});

/// Provider for admin authentication state
final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  final authService = ref.watch(adminAuthServiceProvider);
  return AdminAuthNotifier(authService);
});

/// Convenience provider to check if admin is logged in
final isAdminLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(adminAuthProvider).isLoggedIn;
});

/// Convenience provider to get current admin
final currentAdminProvider = Provider<Admin?>((ref) {
  return ref.watch(adminAuthProvider).admin;
});
