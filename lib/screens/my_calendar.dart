import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../providers/providers.dart';
import '../widgets/event_detail_form.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/in_app_notification_service.dart';
import '../services/user_profile_service.dart';
import 'search_users_screen.dart';
import 'notification_center.dart';

class MyCalendar extends ConsumerStatefulWidget {
  const MyCalendar({super.key});

  @override
  ConsumerState<MyCalendar> createState() => _MyCalendarState();
}

class _MyCalendarState extends ConsumerState<MyCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Notification count
  final InAppNotificationService _notificationService = InAppNotificationService();
  final UserProfileService _profileService = UserProfileService();
  int _unreadNotificationCount = 0;
  StreamSubscription<int>? _notificationSubscription;

  // Gold color theme
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color burgundy = Color(0xFF800020);

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadNotificationCount();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotificationCount() async {
    final profile = await _profileService.getProfileLocally();
    if (profile != null) {
      _notificationSubscription = _notificationService
          .getUnreadCount(profile.uid)
          .listen((count) {
        if (mounted) {
          setState(() => _unreadNotificationCount = count);
        }
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day, List<Event> allEvents) {
    return allEvents.where((event) => event.isSameDate(day)).toList();
  }

  void _showEventDetailForm(DateTime selectedDate, {Event? existingEvent}) {
    // Check if trying to add new event on past date
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final isPastDate = selectedDateOnly.isBefore(todayDate);
    
    if (existingEvent == null && isPastDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add events to past dates'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventDetailForm(
        selectedDate: selectedDate,
        existingEvent: existingEvent,
        onEventSaved: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsForMonthProvider(_focusedDay));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: goldColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Hamburger menu button
                  IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                    tooltip: 'Menu',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.myCalendar ?? 'My Calendar',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Your personal work events',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withAlpha(204),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification bell with badge
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const NotificationCenterScreen()),
                          );
                        },
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        tooltip: 'Notifications',
                      ),
                      if (_unreadNotificationCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: burgundy,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              _unreadNotificationCount > 9 ? '9+' : '$_unreadNotificationCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SearchUsersScreen()),
                      );
                    },
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    tooltip: 'Find Connections',
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime.now();
                        _selectedDay = DateTime.now();
                      });
                    },
                    icon: const Icon(Icons.today, color: Colors.white),
                    tooltip: 'Go to Today',
                  ),
                ],
              ),
            ),
            
            // Calendar
            Expanded(
              child: eventsAsync.when(
                data: (events) {
                  return Column(
                    children: [
                      // Events count banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        color: goldColor.withAlpha(26),
                        child: Row(
                          children: [
                            const Icon(Icons.event_available, size: 18, color: goldColor),
                            const SizedBox(width: 8),
                            Text(
                              '${events.length} event${events.length != 1 ? 's' : ''} this month',
                              style: const TextStyle(
                                color: goldColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('MMMM yyyy').format(_focusedDay),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Calendar widget
                      Expanded(
                        child: TableCalendar<Event>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          
                          eventLoader: (day) => _getEventsForDay(day, events),
                          
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            weekendTextStyle: const TextStyle(color: Colors.red),
                            todayDecoration: BoxDecoration(
                              color: goldColor.withAlpha(77),
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: const TextStyle(
                              color: goldColor,
                              fontWeight: FontWeight.bold,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: goldColor,
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: goldColor,
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 1,
                            markerSize: 6,
                            markerMargin: const EdgeInsets.only(top: 1),
                          ),
                          
                          // Fix: Simplified to Month and Week only (removed confusing 2-weeks)
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                            CalendarFormat.week: 'Week',
                          },
                          
                          headerStyle: HeaderStyle(
                            formatButtonVisible: true,
                            titleCentered: true,
                            formatButtonDecoration: BoxDecoration(
                              border: Border.all(color: goldColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            formatButtonTextStyle: const TextStyle(color: goldColor),
                            titleTextStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            leftChevronIcon: const Icon(Icons.chevron_left, color: goldColor),
                            rightChevronIcon: const Icon(Icons.chevron_right, color: goldColor),
                          ),
                          
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            
                            final dayEvents = _getEventsForDay(selectedDay, events);
                            final existingEvent = dayEvents.isNotEmpty ? dayEvents.first : null;
                            
                            _showEventDetailForm(selectedDay, existingEvent: existingEvent);
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
                        ),
                      ),
                      
                      // Quick add hint
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey.shade100,
                        child: Row(
                          children: [
                            Icon(Icons.touch_app, color: Colors.grey.shade500, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap any date to view or add an event',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: goldColor),
                      SizedBox(height: 16),
                      Text('Loading events...'),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading events: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.refresh(eventsForMonthProvider(_focusedDay)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Floating action button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventDetailForm(_selectedDay),
        backgroundColor: goldColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
    );
  }
}
