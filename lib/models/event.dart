import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String? id;
  final DateTime date;
  final String tamilDate;
  final String assignedBy;
  final String whatToCarry;
  final String employerName;
  final String employerContact;
  final double paymentAmount;
  final String currency;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // New fields for unified admin/user events
  final bool assignedByAdmin;
  final String? performerHead;      // @username of performer
  final String? performerHeadId;
  final String? performerAssistant;
  final String? performerAssistantId;
  final String? city;
  final String? time;
  final String? transport;
  final String status;              // pending, confirmed, denied

  Event({
    this.id,
    required this.date,
    required this.tamilDate,
    required this.assignedBy,
    required this.whatToCarry,
    required this.employerName,
    required this.employerContact,
    required this.paymentAmount,
    required this.currency,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.assignedByAdmin = false,
    this.performerHead,
    this.performerHeadId,
    this.performerAssistant,
    this.performerAssistantId,
    this.city,
    this.time,
    this.transport,
    this.status = 'pending',
  });

  /// Check if event is upcoming (date >= today)
  bool get isUpcoming {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    return eventDate.isAfter(todayStart) || eventDate.isAtSameMomentAs(todayStart);
  }

  /// Check if event is completed (date < today)
  bool get isCompleted => !isUpcoming;

  // Convert Event to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': _formatDateForFirestore(date),
      'tamilDate': tamilDate,
      'assignedBy': assignedBy,
      'whatToCarry': whatToCarry,
      'employerName': employerName,
      'employerContact': employerContact,
      'paymentAmount': paymentAmount,
      'currency': currency,
      'createdBy': createdBy,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'assignedByAdmin': assignedByAdmin,
      if (performerHead != null) 'performerHead': performerHead,
      if (performerHeadId != null) 'performerHeadId': performerHeadId,
      if (performerAssistant != null) 'performerAssistant': performerAssistant,
      if (performerAssistantId != null) 'performerAssistantId': performerAssistantId,
      if (city != null) 'city': city,
      if (time != null) 'time': time,
      if (transport != null) 'transport': transport,
      'status': status,
    };
  }

  // Create Event from Firestore DocumentSnapshot
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      date: _parseDateFromFirestore(data['date']),
      tamilDate: data['tamilDate'] ?? '',
      assignedBy: data['assignedBy'] ?? '',
      whatToCarry: data['whatToCarry'] ?? '',
      employerName: data['employerName'] ?? '',
      employerContact: data['employerContact'] ?? '',
      paymentAmount: (data['paymentAmount'] ?? 0).toDouble(),
      currency: data['currency'] ?? '₹',
      createdBy: data['createdBy'] ?? '',
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      assignedByAdmin: data['assignedByAdmin'] ?? false,
      performerHead: data['performerHead'],
      performerHeadId: data['performerHeadId'],
      performerAssistant: data['performerAssistant'],
      performerAssistantId: data['performerAssistantId'],
      city: data['city'],
      time: data['time'],
      transport: data['transport'],
      status: data['status'] ?? 'pending',
    );
  }

  // Helper to parse DateTime from various formats (Timestamp, int, null)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }


  // Create Event from Map (for local operations)
  factory Event.fromMap(Map<String, dynamic> map, {String? id}) {
    return Event(
      id: id,
      date: map['date'] is DateTime 
          ? map['date'] 
          : _parseDateFromFirestore(map['date']),
      tamilDate: map['tamilDate'] ?? '',
      assignedBy: map['assignedBy'] ?? '',
      whatToCarry: map['whatToCarry'] ?? '',
      employerName: map['employerName'] ?? '',
      employerContact: map['employerContact'] ?? '',
      paymentAmount: (map['paymentAmount'] ?? 0).toDouble(),
      currency: map['currency'] ?? '₹',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
      assignedByAdmin: map['assignedByAdmin'] ?? false,
      performerHead: map['performerHead'],
      performerHeadId: map['performerHeadId'],
      city: map['city'],
      time: map['time'],
      status: map['status'] ?? 'pending',
    );
  }

  // Create a copy of Event with updated fields
  Event copyWith({
    String? id,
    DateTime? date,
    String? tamilDate,
    String? assignedBy,
    String? whatToCarry,
    String? employerName,
    String? employerContact,
    double? paymentAmount,
    String? currency,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return Event(
      id: id ?? this.id,
      date: date ?? this.date,
      tamilDate: tamilDate ?? this.tamilDate,
      assignedBy: assignedBy ?? this.assignedBy,
      whatToCarry: whatToCarry ?? this.whatToCarry,
      employerName: employerName ?? this.employerName,
      employerContact: employerContact ?? this.employerContact,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      currency: currency ?? this.currency,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedByAdmin: assignedByAdmin,
      performerHead: performerHead,
      performerHeadId: performerHeadId,
      performerAssistant: performerAssistant,
      performerAssistantId: performerAssistantId,
      city: city,
      time: time,
      transport: transport,
      status: status ?? this.status,
    );
  }

  // Helper method to format date for Firestore (ISO string)
  static String _formatDateForFirestore(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  // Helper method to parse date from Firestore
  static DateTime _parseDateFromFirestore(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is Timestamp) return dateValue.toDate();
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Get formatted date string for display
  String get formattedDate => _formatDateForFirestore(date);

  // Check if this event is on the same date as another DateTime
  bool isSameDate(DateTime other) {
    return date.year == other.year &&
           date.month == other.month &&
           date.day == other.day;
  }

  /// Get display name (employer or function name)
  String get displayName => employerName.isNotEmpty ? employerName : 'Event';

  @override
  String toString() {
    return 'Event(id: $id, date: $formattedDate, assignedBy: $assignedBy, '
           'employerName: $employerName, paymentAmount: $paymentAmount $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event &&
           other.id == id &&
           other.date == date &&
           other.assignedBy == assignedBy &&
           other.employerName == employerName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           date.hashCode ^
           assignedBy.hashCode ^
           employerName.hashCode;
  }
}
