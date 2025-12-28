import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/user_profile.dart';
import '../../models/in_app_notification.dart';
import '../../services/event_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/in_app_notification_service.dart';

/// Form for creating/editing admin tasks with @mention support
class AdminTaskFormScreen extends StatefulWidget {
  final Event? existingEvent;

  const AdminTaskFormScreen({super.key, this.existingEvent});

  @override
  State<AdminTaskFormScreen> createState() => _AdminTaskFormScreenState();
}

class _AdminTaskFormScreenState extends State<AdminTaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService();
  final _userProfileService = UserProfileService();

  // Controllers
  final _timeController = TextEditingController();
  final _tamilDateController = TextEditingController();
  final _functionNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _clientContactController = TextEditingController();
  final _budgetController = TextEditingController();
  final _performHeadController = TextEditingController();
  final _headContactController = TextEditingController();
  final _assistantController = TextEditingController();
  final _assistantContactController = TextEditingController();
  final _detailsController = TextEditingController();
  final _transportController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;

  // @mention suggestions
  List<UserProfile> _headSuggestions = [];
  List<UserProfile> _assistantSuggestions = [];
  String? _selectedHeadId;
  String? _selectedAssistantId;
  bool _showHeadSuggestions = false;
  bool _showAssistantSuggestions = false;

  // Theme colors
  static const Color burgundy = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      _initializeWithEvent(widget.existingEvent!);
    }
  }

  void _initializeWithEvent(Event event) {
    _selectedDate = event.date;
    _timeController.text = event.time ?? '';
    _tamilDateController.text = event.tamilDate;
    _functionNameController.text = event.employerName; // Using employerName as function name
    _cityController.text = event.city ?? '';
    _clientContactController.text = event.employerContact;
    _budgetController.text = event.paymentAmount.toString();
    if (event.performerHead != null) {
      _performHeadController.text = '@${event.performerHead}';
      _selectedHeadId = event.performerHeadId;
    }
    _headContactController.text = ''; // Not stored separately
    if (event.performerAssistant != null) {
      _assistantController.text = '@${event.performerAssistant}';
      _selectedAssistantId = event.performerAssistantId;
    }
    _detailsController.text = event.whatToCarry;
    _transportController.text = event.transport ?? '';
  }


  @override
  void dispose() {
    _timeController.dispose();
    _tamilDateController.dispose();
    _functionNameController.dispose();
    _cityController.dispose();
    _clientContactController.dispose();
    _budgetController.dispose();
    _performHeadController.dispose();
    _headContactController.dispose();
    _assistantController.dispose();
    _assistantContactController.dispose();
    _detailsController.dispose();
    _transportController.dispose();
    super.dispose();
  }

  Future<void> _searchHeadUsers(String query) async {
    if (!query.startsWith('@') || query.length < 2) {
      setState(() {
        _headSuggestions = [];
        _showHeadSuggestions = false;
      });
      return;
    }

    final searchQuery = query.substring(1);
    final results = await _userProfileService.searchUsers(
      query: searchQuery,
      currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
    );

    setState(() {
      _headSuggestions = results;
      _showHeadSuggestions = results.isNotEmpty;
    });
  }

  Future<void> _searchAssistantUsers(String query) async {
    if (!query.startsWith('@') || query.length < 2) {
      setState(() {
        _assistantSuggestions = [];
        _showAssistantSuggestions = false;
      });
      return;
    }

    final searchQuery = query.substring(1);
    final results = await _userProfileService.searchUsers(
      query: searchQuery,
      currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
    );

    setState(() {
      _assistantSuggestions = results;
      _showAssistantSuggestions = results.isNotEmpty;
    });
  }

  void _selectHead(UserProfile user) {
    setState(() {
      _performHeadController.text = '@${user.username}';
      _selectedHeadId = user.uid;
      _headSuggestions = [];
      _showHeadSuggestions = false;
    });
  }

  void _selectAssistant(UserProfile user) {
    setState(() {
      _assistantController.text = '@${user.username}';
      _selectedAssistantId = user.uid;
      _assistantSuggestions = [];
      _showAssistantSuggestions = false;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: gold,
              surface: burgundy,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: gold,
              surface: burgundy,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _timeController.text = picked.format(context);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHeadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Perform Head using @mention')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final headUsername = _performHeadController.text.startsWith('@')
          ? _performHeadController.text.substring(1)
          : _performHeadController.text;

      final assistantUsername = _assistantController.text.isNotEmpty &&
              _assistantController.text.startsWith('@')
          ? _assistantController.text.substring(1)
          : null;

      final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Create Event instead of AdminTask - saves to unified events collection
      final event = Event(
        id: widget.existingEvent?.id,
        date: _selectedDate,
        tamilDate: _tamilDateController.text.trim(),
        assignedBy: headUsername,  // Assigned to this performer
        whatToCarry: _detailsController.text.trim(),
        employerName: _functionNameController.text.trim(), // Function name
        employerContact: _clientContactController.text.trim(),
        paymentAmount: double.tryParse(_budgetController.text) ?? 0,
        currency: '₹',
        createdBy: adminId,
        assignedByAdmin: true,  // Mark as admin-created
        performerHead: headUsername,
        performerHeadId: _selectedHeadId,
        performerAssistant: assistantUsername,
        performerAssistantId: _selectedAssistantId,
        city: _cityController.text.trim(),
        time: _timeController.text.trim(),
        transport: _transportController.text.trim(),
        status: 'pending',  // User needs to confirm
      );

      // Save to events collection
      await _eventService.createEventAsAdmin(event, headUsername);

      // Send notification to the assigned performer
      final notificationService = InAppNotificationService();
      await notificationService.sendNotification(
        userId: _selectedHeadId!,
        title: 'New Task Assigned',
        body: '${event.employerName} on ${DateFormat('MMM dd, yyyy').format(event.date)} in ${event.city ?? 'TBD'}',
        type: NotificationType.taskAssigned,
      );

      // Also notify assistant if assigned
      if (_selectedAssistantId != null) {
        await notificationService.sendNotification(
          userId: _selectedAssistantId!,
          title: 'New Task Assigned (Assistant)',
          body: '${event.employerName} on ${DateFormat('MMM dd, yyyy').format(event.date)} in ${event.city ?? 'TBD'}',
          type: NotificationType.taskAssigned,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: burgundy,
      appBar: AppBar(
        backgroundColor: burgundy,
        foregroundColor: gold,
        elevation: 0,
        title: Text(
          widget.existingEvent != null ? 'Edit Task' : 'New Task',
          style: const TextStyle(color: gold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Time row
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimeField(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tamil Date
                    _buildTextField(
                      controller: _tamilDateController,
                      label: 'Tamil Date',
                      hint: 'e.g., மார்கழி 15',
                      icon: Icons.calendar_month,
                      required: true,
                    ),
                    const SizedBox(height: 16),

                    // Function Name
                    _buildTextField(
                      controller: _functionNameController,
                      label: 'Function Name',
                      hint: 'Event or function name',
                      icon: Icons.event,
                      required: true,
                    ),
                    const SizedBox(height: 16),

                    // City
                    _buildTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'Location city',
                      icon: Icons.location_city,
                      required: true,
                    ),
                    const SizedBox(height: 16),

                    // Client Contact
                    _buildTextField(
                      controller: _clientContactController,
                      label: 'Client Contact',
                      hint: 'Phone number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      required: true,
                    ),
                    const SizedBox(height: 16),

                    // Budget
                    _buildTextField(
                      controller: _budgetController,
                      label: 'Budget (₹)',
                      hint: 'Amount',
                      icon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      required: true,
                    ),
                    const SizedBox(height: 24),

                    // Section: Perform Head
                    _buildSectionHeader('Perform Head'),
                    const SizedBox(height: 8),
                    _buildMentionField(
                      controller: _performHeadController,
                      label: 'Perform Head (@username)',
                      hint: 'Type @ to search...',
                      suggestions: _headSuggestions,
                      showSuggestions: _showHeadSuggestions,
                      onChanged: _searchHeadUsers,
                      onSelect: _selectHead,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _headContactController,
                      label: 'Head Contact',
                      hint: 'Phone number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      required: true,
                    ),
                    const SizedBox(height: 24),

                    // Section: Assistant (Optional)
                    _buildSectionHeader('Perform Assistant (Optional)'),
                    const SizedBox(height: 8),
                    _buildMentionField(
                      controller: _assistantController,
                      label: 'Assistant (@username)',
                      hint: 'Type @ to search...',
                      suggestions: _assistantSuggestions,
                      showSuggestions: _showAssistantSuggestions,
                      onChanged: _searchAssistantUsers,
                      onSelect: _selectAssistant,
                      required: false,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _assistantContactController,
                      label: 'Assistant Contact',
                      hint: 'Phone number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Details
                    _buildTextField(
                      controller: _detailsController,
                      label: 'Details',
                      hint: 'Additional task details...',
                      icon: Icons.description,
                      maxLines: 4,
                      required: true,
                    ),
                    const SizedBox(height: 16),

                    // Transport
                    _buildTextField(
                      controller: _transportController,
                      label: 'Transport',
                      hint: 'Transport arrangements...',
                      icon: Icons.directions_car,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: burgundy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: burgundy)
                            : Text(
                                widget.existingEvent != null
                                    ? 'Update Task'
                                    : 'Create Task',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: gold,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'English Date',
          labelStyle: TextStyle(color: gold.withAlpha(180)),
          prefixIcon: const Icon(Icons.calendar_today, color: gold),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: gold.withAlpha(128)),
          ),
        ),
        child: Text(
          DateFormat('MMM dd, yyyy').format(_selectedDate),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    return InkWell(
      onTap: _selectTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Time',
          labelStyle: TextStyle(color: gold.withAlpha(180)),
          prefixIcon: const Icon(Icons.access_time, color: gold),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: gold.withAlpha(128)),
          ),
        ),
        child: Text(
          _timeController.text.isEmpty ? 'Select time' : _timeController.text,
          style: TextStyle(
            color: _timeController.text.isEmpty ? Colors.white54 : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: gold,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF3D1A1A),
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: gold.withAlpha(180)),
        hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
        prefixIcon: Icon(icon, color: gold),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gold.withAlpha(128)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
      ),
      validator: required
          ? (value) => value?.isEmpty == true ? 'Required' : null
          : null,
    );
  }

  Widget _buildMentionField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required List<UserProfile> suggestions,
    required bool showSuggestions,
    required Function(String) onChanged,
    required Function(UserProfile) onSelect,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          style: const TextStyle(color: gold, fontSize: 16),
          cursorColor: gold,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF3D1A1A),
            labelText: label,
            hintText: hint,
            labelStyle: TextStyle(color: gold.withAlpha(180)),
            hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
            prefixIcon: const Icon(Icons.alternate_email, color: gold),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: gold.withAlpha(128)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: gold, width: 2),
            ),
          ),
          onChanged: onChanged,
          validator: required
              ? (value) => value?.isEmpty == true ? 'Required' : null
              : null,
        ),
        if (showSuggestions) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1015),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: gold.withAlpha(128)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final user = suggestions[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: gold,
                    radius: 16,
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: const TextStyle(color: burgundy, fontSize: 12),
                    ),
                  ),
                  title: Text(
                    '@${user.username}',
                    style: const TextStyle(color: gold, fontSize: 14),
                  ),
                  subtitle: Text(
                    user.email,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  onTap: () => onSelect(user),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
