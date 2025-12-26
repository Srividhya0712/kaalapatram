import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/connection.dart';
import '../models/user_profile.dart';
import '../services/connection_service.dart';
import '../services/user_profile_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> 
    with SingleTickerProviderStateMixin {
  final ConnectionService _connectionService = ConnectionService();
  final UserProfileService _profileService = UserProfileService();
  
  late TabController _tabController;
  
  List<Connection> _pendingRequests = [];
  List<Connection> _sentRequests = [];
  Map<String, UserProfile> _userProfiles = {};
  String? _currentUserId;
  bool _isLoading = true;

  StreamSubscription<List<Connection>>? _pendingSubscription;
  StreamSubscription<List<Connection>>? _sentSubscription;

  static const Color goldColor = Color(0xFFD4AF37);
  static const Color tealColor = Color(0xFF26A69A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pendingSubscription?.cancel();
    _sentSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _profileService.getProfileLocally();
      if (profile == null) return;
      
      _currentUserId = profile.uid;

      // Subscribe to pending requests
      _pendingSubscription = _connectionService
          .getPendingRequests(_currentUserId!)
          .listen((requests) async {
        _pendingRequests = requests;
        await _loadUserProfiles(requests);
        if (mounted) setState(() {});
      });

      // Subscribe to sent requests
      _sentSubscription = _connectionService
          .getSentRequests(_currentUserId!)
          .listen((requests) async {
        _sentRequests = requests.where((r) => r.status == ConnectionStatus.pending).toList();
        await _loadUserProfiles(_sentRequests);
        if (mounted) setState(() {});
      });

    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserProfiles(List<Connection> connections) async {
    for (final connection in connections) {
      final otherUserId = connection.getOtherUserId(_currentUserId!);
      if (!_userProfiles.containsKey(otherUserId)) {
        final profile = await _connectionService.getUserProfile(otherUserId);
        if (profile != null) {
          _userProfiles[otherUserId] = profile;
        }
      }
    }
  }

  Future<void> _acceptRequest(Connection connection) async {
    try {
      await _connectionService.acceptConnectionRequest(connection.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection accepted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _declineRequest(Connection connection) async {
    try {
      await _connectionService.declineConnectionRequest(connection.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request declined')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelRequest(Connection connection) async {
    try {
      await _connectionService.removeConnection(connection.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: goldColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add, size: 18),
                  const SizedBox(width: 6),
                  Text('Requests${_pendingRequests.isNotEmpty ? ' (${_pendingRequests.length})' : ''}'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.send, size: 18),
                  const SizedBox(width: 6),
                  Text('Sent${_sentRequests.isNotEmpty ? ' (${_sentRequests.length})' : ''}'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: goldColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(),
                _buildSentList(),
              ],
            ),
    );
  }

  Widget _buildRequestsList() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_add_outlined,
        title: 'No Connection Requests',
        subtitle: 'When someone sends you a request, it will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        final otherUserId = request.requesterId;
        final profile = _userProfiles[otherUserId];
        
        return _buildRequestCard(
          profile: profile,
          username: request.requesterUsername,
          subtitle: 'wants to connect with you',
          actions: [
            OutlinedButton(
              onPressed: () => _declineRequest(request),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Decline'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _acceptRequest(request),
              style: ElevatedButton.styleFrom(
                backgroundColor: tealColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSentList() {
    if (_sentRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send_outlined,
        title: 'No Pending Requests',
        subtitle: 'Requests you send will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sentRequests.length,
      itemBuilder: (context, index) {
        final request = _sentRequests[index];
        final otherUserId = request.receiverId;
        final profile = _userProfiles[otherUserId];
        
        return _buildRequestCard(
          profile: profile,
          username: request.receiverUsername,
          subtitle: 'Request pending...',
          actions: [
            OutlinedButton(
              onPressed: () => _cancelRequest(request),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Cancel Request'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard({
    UserProfile? profile,
    required String username,
    required String subtitle,
    required List<Widget> actions,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [goldColor, tealColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: profile?.photoUrl.isNotEmpty == true
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profile!.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildInitialsAvatar(username),
                      errorWidget: (_, __, ___) => _buildInitialsAvatar(username),
                    ),
                  )
                : _buildInitialsAvatar(username),
          ),
          const SizedBox(width: 12),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (profile?.profession.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile!.profession,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: tealColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: actions,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String username) {
    return Center(
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: goldColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: goldColor.withAlpha(128)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
