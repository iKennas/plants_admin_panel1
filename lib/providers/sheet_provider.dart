import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/sheet.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';

/// Provider for managing sheet data state
/// Handles loading, editing, and managing customer sheets
class SheetProvider extends ChangeNotifier {
  // Private state variables
  List<CustomerSheet> _sheets = [];
  bool _isLoading = false;
  String? _error;
  String? _currentCustomerId;
  CustomerSheet? _selectedSheet;
  String _searchQuery = '';
  bool _isEditingMode = false;

  // Public getters
  List<CustomerSheet> get sheets => _sheets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentCustomerId => _currentCustomerId;
  CustomerSheet? get selectedSheet => _selectedSheet;
  String get searchQuery => _searchQuery;
  bool get isEditingMode => _isEditingMode;

  // Computed properties
  bool get hasSheets => _sheets.isNotEmpty;
  bool get hasError => _error != null;
  int get sheetCount => _sheets.length;
  bool get hasSelectedSheet => _selectedSheet != null;

  /// Get filtered sheets based on search query
  List<CustomerSheet> get filteredSheets {
    if (_searchQuery.trim().isEmpty) {
      return _sheets;
    }

    return _sheets
        .where((sheet) => sheet.containsSearchTerm(_searchQuery))
        .toList();
  }

  // ==========================================================================
  // LOADING OPERATIONS
  // ==========================================================================

  /// Load all sheets for a specific customer
  Future<void> loadCustomerSheets(String customerId) async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _currentCustomerId = customerId;
    _setLoading(true);
    clearError();

    try {
      final sheets = await FirebaseService.getCustomerSheets(customerId);
      _sheets = sheets;

      print('Loaded ${sheets.length} sheets for customer: $customerId');
    } catch (e) {
      _setError('Failed to load sheets: $e');
      print('Error loading sheets: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh sheets (reload from server)
  Future<void> refreshSheets() async {
    if (_currentCustomerId != null) {
      await loadCustomerSheets(_currentCustomerId!);
    }
  }

  /// Load sheets with real-time updates (stream)
  void startListeningToSheets(String customerId) {
    _currentCustomerId = customerId;

    FirebaseService.customerSheetsStream(customerId).listen(
          (sheets) {
        _sheets = sheets;
        clearError();
        notifyListeners();
      },
      onError: (error) {
        _setError('Real-time update failed: $error');
      },
    );
  }

  // ==========================================================================
  // SHEET OPERATIONS
  // ==========================================================================

  /// Add a new sheet
  Future<bool> addSheet(CustomerSheet sheet) async {
    if (!sheet.isValid()) {
      _setError('Invalid sheet data');
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      final sheetId = await FirebaseService.addSheet(sheet);

      if (sheetId != null) {
        // Add to local list with the new ID
        final newSheet = sheet.copyWith(id: sheetId);
        _sheets.insert(0, newSheet); // Add to beginning (newest first)

        print('Sheet added successfully: $sheetId');
        return true;
      } else {
        _setError('Failed to add sheet to database');
        return false;
      }
    } catch (e) {
      _setError('Error adding sheet: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing sheet
  Future<bool> updateSheet(CustomerSheet sheet) async {
    if (!sheet.isValid()) {
      _setError('Invalid sheet data');
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      final success = await FirebaseService.updateSheet(sheet);

      if (success) {
        // Update local list
        final index = _sheets.indexWhere((s) => s.id == sheet.id);
        if (index != -1) {
          _sheets[index] = sheet;
        }

        // Update selected sheet if it's the same one
        if (_selectedSheet?.id == sheet.id) {
          _selectedSheet = sheet;
        }

        print('Sheet updated successfully: ${sheet.id}');
        return true;
      } else {
        _setError('Failed to update sheet in database');
        return false;
      }
    } catch (e) {
      _setError('Error updating sheet: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a sheet
  Future<bool> deleteSheet(String sheetId) async {
    _setLoading(true);
    clearError();

    try {
      final success = await FirebaseService.deleteSheet(sheetId);

      if (success) {
        // Remove from local list
        _sheets.removeWhere((sheet) => sheet.id == sheetId);

        // Clear selected sheet if it was deleted
        if (_selectedSheet?.id == sheetId) {
          _selectedSheet = null;
          _isEditingMode = false;
        }

        print('Sheet deleted successfully: $sheetId');
        return true;
      } else {
        _setError('Failed to delete sheet from database');
        return false;
      }
    } catch (e) {
      _setError('Error deleting sheet: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get a sheet by ID
  CustomerSheet? getSheetById(String sheetId) {
    try {
      return _sheets.firstWhere((sheet) => sheet.id == sheetId);
    } catch (e) {
      return null;
    }
  }

  // ==========================================================================
  // SHEET EDITING OPERATIONS
  // ==========================================================================

  /// Select a sheet for editing
  void selectSheet(CustomerSheet sheet) {
    if (_selectedSheet?.id != sheet.id) {
      _selectedSheet = sheet;
      _isEditingMode = false; // Reset editing mode
      notifyListeners();
    }
  }

  /// Enter editing mode for selected sheet
  void enterEditingMode() {
    if (_selectedSheet != null && !_isEditingMode) {
      _isEditingMode = true;
      notifyListeners();
    }
  }

  /// Exit editing mode
  void exitEditingMode() {
    if (_isEditingMode) {
      _isEditingMode = false;
      notifyListeners();
    }
  }

  /// Update cell in selected sheet (local only)
  void updateCellInSelectedSheet(int row, int column, CellData cellData) {
    if (_selectedSheet == null) return;

    final updatedSheet = _selectedSheet!.setCell(row, column, cellData);
    _selectedSheet = updatedSheet;

    // Also update in the sheets list
    final index = _sheets.indexWhere((s) => s.id == updatedSheet.id);
    if (index != -1) {
      _sheets[index] = updatedSheet;
    }

    notifyListeners();
  }

  /// Add row to selected sheet (local only)
  void addRowToSelectedSheet() {
    if (_selectedSheet == null) return;

    final updatedSheet = _selectedSheet!.addRow();
    _selectedSheet = updatedSheet;

    // Update in sheets list
    final index = _sheets.indexWhere((s) => s.id == updatedSheet.id);
    if (index != -1) {
      _sheets[index] = updatedSheet;
    }

    notifyListeners();
  }

  /// Add column to selected sheet (local only)
  void addColumnToSelectedSheet() {
    if (_selectedSheet == null) return;

    final updatedSheet = _selectedSheet!.addColumn();
    _selectedSheet = updatedSheet;

    // Update in sheets list
    final index = _sheets.indexWhere((s) => s.id == updatedSheet.id);
    if (index != -1) {
      _sheets[index] = updatedSheet;
    }

    notifyListeners();
  }

  /// Remove row from selected sheet (local only)
  void removeRowFromSelectedSheet(int rowIndex) {
    if (_selectedSheet == null) return;

    final updatedSheet = _selectedSheet!.removeRow(rowIndex);
    _selectedSheet = updatedSheet;

    // Update in sheets list
    final index = _sheets.indexWhere((s) => s.id == updatedSheet.id);
    if (index != -1) {
      _sheets[index] = updatedSheet;
    }

    notifyListeners();
  }

  /// Remove column from selected sheet (local only)
  void removeColumnFromSelectedSheet(int columnIndex) {
    if (_selectedSheet == null) return;

    final updatedSheet = _selectedSheet!.removeColumn(columnIndex);
    _selectedSheet = updatedSheet;

    // Update in sheets list
    final index = _sheets.indexWhere((s) => s.id == updatedSheet.id);
    if (index != -1) {
      _sheets[index] = updatedSheet;
    }

    notifyListeners();
  }

  /// Save current changes to Firebase
  Future<bool> saveSelectedSheet() async {
    if (_selectedSheet == null) return false;

    return await updateSheet(_selectedSheet!);
  }

  // ==========================================================================
  // PDF OPERATIONS
  // ==========================================================================

  /// Generate and share PDF for selected sheet
  Future<bool> exportSelectedSheetToPdf(Customer customer) async {
    if (_selectedSheet == null) {
      _setError('No sheet selected for PDF export');
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      final success = await PdfService.generateAndSharePdf(_selectedSheet!, customer);

      if (success) {
        print('PDF generated and shared successfully');
        return true;
      } else {
        _setError('Failed to generate PDF');
        return false;
      }
    } catch (e) {
      _setError('Error generating PDF: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Generate and save PDF for selected sheet
  Future<String?> saveSelectedSheetToPdf(Customer customer) async {
    if (_selectedSheet == null) {
      _setError('No sheet selected for PDF export');
      return null;
    }

    _setLoading(true);
    clearError();

    try {
      final filePath = await PdfService.generateAndSavePdf(_selectedSheet!, customer);

      if (filePath != null) {
        print('PDF saved successfully: $filePath');
        return filePath;
      } else {
        _setError('Failed to save PDF');
        return null;
      }
    } catch (e) {
      _setError('Error saving PDF: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ==========================================================================
  // SEARCH AND FILTER
  // ==========================================================================

  /// Set search query and filter sheets
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Clear search query
  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

  // ==========================================================================
  // SORTING AND ORGANIZATION
  // ==========================================================================

  /// Sort sheets by title (A-Z)
  void sortSheetsByTitle({bool ascending = true}) {
    _sheets.sort((a, b) {
      final comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return ascending ? comparison : -comparison;
    });
    notifyListeners();
  }

  /// Sort sheets by creation date
  void sortSheetsByDate({bool newestFirst = true}) {
    _sheets.sort((a, b) {
      final comparison = a.createdAt.compareTo(b.createdAt);
      return newestFirst ? -comparison : comparison;
    });
    notifyListeners();
  }

  /// Sort sheets by last update
  void sortSheetsByLastUpdate({bool recentFirst = true}) {
    _sheets.sort((a, b) {
      final comparison = a.updatedAt.compareTo(b.updatedAt);
      return recentFirst ? -comparison : comparison;
    });
    notifyListeners();
  }

  // ==========================================================================
  // STATISTICS AND ANALYTICS
  // ==========================================================================

  /// Get sheets created in the last 7 days
  List<CustomerSheet> get recentSheets {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _sheets
        .where((sheet) => sheet.createdAt.isAfter(weekAgo))
        .toList();
  }

  /// Get sheets updated recently
  List<CustomerSheet> get recentlyUpdatedSheets {
    return _sheets
        .where((sheet) => sheet.wasRecentlyUpdated)
        .toList();
  }

  /// Get sheet statistics
  Map<String, dynamic> get statistics {
    final totalCells = _sheets.fold<int>(
      0,
          (sum, sheet) => sum + (sheet.rowCount * sheet.columnCount),
    );

    final filledCells = _sheets.fold<int>(
      0,
          (sum, sheet) => sum + sheet.nonEmptyCellCount,
    );

    return {
      'total': _sheets.length,
      'recent': recentSheets.length,
      'recentlyUpdated': recentlyUpdatedSheets.length,
      'totalCells': totalCells,
      'filledCells': filledCells,
      'emptySheets': _sheets.where((s) => s.isEmpty).length,
    };
  }

  // ==========================================================================
  // PRIVATE HELPER METHODS
  // ==========================================================================

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();

    // Auto-clear error after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (_error == error) {
        clearError();
      }
    });
  }

  /// Clear error message
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Clear selected sheet
  void clearSelection() {
    if (_selectedSheet != null) {
      _selectedSheet = null;
      _isEditingMode = false;
      notifyListeners();
    }
  }

  // ==========================================================================
  // VALIDATION AND UTILITIES
  // ==========================================================================

  /// Check if sheet title already exists for current customer
  bool isSheetTitleTaken(String title, {String? excludeId}) {
    return _sheets.any((sheet) =>
    sheet.title.toLowerCase() == title.toLowerCase() &&
        sheet.id != excludeId
    );
  }

  /// Reset provider to initial state
  void reset() {
    _sheets = [];
    _isLoading = false;
    _error = null;
    _currentCustomerId = null;
    _selectedSheet = null;
    _searchQuery = '';
    _isEditingMode = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up any subscriptions or resources
    super.dispose();
  }
}