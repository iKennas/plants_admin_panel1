/// Individual cell data model for spreadsheet cells
/// Handles text and numeric values with type detection
class CellData {
  final String value;
  final bool isNumeric;

  const CellData({
    required this.value,
    this.isNumeric = false,
  });

  /// Create CellData from Map (Firebase/JSON)
  factory CellData.fromMap(Map<String, dynamic> map) {
    return CellData(
      value: map['value']?.toString() ?? '',
      isNumeric: map['isNumeric'] ?? false,
    );
  }

  /// Convert CellData to Map for Firebase/JSON
  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'isNumeric': isNumeric,
    };
  }

  /// Create a copy with optional changes
  CellData copyWith({
    String? value,
    bool? isNumeric,
  }) {
    return CellData(
      value: value ?? this.value,
      isNumeric: isNumeric ?? this.isNumeric,
    );
  }

  /// Create CellData with automatic type detection
  factory CellData.fromValue(String value) {
    final trimmedValue = value.trim();
    final isNum = _isNumericString(trimmedValue);

    return CellData(
      value: trimmedValue,
      isNumeric: isNum,
    );
  }

  /// Create an empty cell
  factory CellData.empty() {
    return const CellData(value: '');
  }

  /// Helper method to detect if a string is numeric
  static bool _isNumericString(String value) {
    if (value.isEmpty) return false;

    // Try to parse as double (handles both int and decimal)
    final parsedValue = double.tryParse(value);
    return parsedValue != null;
  }

  /// Get the numeric value if this cell is numeric
  double? get numericValue {
    if (!isNumeric) return null;
    return double.tryParse(value);
  }

  /// Get the integer value if this cell is numeric and whole number
  int? get intValue {
    final numVal = numericValue;
    if (numVal == null) return null;

    // Check if it's a whole number
    if (numVal == numVal.roundToDouble()) {
      return numVal.round();
    }
    return null;
  }

  /// Check if the cell is empty
  bool get isEmpty => value.trim().isEmpty;

  /// Check if the cell has content
  bool get isNotEmpty => !isEmpty;

  /// Get display value (formatted for UI)
  String get displayValue {
    if (isEmpty) return '';

    // For numeric values, you might want special formatting
    if (isNumeric) {
      final numVal = numericValue;
      if (numVal != null) {
        // Remove unnecessary decimal places for whole numbers
        if (numVal == numVal.roundToDouble()) {
          return numVal.round().toString();
        }
        // Limit decimal places for display
        return numVal.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      }
    }

    return value;
  }

  /// Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CellData &&
        other.value == value &&
        other.isNumeric == isNumeric;
  }

  /// Hash code
  @override
  int get hashCode => Object.hash(value, isNumeric);

  /// String representation for debugging
  @override
  String toString() {
    return 'CellData(value: "$value", isNumeric: $isNumeric)';
  }

  /// Validate cell data
  bool isValid() {
    // Add any validation rules here
    // For now, all non-null strings are valid
    return true;
  }

  /// Compare cells for sorting (numeric-aware)
  int compareTo(CellData other) {
    // If both are numeric, compare numerically
    if (isNumeric && other.isNumeric) {
      final thisNum = numericValue ?? 0;
      final otherNum = other.numericValue ?? 0;
      return thisNum.compareTo(otherNum);
    }

    // If both are text or mixed types, compare as strings
    return value.toLowerCase().compareTo(other.value.toLowerCase());
  }
}