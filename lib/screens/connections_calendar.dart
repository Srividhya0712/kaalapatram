import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../models/connection.dart';
import '../services/event_service.dart';
import '../services/connection_service.dart';
import '../services/user_profile_service.dart';
import 'search_users_screen.dart';
import 'manage_connections_screen.dart';

class ConnectionsCalendar extends StatefulWidget {
  const ConnectionsCalendar({super.key});

  @override
  State<ConnectionsCalendar> createState() => _ConnectionsCalendarState();
}

class _ConnectionsCalendarState extends State<ConnectionsCalendar> {
  final EventService _eventService = EventService();
  final ConnectionService _connectionService = ConnectionService();
  final UserProfileService _profileService = UserProfileService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  List<Event> _connectionsEvents = [];
  List<Connection> _connections = [];
  Map<String, String> _userNames = {};
  String? _currentUserId;
  bool _isLoading = true;
  String? _errorMessage;
  
  StreamSubscription<List<Connection>>? _connectionsSubscription;

  // Teal color for Network Calendar
  static const Color connectionsTeal = Color(0xFF26A69A);

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _initializeData();
  }

  @override
  void dispose() {
    _connectionsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    debugPrint('🔄 ConnectionsCalendar: Initializing...');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user
      final profile = await _profileService.getProfileLocally();
      if (profile == null) {
        debugPrint('❌ ConnectionsCalendar: No local profile found');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login again';
        });
        return;
      }
      
      _currentUserId = profile.uid;
      debugPrint('✅ ConnectionsCalendar: User ID: $_currentUserId');

      // Cancel any existing subscription
      await _connectionsSubscription?.cancel();

      // Subscribe to connections stream
      _connectionsSubscription = _connectionService
          .getAcceptedConnections(_currentUserId!)
          .listen(
            _onConnectionsUpdated,
            onError: (error) {
              debugPrint('❌ ConnectionsCalendar: Stream error: $error');
              setState(() {
                _isLoading = false;
                _errorMessage = 'Failed to load connections';
              });
            },
          );
    } catch (e) {
      debugPrint('❌ ConnectionsCalendar: Error initializing: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading data: $e';
      });
    }
  }

  void _onConnectionsUpdated(List<Connection> connections) async {
    debugPrint('📥 ConnectionsCalendar: Received ${connections.length} connections');
    
    _connections = connections;
    
    // Build user names map
    _userNames.clear();
    for (final connection in connections) {
      final otherUserId = connection.getOtherUserId(_currentUserId!);
      final otherUserName = connection.getOtherUserUsername(_currentUserId!);
      _userNames[otherUserId] = otherUserName;
      debugPrint('   - Connection with: $otherUserName ($otherUserId)');
    }

    // Load events for all connected users
    await _loadAllConnectionsEvents();
  }

  Future<void> _loadAllConnectionsEvents() async {
    final allEvents = <Event>[];
    
    // First, load current user's own events
    if (_currentUserId != null) {
      try {
        debugPrint('🔍 Loading MY events...');
        final myEvents = await _eventService
            .getUserEvents(_currentUserId!)
            .first
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => <Event>[],
            );
        
        debugPrint('   ✅ Found ${myEvents.length} of my events');
        allEvents.addAll(myEvents);
        
        // Add current user to names map
        final profile = await _profileService.getProfileLocally();
        if (profile != null) {
          _userNames[_currentUserId!] = '${profile.username} (Me)';
        }
      } catch (e) {
        debugPrint('   ❌ Error loading my events: $e');
      }
    }
    
    // Then load connections' events (even if no connections, show user's events)
    if (_connections.isEmpty) {
      debugPrint('📭 ConnectionsCalendar: No connections, showing only my events');
      setState(() {
        _connectionsEvents = allEvents;
        _isLoading = false;
      });
      return;
    }
    
    for (final connection in _connections) {
      final otherUserId = connection.getOtherUserId(_currentUserId!);
      
      try {
        debugPrint('🔍 Loading events for: ${_userNames[otherUserId]} ($otherUserId)');
        
        // Get events for this connected user (with timeout)
        final userEvents = await _eventService
            .getUserEvents(otherUserId)
            .first
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('⏰ Timeout loading events for $otherUserId');
                return <Event>[];
              },
            );
        
        debugPrint('   ✅ Found ${userEvents.length} events');
        allEvents.addAll(userEvents);
      } catch (e) {
        debugPrint('   ❌ Error loading events for $otherUserId: $e');
      }
    }

    debugPrint('📊 ConnectionsCalendar: Total events loaded: ${allEvents.length}');
    
    if (mounted) {
      setState(() {
        _connectionsEvents = allEvents;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    debugPrint('🔄 ConnectionsCalendar: Refreshing...');
    await _initializeData();
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _connectionsEvents.where((event) => event.isSameDate(day)).toList();
  }

  Map<String, List<Event>> _getEventsByUser(DateTime day) {
    final dayEvents = _getEventsForDay(day);
    final eventsByUser = <String, List<Event>>{};
    
    for (final event in dayEvents) {
      if (!eventsByUser.containsKey(event.createdBy)) {
        eventsByUser[event.createdBy] = [];
      }
      eventsByUser[event.createdBy]!.add(event);
    }
    
    return eventsByUser;
  }

  void _showDayEventsBottomSheet(DateTime day) {
    final eventsByUser = _getEventsByUser(day);
    
    if (eventsByUser.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No connection events on ${DateFormat('MMM d').format(day)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: connectionsTeal.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: connectionsTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d').format(day),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${eventsByUser.length} connection(s) busy',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Events list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: eventsByUser.length,
                itemBuilder: (context, index) {
                  final userId = eventsByUser.keys.elementAt(index);
                  final userEvents = eventsByUser[userId]!;
                  final userName = _userNames[userId] ?? 'Unknown User';
                  
                  return _buildUserEventsSection(userName, userEvents);
                },
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserEventsSection(String userName, List<Event> events) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: connectionsTeal.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: connectionsTeal.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: connectionsTeal,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
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
                child: Text(
                  userName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: connectionsTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${events.length} event${events.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Events list
          ...events.map((event) => _buildConnectionEventCard(event)),
        ],
      ),
    );
  }

  Widget _buildConnectionEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: connectionsTeal.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.assignedBy.isNotEmpty) ...[
            _buildEventDetailRow(
              Icons.assignment_ind,
              'Assigned by: ${event.assignedBy}',
              isBold: true,
            ),
          ],
          
          if (event.whatToCarry.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildEventDetailRow(
              Icons.inventory_2,
              'Carry: ${event.whatToCarry}',
            ),
          ],
          
          if (event.employerName.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildEventDetailRow(
              Icons.business,
              'Employer: ${event.employerName}',
            ),
          ],
          
          if (event.employerContact.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildEventDetailRow(
              Icons.phone,
              'Contact: ${event.employerContact}',
            ),
          ],
          
          // Note: Payment amount is intentionally hidden for connections
        ],
      ),
    );
  }

  Widget _buildEventDetailRow(IconData icon, String text, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: connectionsTeal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventMarker(DateTime day, List<Event> events) {
    if (events.isEmpty) return const SizedBox.shrink();
    
    // Group events by user and show initials
    final eventsByUser = _getEventsByUser(day);
    final userInitials = eventsByUser.keys.map((userId) {
      final userName = _userNames[userId] ?? 'U';
      return userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    }).take(3).toList();
    
    return Positioned(
      bottom: 2,
      right: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: connectionsTeal,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          userInitials.join(''),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Network Calendar'),
            Text(
              'Your events & connections\' events',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white.withAlpha(204),
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
        backgroundColor: connectionsTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Manage Connections
          IconButton(
            icon: const Icon(Icons.people_alt),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManageConnectionsScreen(),
                ),
              );
            },
            tooltip: 'Manage Connections',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: connectionsTeal),
            SizedBox(height: 16),
            Text('Loading connections...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_connections.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCalendar();
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            connectionsTeal.withAlpha(26),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: connectionsTeal.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_outline,
                  size: 80,
                  color: connectionsTeal.withAlpha(128),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Connections Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Connect with colleagues to see their work schedules here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SearchUsersScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Find Connections'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: connectionsTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        // Connection count banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: connectionsTeal.withAlpha(26),
          child: Row(
            children: [
              const Icon(Icons.people, size: 18, color: connectionsTeal),
              const SizedBox(width: 8),
              Text(
                '${_connections.length} connection${_connections.length != 1 ? 's' : ''} • ${_connectionsEvents.length} total event${_connectionsEvents.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: connectionsTeal,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _refreshData,
                child: const Icon(Icons.refresh, size: 18, color: connectionsTeal),
              ),
            ],
          ),
        ),
        
        // Calendar
        Expanded(
          child: TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            
            eventLoader: _getEventsForDay,
            
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.red),
              todayDecoration: BoxDecoration(
                color: connectionsTeal.withAlpha(77),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: connectionsTeal,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: connectionsTeal,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
            ),
            
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: connectionsTeal),
                borderRadius: BorderRadius.circular(8),
              ),
              formatButtonTextStyle: const TextStyle(color: connectionsTeal),
            ),
            
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              
              // Show events for selected day
              _showDayEventsBottomSheet(selectedDay);
            },
            
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                return _buildEventMarker(day, events);
              },
            ),
          ),
        ),
      ],
    );
  }
}
