/// Sheet data model for spreadsheet functionality
/// Handles 2D grid of cells with rows and columns

/// Individual cell data model for spreadsheet cells
class CellData {
  final String value;
  final bool isNumeric;

  const CellData({
    required this.value,
    this.isNumeric = false,
  });

  factory CellData.fromMap(Map<String, dynamic> map) {
    return CellData(
      value: map['value']?.toString() ?? '',
      isNumeric: map['isNumeric'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'isNumeric': isNumeric,
    };
  }

  CellData copyWith({String? value, bool? isNumeric}) {
    return CellData(
      value: value ?? this.value,
      isNumeric: isNumeric ?? this.isNumeric,
    );
  }

  factory CellData.fromValue(String value) {
    final trimmedValue = value.trim();
    final isNum = double.tryParse(trimmedValue) != null;
    return CellData(value: trimmedValue, isNumeric: isNum);
  }

  factory CellData.empty() {
    return const CellData(value: '');
  }

  bool get isEmpty => value.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  double? get numericValue {
    if (!isNumeric) return null;
    return double.tryParse(value);
  }

  String get displayValue {
    if (isEmpty) return '';
    if (isNumeric) {
      final numVal = numericValue;
      if (numVal != null && numVal == numVal.roundToDouble()) {
        return numVal.round().toString();
      }
    }
    return value;
  }
}

/// Sheet data model for spreadsheet functionality
/// Handles 2D grid of cells with rows and columns
class CustomerSheet {
  final String id;
  final String customerId;
  final String title;
  final List<List<CellData>> data;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerSheet({
    required this.id,
    required this.customerId,
    required this.title,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Sheet from Firebase document
  /// Reconstructs 2D array from flat map structure
  factory CustomerSheet.fromMap(Map<String, dynamic> map, String documentId) {
    final rowCount = map['rowCount'] ?? 10;
    final columnCount = map['columnCount'] ?? 5;

    // Initialize empty 2D array
    List<List<CellData>> data = [];
    for (int row = 0; row < rowCount; row++) {
      List<CellData> rowData = [];
      for (int col = 0; col < columnCount; col++) {
        rowData.add(CellData.empty());
      }
      data.add(rowData);
    }

    // Fill data from flat map structure
    final cellsMap = map['cells'] as Map<String, dynamic>? ?? {};
    for (String cellKey in cellsMap.keys) {
      final parts = cellKey.split('_');
      if (parts.length == 3 && parts[0] == 'cell') {
        final row = int.tryParse(parts[1]) ?? 0;
        final col = int.tryParse(parts[2]) ?? 0;

        if (row < rowCount && col < columnCount) {
          data[row][col] = CellData.fromMap(cellsMap[cellKey]);
        }
      }
    }

    return CustomerSheet(
      id: documentId,
      customerId: map['customerId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      data: data,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  /// Convert Sheet to Map for Firebase
  /// Flattens 2D array into a flat map structure for Firestore compatibility
  Map<String, dynamic> toMap() {
    Map<String, dynamic> cellsMap = {};

    // Convert 2D array to flat map with keys like "cell_0_1" (row_column)
    for (int row = 0; row < data.length; row++) {
      for (int col = 0; col < data[row].length; col++) {
        final cellKey = 'cell_${row}_$col';
        cellsMap[cellKey] = data[row][col].toMap();
      }
    }

    return {
      'customerId': customerId,
      'title': title,
      'rowCount': rowCount,
      'columnCount': columnCount,
      'cells': cellsMap,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create a copy with optional changes
  CustomerSheet copyWith({
    String? id,
    String? customerId,
    String? title,
    List<List<CellData>>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerSheet(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      title: title ?? this.title,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Update sheet with new timestamp
  CustomerSheet update({
    String? title,
    List<List<CellData>>? data,
  }) {
    return copyWith(
      title: title?.trim(),
      data: data,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a new empty sheet
  factory CustomerSheet.create({
    required String customerId,
    required String title,
    int rows = 10,
    int columns = 5,
  }) {
    final now = DateTime.now();

    // Create empty grid
    List<List<CellData>> data = [];
    for (int i = 0; i < rows; i++) {
      List<CellData> row = [];
      for (int j = 0; j < columns; j++) {
        row.add(CellData.empty());
      }
      data.add(row);
    }

    return CustomerSheet(
      id: '',
      customerId: customerId,
      title: title.trim(),
      data: data,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Helper method to parse timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    if (timestamp is DateTime) {
      return timestamp;
    }

    return DateTime.now();
  }

  /// Get number of rows
  int get rowCount => data.length;

  /// Get number of columns (based on first row)
  int get columnCount => data.isEmpty ? 0 : data[0].length;

  /// Check if sheet is empty (no data)
  bool get isEmpty {
    for (var row in data) {
      for (var cell in row) {
        if (cell.isNotEmpty) return false;
      }
    }
    return true;
  }

  /// Check if sheet has data
  bool get isNotEmpty => !isEmpty;

  /// Get cell at specific position
  CellData? getCell(int row, int column) {
    if (row < 0 || row >= rowCount || column < 0 || column >= columnCount) {
      return null;
    }
    return data[row][column];
  }

  /// Set cell at specific position
  CustomerSheet setCell(int row, int column, CellData cellData) {
    if (row < 0 || row >= rowCount || column < 0 || column >= columnCount) {
      return this;
    }

    List<List<CellData>> newData = [];
    for (int i = 0; i < data.length; i++) {
      List<CellData> newRow = [];
      for (int j = 0; j < data[i].length; j++) {
        if (i == row && j == column) {
          newRow.add(cellData);
        } else {
          newRow.add(data[i][j]);
        }
      }
      newData.add(newRow);
    }

    return copyWith(data: newData, updatedAt: DateTime.now());
  }

  /// Add a new row at the end
  CustomerSheet addRow() {
    if (rowCount >= 100) return this;

    List<CellData> newRow = [];
    for (int i = 0; i < columnCount; i++) {
      newRow.add(CellData.empty());
    }

    List<List<CellData>> newData = List.from(data);
    newData.add(newRow);

    return copyWith(data: newData, updatedAt: DateTime.now());
  }

  /// Add a new column at the end
  CustomerSheet addColumn() {
    if (columnCount >= 20) return this;

    List<List<CellData>> newData = [];
    for (var row in data) {
      List<CellData> newRow = List.from(row);
      newRow.add(CellData.empty());
      newData.add(newRow);
    }

    return copyWith(data: newData, updatedAt: DateTime.now());
  }

  /// Remove a row
  CustomerSheet removeRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= rowCount || rowCount <= 1) {
      return this;
    }

    List<List<CellData>> newData = [];
    for (int i = 0; i < data.length; i++) {
      if (i != rowIndex) {
        newData.add(List.from(data[i]));
      }
    }

    return copyWith(data: newData, updatedAt: DateTime.now());
  }

  /// Remove a column
  CustomerSheet removeColumn(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= columnCount || columnCount <= 1) {
      return this;
    }

    List<List<CellData>> newData = [];
    for (var row in data) {
      List<CellData> newRow = [];
      for (int j = 0; j < row.length; j++) {
        if (j != columnIndex) {
          newRow.add(row[j]);
        }
      }
      newData.add(newRow);
    }

    return copyWith(data: newData, updatedAt: DateTime.now());
  }

  /// Count non-empty cells
  int get nonEmptyCellCount {
    int count = 0;
    for (var row in data) {
      for (var cell in row) {
        if (cell.isNotEmpty) count++;
      }
    }
    return count;
  }

  /// Get formatted creation date
  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get formatted last update date
  String get formattedUpdatedDate {
    return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
  }

  /// Check if sheet was recently updated
  bool get wasRecentlyUpdated {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    return difference.inHours < 24;
  }

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

  /// Validate sheet data
  bool isValid() {
    return title.trim().isNotEmpty &&
        customerId.trim().isNotEmpty &&
        data.isNotEmpty &&
        title.length <= 100;
  }

  /// Search within sheet data
  bool containsSearchTerm(String searchTerm) {
    if (searchTerm.trim().isEmpty) return true;

    final lowerSearch = searchTerm.toLowerCase().trim();

    if (title.toLowerCase().contains(lowerSearch)) return true;

    for (var row in data) {
      for (var cell in row) {
        if (cell.value.toLowerCase().contains(lowerSearch)) return true;
      }
    }

    return false;
  }

  /// Get sheet summary for display
  String get summary {
    final cellCount = nonEmptyCellCount;
    return '$rowCount rows × $columnCount columns ($cellCount filled)';
  }

  @override
  String toString() {
    return 'CustomerSheet(id: $id, customerId: $customerId, title: "$title", ${rowCount}x$columnCount)';
  }
}