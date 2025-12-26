import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_calendar.dart';
import 'connections_calendar.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import 'notification_center.dart';
import '../widgets/tour_overlay.dart';
import '../services/connection_service.dart';
import '../services/chat_service.dart';
import '../services/user_profile_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _myCalendarTourShown = false;
  bool _connectionsTourShown = false;
  bool _profileTourShown = false;
  
  // Notification counts
  int _pendingRequestsCount = 0;
  int _unreadChatsCount = 0;
  
  StreamSubscription? _pendingRequestsSubscription;
  StreamSubscription? _unreadChatsSubscription;
  
  final ConnectionService _connectionService = ConnectionService();
  final ChatService _chatService = ChatService();
  final UserProfileService _profileService = UserProfileService();
  String? _currentUserId;

  final List<Widget> _screens = [
    const MyCalendar(),
    const ConnectionsCalendar(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAndShowTour();
    _loadNotificationCounts();
  }

  @override
  void dispose() {
    _pendingRequestsSubscription?.cancel();
    _unreadChatsSubscription?.cancel();
    super.dispose();
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
    _profileTourShown = prefs.getBool('profile_tour_shown') ?? false;

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

  void _showProfileTour() {
    if (_profileTourShown) return;
    showTour(context, TourSteps.profileTour, () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_tour_shown', true);
      setState(() => _profileTourShown = true);
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
        case 3:
          if (!_profileTourShown) _showProfileTour();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  label: 'My Calendar',
                  color: const Color(0xFFD4AF37),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.groups_outlined,
                  activeIcon: Icons.groups,
                  label: 'Network',
                  color: const Color(0xFF26A69A),
                  badgeCount: _pendingRequestsCount, // Connection requests badge
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Chats',
                  color: const Color(0xFF5C6BC0),
                  badgeCount: _unreadChatsCount, // Unread chats badge
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  color: const Color(0xFFD4AF37),
                ),
              ],
            ),
          ),
        ),
      ),
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
          horizontal: isSelected ? 16 : 12,
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
