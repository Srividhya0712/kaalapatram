import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/presence_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final String currentUserId;
  final String currentUserName;

  const ChatScreen({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final PresenceService _presenceService = PresenceService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  List<ChatMessage> _pendingMessages = []; // Optimistic messages not yet confirmed
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  StreamSubscription<bool>? _onlineSubscription;
  StreamSubscription<bool>? _typingSubscription;
  bool _isSending = false;
  bool _isOtherUserOnline = false;
  bool _isOtherUserTyping = false;
  String _otherUserLastSeen = '';

  static const Color goldColor = Color(0xFFD4AF37);
  static const Color tealColor = Color(0xFF26A69A);
  // WhatsApp-style dark theme colors
  static const Color whatsappDarkBg = Color(0xFF1F2C34);
  static const Color whatsappInputBg = Color(0xFF2A3942);
  static const Color whatsappGreen = Color(0xFF00A884);

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markAsRead();
    _setupPresence();
    _setupTypingListener();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _onlineSubscription?.cancel();
    _typingSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _presenceService.stopTyping();
    super.dispose();
  }

  void _setupPresence() {
    final otherUserId = widget.chatRoom.getOtherUserId(widget.currentUserId);
    
    // Listen to other user's online status
    _onlineSubscription = _presenceService.isUserOnline(otherUserId).listen((isOnline) {
      if (mounted) {
        setState(() => _isOtherUserOnline = isOnline);
      }
    });
    
    // Listen to other user's typing status
    _typingSubscription = _presenceService.isUserTyping(otherUserId, widget.chatRoom.id).listen((isTyping) {
      if (mounted) {
        setState(() => _isOtherUserTyping = isTyping);
      }
    });
    
    // Get last seen
    _presenceService.getLastSeen(otherUserId).listen((lastSeen) {
      if (mounted && lastSeen != null) {
        setState(() => _otherUserLastSeen = _formatLastSeen(lastSeen));
      }
    });
  }

  void _setupTypingListener() {
    // Listen to text changes to trigger typing indicator and update send/mic button
    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty) {
        _presenceService.startTyping(widget.chatRoom.id);
      }
      // Trigger rebuild to switch between mic and send icon
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(lastSeen);
  }

  void _loadMessages() {
    _messagesSubscription = _chatService
        .getMessages(widget.chatRoom.id)
        .listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
          // Remove pending messages that are now confirmed (appear in the stream)
          _pendingMessages.removeWhere((pending) {
            return messages.any((m) => 
              m.message == pending.message && 
              m.senderId == pending.senderId &&
              m.timestamp.difference(pending.timestamp).inSeconds.abs() < 10
            );
          });
        });
        _scrollToBottom();
      }
    });
  }

  void _markAsRead() {
    _chatService.markMessagesAsRead(widget.chatRoom.id, widget.currentUserId);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Get all messages including pending optimistic ones
  List<ChatMessage> get _allMessages {
    final all = [..._messages, ..._pendingMessages];
    all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return all;
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();
    
    // Create optimistic message (shows instantly with "sending" status)
    final optimisticMessage = ChatMessage(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      chatRoomId: widget.chatRoom.id,
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      message: messageText,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    // Add to pending messages immediately (WhatsApp-style instant display)
    setState(() {
      _pendingMessages.add(optimisticMessage);
    });
    _scrollToBottom();

    try {
      final receiverId = widget.chatRoom.getOtherUserId(widget.currentUserId);
      
      await _chatService.sendMessage(
        chatRoomId: widget.chatRoom.id,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        message: messageText,
        receiverId: receiverId,
      );
      
      // Message sent successfully - it will appear in stream and remove from pending
    } catch (e) {
      // Mark as failed
      setState(() {
        final index = _pendingMessages.indexWhere((m) => m.id == optimisticMessage.id);
        if (index != -1) {
          _pendingMessages[index] = optimisticMessage.copyWith(status: MessageStatus.failed);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUserName = widget.chatRoom.getOtherUserName(widget.currentUserId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: goldColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(51),
              ),
              child: Center(
                child: Text(
                  otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  _buildStatusText(),
                ],
              ),
            ),
            // Online indicator dot
            if (_isOtherUserOnline)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _allMessages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _allMessages.length,
                    itemBuilder: (context, index) {
                      final message = _allMessages[index];
                      final isMe = message.senderId == widget.currentUserId;
                      final showDate = index == 0 ||
                          !_isSameDay(_allMessages[index - 1].timestamp, message.timestamp);
                      
                      return Column(
                        children: [
                          if (showDate) _buildDateDivider(message.timestamp),
                          _buildMessageBubble(message, isMe),
                        ],
                      );
                    },
                  ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: goldColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: goldColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline, size: 48, color: goldColor.withAlpha(128)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start a conversation!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to get started',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    if (_isOtherUserTyping) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypingIndicator(),
          const SizedBox(width: 4),
          const Text(
            'typing...',
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.normal,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else if (_isOtherUserOnline) {
      return const Text(
        'Online',
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.normal,
          color: Colors.greenAccent,
        ),
      );
    } else if (_otherUserLastSeen.isNotEmpty) {
      return Text(
        'Last seen $_otherUserLastSeen',
        style: const TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.normal,
          color: Colors.white70,
        ),
      );
    } else {
      return const Text(
        'Offline',
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.normal,
          color: Colors.white70,
        ),
      );
    }
  }

  Widget _buildTypingIndicator() {
    return SizedBox(
      width: 30,
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 200)),
            builder: (context, value, child) {
              return Container(
                width: 6,
                height: 6 + (value * 3),
                decoration: BoxDecoration(
                  color: Colors.white70.withOpacity(0.5 + (value * 0.5)),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          );
        }),
      ),
    );
  }


  Widget _buildDateDivider(DateTime date) {
    String dateText;
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      dateText = 'Today';
    } else if (diff.inDays == 1) {
      dateText = 'Yesterday';
    } else if (diff.inDays < 7) {
      dateText = DateFormat('EEEE').format(date);
    } else {
      dateText = DateFormat('MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe 
              ? (message.status == MessageStatus.failed ? Colors.red.shade300 : goldColor)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // WhatsApp-style message status icons
  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white70,
          ),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 14, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: Colors.white);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
