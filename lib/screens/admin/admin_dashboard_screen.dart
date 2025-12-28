import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../providers/admin_auth_provider.dart';
import 'admin_task_form.dart';
import 'admin_login_screen.dart';

/// Admin dashboard for managing ALL events (admin + user created)
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<Event>>? _eventsSubscription;

  // Theme colors - burgundy background with gold accents
  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);
  static const Color cardBg = Color(0xFF3D1A1A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
    
    // Guard: redirect to login if not authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isLoggedIn = ref.read(isAdminLoggedInProvider);
      if (!isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _eventsSubscription?.cancel();
    _eventsSubscription = _eventService.getAllEventsForAdmin().listen(
      (events) {
        if (mounted) {
          debugPrint('📋 Loaded ${events.length} events from Firestore');
          setState(() {
            _allEvents = events;
            _applyFilter();
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('❌ Error loading events: $error');
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load events: $error';
            _isLoading = false;
          });
        }
      },
    );
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredEvents = _allEvents;
    } else {
      final query = _searchQuery.toLowerCase().replaceAll('@', '');
      _filteredEvents = _allEvents.where((e) {
        return e.createdBy.toLowerCase().contains(query) ||
               (e.performerHead ?? '').toLowerCase().contains(query) ||
               e.assignedBy.toLowerCase().contains(query) ||
               e.employerName.toLowerCase().contains(query);
      }).toList();
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilter();
    });
  }

  Future<void> _logout() async {
    await ref.read(adminAuthProvider.notifier).logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
    }
  }

  Future<void> _callClient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Build text field with proper visibility
  InputDecoration _buildInputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: gold.withAlpha(100)),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: gold) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: gold.withAlpha(80)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: gold.withAlpha(80)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gold, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(currentAdminProvider);
    
    return Scaffold(
      backgroundColor: burgundy,
      appBar: AppBar(
        backgroundColor: burgundy,
        foregroundColor: gold,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (admin != null)
              Text(
                '@${admin.username}',
                style: TextStyle(color: gold.withAlpha(180), fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search bar with visible text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  cursorColor: gold,
                  decoration: _buildInputDecoration(
                    hint: 'Search by @username, name...',
                    prefixIcon: Icons.search,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: gold),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _onSearch,
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: gold,
                indicatorWeight: 3,
                labelColor: gold,
                unselectedLabelColor: gold.withAlpha(100),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Upcoming (${EventService.filterUpcoming(_filteredEvents).length})'),
                  Tab(text: 'Completed (${EventService.filterCompleted(_filteredEvents).length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: gold.withAlpha(150)),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadEvents,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: burgundy,
                        ),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventList(EventService.filterUpcoming(_filteredEvents)),
                    _buildEventList(EventService.filterCompleted(_filteredEvents)),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: gold,
        foregroundColor: burgundy,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
        onPressed: () => _showTaskForm(null),
      ),
    );
  }

  Widget _buildEventList(List<Event> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: gold.withAlpha(80)),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(color: gold.withAlpha(150), fontSize: 16),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Try a different search term',
                  style: TextStyle(color: gold.withAlpha(100), fontSize: 14),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) => _buildEventCard(events[index]),
    );
  }

  Widget _buildEventCard(Event event) {
    final statusColor = _getStatusColor(event.status);
    final isAdminCreated = event.assignedByAdmin;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Admin/User badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAdminCreated ? Colors.purple.withAlpha(50) : Colors.blue.withAlpha(50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isAdminCreated ? 'ADMIN' : 'USER',
                      style: TextStyle(
                        color: isAdminCreated ? Colors.purple.shade200 : Colors.blue.shade200,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.displayName,
                      style: const TextStyle(
                        color: gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      event.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Date and time row
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(event.date),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (event.time != null && event.time!.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      event.time!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ],
              ),
              
              // Tamil date
              if (event.tamilDate.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  event.tamilDate,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              
              // Location
              if (event.city != null && event.city!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      event.city!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              
              // Created by
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: gold),
                  const SizedBox(width: 4),
                  Text(
                    'Created by: @${event.createdBy}',
                    style: TextStyle(color: gold.withAlpha(180), fontSize: 12),
                  ),
                ],
              ),
              
              // Performer head if different
              if (event.performerHead != null && event.performerHead!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: gold),
                    const SizedBox(width: 4),
                    Text(
                      'Performer: ${event.performerHead}',
                      style: const TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              
              // Client contact (tappable)
              if (event.employerContact.isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _callClient(event.employerContact),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        event.employerContact,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Budget
              if (event.paymentAmount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.currency_rupee, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${event.currency}${event.paymentAmount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'denied':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  void _showTaskForm(Event? event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminTaskFormScreen(existingEvent: event),
      ),
    );
  }

  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: gold.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              event.displayName,
              style: const TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.calendar_today, DateFormat('EEEE, MMM dd, yyyy').format(event.date)),
            if (event.tamilDate.isNotEmpty) _buildDetailRow(Icons.calendar_month, event.tamilDate),
            if (event.time != null) _buildDetailRow(Icons.access_time, event.time!),
            if (event.city != null) _buildDetailRow(Icons.location_on, event.city!),
            _buildDetailRow(Icons.person_outline, 'Created by: @${event.createdBy}'),
            if (event.performerHead != null) _buildDetailRow(Icons.person, 'Performer: ${event.performerHead}'),
            if (event.employerContact.isNotEmpty) 
              GestureDetector(
                onTap: () => _callClient(event.employerContact),
                child: _buildDetailRow(Icons.phone, event.employerContact, color: Colors.green),
              ),
            if (event.paymentAmount > 0) _buildDetailRow(Icons.currency_rupee, '${event.currency}${event.paymentAmount.toStringAsFixed(0)}', color: Colors.amber),
            if (event.whatToCarry.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Notes:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(event.whatToCarry, style: const TextStyle(color: Colors.white70)),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.white70),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: color ?? Colors.white, fontSize: 15))),
        ],
      ),
    );
  }
}
