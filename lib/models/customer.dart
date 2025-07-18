/// Customer data model for the plants and seeds admin panel
/// Handles customer information including name, phone, notes, and timestamps
class Customer {
  final String id;
  final String name;
  final String phoneNumber;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Customer from Firebase document
  factory Customer.fromMap(Map<String, dynamic> map, String documentId) {
    return Customer(
      id: documentId,
      name: map['name']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  /// Convert Customer to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create a copy with optional changes
  Customer copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a new customer (for adding to database)
  factory Customer.create({
    required String name,
    required String phoneNumber,
    String notes = '',
  }) {
    final now = DateTime.now();
    return Customer(
      id: '', // Will be set by Firebase
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      notes: notes.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update customer with new timestamp
  Customer update({
    String? name,
    String? phoneNumber,
    String? notes,
  }) {
    return copyWith(
      name: name?.trim(),
      phoneNumber: phoneNumber?.trim(),
      notes: notes?.trim(),
      updatedAt: DateTime.now(),
    );
  }

  /// Helper method to parse timestamp from various formats
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    if (timestamp is DateTime) {
      return timestamp;
    }

    // Handle Firestore Timestamp if needed
    if (timestamp.runtimeType.toString() == 'Timestamp') {
      return (timestamp as dynamic).toDate();
    }

    return DateTime.now();
  }

  /// Validate customer data
  bool isValid() {
    return name.trim().isNotEmpty &&
        phoneNumber.trim().isNotEmpty &&
        _isValidPhoneNumber(phoneNumber);
  }

  /// Basic phone number validation
  static bool _isValidPhoneNumber(String phone) {
    if (phone.trim().isEmpty) return false;

    // Remove common phone number characters
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Check if it contains only digits and is reasonable length
    return RegExp(r'^\d{8,15}$').hasMatch(cleanPhone);
  }

  /// Get formatted phone number for display (just return as entered)
  String get formattedPhoneNumber {
    return phoneNumber.trim();
  }

  /// Get customer initials for avatar
  String get initials {
    if (name.trim().isEmpty) return '?';

    final nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    } else {
      return '${nameParts[0].substring(0, 1)}${nameParts[1].substring(0, 1)}'.toUpperCase();
    }
  }

  /// Check if customer has notes
  bool get hasNotes => notes.trim().isNotEmpty;

  /// Get time since creation
  String get timeSinceCreated {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Get formatted creation date
  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get formatted last update date
  String get formattedUpdatedDate {
    return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
  }

  /// Check if customer was recently updated
  bool get wasRecentlyUpdated {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    return difference.inHours < 24;
  }

  /// Search helper - check if customer matches search query
  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;

    final lowerQuery = query.toLowerCase().trim();
    return name.toLowerCase().contains(lowerQuery) ||
        phoneNumber.contains(lowerQuery) ||
        notes.toLowerCase().contains(lowerQuery);
  }

  /// Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer &&
        other.id == id &&
        other.name == name &&
        other.phoneNumber == phoneNumber &&
        other.notes == notes;
  }

  /// Hash code
  @override
  int get hashCode => Object.hash(id, name, phoneNumber, notes);

  /// String representation for debugging
  @override
  String toString() {
    return 'Customer(id: $id, name: "$name", phone: "$phoneNumber", notes: "${notes.length > 20 ? notes.substring(0, 20) + '...' : notes}")';
  }

  /// Compare customers for sorting (by name)
  int compareTo(Customer other) {
    return name.toLowerCase().compareTo(other.name.toLowerCase());
  }
}