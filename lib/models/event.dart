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
  });

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
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
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
    );
  }

  // Helper method to format date for Firestore (ISO string)
  static String _formatDateForFirestore(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  // Helper method to parse date from Firestore
  static DateTime _parseDateFromFirestore(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // Fallback to current date if parsing fails
      return DateTime.now();
    }
  }

  // Get formatted date string for display
  String get formattedDate => _formatDateForFirestore(date);

  // Check if this event is on the same date as another DateTime
  bool isSameDate(DateTime other) {
    return date.year == other.year &&
           date.month == other.month &&
           date.day == other.day;
  }

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
