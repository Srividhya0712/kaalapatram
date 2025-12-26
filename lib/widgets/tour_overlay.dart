import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service to manage app tour/tutorial state
class TourService {
  static const String _keyTourCompleted = 'tour_completed';
  static const String _keyMyCalendarTourShown = 'my_calendar_tour_shown';
  static const String _keyConnectionsTourShown = 'connections_tour_shown';
  static const String _keyProfileTourShown = 'profile_tour_shown';

  static Future<bool> isTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTourCompleted) ?? false;
  }

  static Future<void> completeTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTourCompleted, true);
  }

  static Future<bool> isScreenTourShown(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(screenKey) ?? false;
  }

  static Future<void> markScreenTourShown(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(screenKey, true);
  }

  static Future<void> resetAllTours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTourCompleted);
    await prefs.remove(_keyMyCalendarTourShown);
    await prefs.remove(_keyConnectionsTourShown);
    await prefs.remove(_keyProfileTourShown);
  }
}

/// A widget that displays tour tips as an overlay
class TourTooltip extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final bool isLast;
  final Alignment alignment;
  final Color color;

  const TourTooltip({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onNext,
    this.onSkip,
    this.isLast = false,
    this.alignment = Alignment.center,
    this.color = const Color(0xFFD4AF37),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onSkip != null) ...[
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip Tour',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isLast ? 'Got it!' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tour data model
class TourStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  TourStep({
    required this.title,
    required this.description,
    required this.icon,
    this.color = const Color(0xFFD4AF37),
  });
}

/// Pre-defined tour steps for each screen
class TourSteps {
  static final List<TourStep> myCalendarTour = [
    TourStep(
      title: '📅 My Calendar',
      description: 'This is YOUR personal calendar. Only YOU can see your events here. Tap any date to view or add an event.',
      icon: Icons.calendar_today,
    ),
    TourStep(
      title: '🔍 Search Users',
      description: 'Tap here to search for colleagues and send connection requests. Once connected, you can see their calendars!',
      icon: Icons.search,
    ),
    TourStep(
      title: '📍 Today Button',
      description: 'Lost in the calendar? Tap this to quickly jump back to today\'s date.',
      icon: Icons.today,
    ),
    TourStep(
      title: '➕ Add Event',
      description: 'Tap this button to add a new work event. Fill in details like date, employer, what to carry, and payment.',
      icon: Icons.add_circle,
    ),
    TourStep(
      title: '🟡 Event Markers',
      description: 'Gold dots on dates mean you have events scheduled. Tap the date to see details.',
      icon: Icons.circle,
    ),
  ];

  static final List<TourStep> connectionsTour = [
    TourStep(
      title: '👥 Network Calendar',
      description: 'See when your connections are busy! This shows events from people you\'re connected with.',
      icon: Icons.groups,
      color: const Color(0xFF26A69A),
    ),
    TourStep(
      title: '🔗 Connected Users',
      description: 'Events are grouped by user. You can see their work schedule but NOT their payment details - that\'s private!',
      icon: Icons.person,
      color: const Color(0xFF26A69A),
    ),
    TourStep(
      title: '📋 Event Details',
      description: 'Tap on any event to see details like employer name, what to carry, and contact info.',
      icon: Icons.info_outline,
      color: const Color(0xFF26A69A),
    ),
  ];

  static final List<TourStep> profileTour = [
    TourStep(
      title: '👤 Your Profile',
      description: 'View and manage your profile here. Add a photo, profession, and bio to help others know you.',
      icon: Icons.person,
    ),
    TourStep(
      title: '☰ Menu',
      description: 'Tap the menu icon to access settings, manage connections, edit profile, and more.',
      icon: Icons.menu,
    ),
    TourStep(
      title: '🤝 Manage Connections',
      description: 'See your connection requests (sent & received) and manage your network here.',
      icon: Icons.people,
    ),
    TourStep(
      title: '🚪 Logout',
      description: 'When you\'re done, you can safely logout from here.',
      icon: Icons.logout,
    ),
  ];
}

/// A full-screen tour overlay widget
class TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const TourOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay> {
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onSkip?.call();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.steps.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentStep ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentStep
                          ? step.color
                          : Colors.white.withAlpha(102),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            
            // Tooltip
            Expanded(
              child: Center(
                child: TourTooltip(
                  title: step.title,
                  description: step.description,
                  icon: step.icon,
                  color: step.color,
                  onNext: _nextStep,
                  onSkip: _skip,
                  isLast: _currentStep == widget.steps.length - 1,
                ),
              ),
            ),
            
            // Step counter
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Step ${_currentStep + 1} of ${widget.steps.length}',
                style: TextStyle(
                  color: Colors.white.withAlpha(179),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the tour overlay
void showTour(BuildContext context, List<TourStep> steps, VoidCallback onComplete) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => TourOverlay(
      steps: steps,
      onComplete: () {
        Navigator.of(context).pop();
        onComplete();
      },
      onSkip: () {
        Navigator.of(context).pop();
        onComplete();
      },
    ),
  );
}
