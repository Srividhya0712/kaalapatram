import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_calendar.dart';
import 'connections_calendar.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import 'notification_center.dart';
import 'manage_connections_screen.dart';
import 'language_settings_screen.dart';
import 'feedback_screen.dart';
import 'theme_settings_screen.dart';
import '../widgets/tour_overlay.dart';
import '../services/connection_service.dart';
import '../services/chat_service.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';
import '../services/presence_service.dart';
import '../models/user_profile.dart';
import '../l10n/generated/app_localizations.dart';
import 'login_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _myCalendarTourShown = false;
  bool _connectionsTourShown = false;
  
  // Notification counts
  int _pendingRequestsCount = 0;
  int _unreadChatsCount = 0;
  
  StreamSubscription? _pendingRequestsSubscription;
  StreamSubscription? _unreadChatsSubscription;
  
  final ConnectionService _connectionService = ConnectionService();
  final ChatService _chatService = ChatService();
  final UserProfileService _profileService = UserProfileService();
  final AuthService _authService = AuthService();
  final PresenceService _presenceService = PresenceService();
  
  String? _currentUserId;
  UserProfile? _userProfile;

  // Only 3 screens now - Profile moved to drawer
  final List<Widget> _screens = [
    const MyCalendar(),
    const ConnectionsCalendar(),
    const ChatListScreen(),
  ];

  // Global key for scaffold to open drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color goldColor = Color(0xFFD4AF37);
  static const Color tealColor = Color(0xFF26A69A);

  @override
  void initState() {
    super.initState();
    _checkAndShowTour();
    _loadNotificationCounts();
    _loadUserProfile();
    _initializePresence();
  }

  Future<void> _initializePresence() async {
    final profile = await _profileService.getProfileLocally();
    if (profile != null) {
      await _presenceService.initializePresence(profile.uid);
    }
  }

  @override
  void dispose() {
    _pendingRequestsSubscription?.cancel();
    _unreadChatsSubscription?.cancel();
    _presenceService.setOffline();
    _presenceService.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _profileService.getProfileLocally();
    if (mounted && profile != null) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  Future<void> _loadNotificationCounts() async {
    final profile = await _profileService.getProfileLocally();
    if (profile == null) return;
    
    _currentUserId = profile.uid;
    
    // Listen to pending connection requests
    _pendingRequestsSubscription = _connectionService
        .getPendingRequests(_currentUserId!)
        .listen((requests) {
      if (mounted) {
        setState(() {
          _pendingRequestsCount = requests.length;
        });
      }
    });
    
    // Listen to unread chat count
    _unreadChatsSubscription = _chatService
        .getTotalUnreadCount(_currentUserId!)
        .listen((count) {
      if (mounted) {
        setState(() {
          _unreadChatsCount = count;
        });
      }
    });
  }

  Future<void> _checkAndShowTour() async {
    final prefs = await SharedPreferences.getInstance();
    _myCalendarTourShown = prefs.getBool('my_calendar_tour_shown') ?? false;
    _connectionsTourShown = prefs.getBool('connections_tour_shown') ?? false;

    if (!_myCalendarTourShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMyCalendarTour();
      });
    }
  }

  void _showMyCalendarTour() {
    if (_myCalendarTourShown) return;
    showTour(context, TourSteps.myCalendarTour, () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('my_calendar_tour_shown', true);
      setState(() => _myCalendarTourShown = true);
    });
  }

  void _showConnectionsTour() {
    if (_connectionsTourShown) return;
    showTour(context, TourSteps.connectionsTour, () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('connections_tour_shown', true);
      setState(() => _connectionsTourShown = true);
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (index) {
        case 0:
          if (!_myCalendarTourShown) _showMyCalendarTour();
          break;
        case 1:
          if (!_connectionsTourShown) _showConnectionsTour();
          break;
      }
    });
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  label: AppLocalizations.of(context)?.calendar ?? 'Calendar',
                  color: goldColor,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.groups_outlined,
                  activeIcon: Icons.groups,
                  label: AppLocalizations.of(context)?.network ?? 'Network',
                  color: tealColor,
                  badgeCount: _pendingRequestsCount,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: AppLocalizations.of(context)?.chats ?? 'Chats',
                  color: const Color(0xFF5C6BC0),
                  badgeCount: _unreadChatsCount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return GestureDetector(
      onTap: () => _scaffoldKey.currentState?.openDrawer(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu, color: Colors.grey.shade600, size: 24),
            const SizedBox(height: 2),
            Text(
              'Menu',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header with user info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [goldColor, tealColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        _userProfile?.username.isNotEmpty == true
                            ? _userProfile!.username[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: goldColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userProfile?.username ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_userProfile?.profession.isNotEmpty == true)
                    Text(
                      _userProfile!.profession,
                      style: TextStyle(
                        color: Colors.white.withAlpha(204),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            
            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_alt,
                    title: 'Manage Connections',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ManageConnectionsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    badge: _pendingRequestsCount,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationCenterScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.color_lens,
                    title: 'Theme & Appearance',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ThemeSettingsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.language,
                    title: 'Language / மொழி',
                    subtitle: 'English / தமிழ்',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.feedback,
                    title: 'Feedback & Support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FeedbackScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      showAboutDialog(
                        context: context,
                        applicationName: 'Kaalapatram',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2024 Kaalapatram',
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Logout at bottom
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: _buildDrawerItem(
                icon: Icons.logout,
                title: 'Logout',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutConfirmation();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    int badge = 0,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: iconColor ?? Colors.grey.shade700),
          if (badge > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color color,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
              ? Border.all(color: color.withAlpha(51), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isSelected ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withAlpha(51) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? color : Colors.grey.shade500,
                    size: 22,
                  ),
                ),
                // Badge
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Label
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: isSelected 
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
