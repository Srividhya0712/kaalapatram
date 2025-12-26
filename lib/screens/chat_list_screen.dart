import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../models/connection.dart';
import '../services/chat_service.dart';
import '../services/connection_service.dart';
import '../services/user_profile_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final ConnectionService _connectionService = ConnectionService();
  final UserProfileService _profileService = UserProfileService();
  
  String? _currentUserId;
  String? _currentUserName;
  List<Connection> _connections = [];
  bool _isLoading = true;

  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;
  List<ChatRoom> _chatRooms = [];

  static const Color goldColor = Color(0xFFD4AF37);
  static const Color tealColor = Color(0xFF26A69A);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _profileService.getProfileLocally();
      if (profile == null) return;
      
      _currentUserId = profile.uid;
      _currentUserName = profile.username;

      // Get connections
      final connections = await _connectionService
          .getAcceptedConnections(_currentUserId!)
          .first;
      _connections = connections;

      // Subscribe to chat rooms
      _chatRoomsSubscription = _chatService
          .getChatRooms(_currentUserId!)
          .listen((rooms) {
        if (mounted) {
          setState(() {
            _chatRooms = rooms;
          });
        }
      });

    } catch (e) {
      debugPrint('Error loading chats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChat(Connection connection) async {
    final otherUserId = connection.getOtherUserId(_currentUserId!);
    final otherUserName = connection.getOtherUserUsername(_currentUserId!);

    final chatRoom = await _chatService.getOrCreateChatRoom(
      user1Id: _currentUserId!,
      user1Name: _currentUserName!,
      user2Id: otherUserId,
      user2Name: otherUserName,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoom: chatRoom,
            currentUserId: _currentUserId!,
            currentUserName: _currentUserName!,
          ),
        ),
      );
    }
  }

  void _openExistingChat(ChatRoom chatRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoom: chatRoom,
          currentUserId: _currentUserId!,
          currentUserName: _currentUserName!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: goldColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: goldColor))
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: goldColor,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildContent() {
    if (_chatRooms.isEmpty && _connections.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Active connections (can start new chat)
        if (_connections.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            color: goldColor.withAlpha(26),
            child: Row(
              children: [
                const Icon(Icons.people, size: 18, color: goldColor),
                const SizedBox(width: 8),
                Text(
                  '${_connections.length} connection${_connections.length != 1 ? 's' : ''} available to chat',
                  style: const TextStyle(color: goldColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
        
        // Chat list
        Expanded(
          child: _chatRooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to start a new chat',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _chatRooms.length,
                  itemBuilder: (context, index) {
                    final room = _chatRooms[index];
                    return _buildChatRoomTile(room);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatRoomTile(ChatRoom room) {
    final otherUserName = room.getOtherUserName(_currentUserId!);
    final unreadCount = room.getUnreadCount(_currentUserId!);
    final isUnread = unreadCount > 0;
    final timeString = _formatTime(room.lastMessageTime);

    return ListTile(
      onTap: () => _openExistingChat(room),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [goldColor, tealColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
      title: Text(
        otherUserName,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        room.lastMessage.isEmpty ? 'No messages yet' : room.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isUnread ? Colors.black87 : Colors.grey,
          fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeString,
            style: TextStyle(
              color: isUnread ? tealColor : Colors.grey,
              fontSize: 12,
            ),
          ),
          if (isUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tealColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEE').format(time);
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  void _showNewChatDialog() {
    if (_connections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connect with people first to start chatting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Start New Chat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a connection to message',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _connections.length,
                itemBuilder: (context, index) {
                  final connection = _connections[index];
                  final otherUserName = connection.getOtherUserUsername(_currentUserId!);
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tealColor,
                      child: Text(
                        otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(otherUserName),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _openChat(connection);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              child: Icon(Icons.chat_bubble_outline, size: 64, color: goldColor.withAlpha(128)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Chats Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with colleagues to start messaging',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
