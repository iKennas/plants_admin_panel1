import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/firebase_service.dart';

/// Provider for managing customer data state
/// Handles loading, adding, updating, and deleting customers
class CustomerProvider extends ChangeNotifier {
  // Private state variables
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  Customer? _selectedCustomer;

  // Public getters
  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  Customer? get selectedCustomer => _selectedCustomer;

  // Computed properties
  bool get hasCustomers => _customers.isNotEmpty;
  bool get hasError => _error != null;
  int get customerCount => _customers.length;

  /// Get filtered customers based on search query
  List<Customer> get filteredCustomers {
    if (_searchQuery.trim().isEmpty) {
      return _customers;
    }

    return _customers
        .where((customer) => customer.matchesSearch(_searchQuery))
        .toList();
  }

  // ==========================================================================
  // LOADING OPERATIONS
  // ==========================================================================

  /// Load all customers from Firebase
  Future<void> loadCustomers() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _setLoading(true);
    clearError();

    try {
      final customers = await FirebaseService.getCustomers();
      _customers = customers;

      print('Loaded ${customers.length} customers');
    } catch (e) {
      _setError('Failed to load customers: $e');
      print('Error loading customers: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh customers (reload from server)
  Future<void> refreshCustomers() async {
    await loadCustomers();
  }

  /// Load customers with real-time updates (stream)
  void startListeningToCustomers() {
    FirebaseService.customersStream().listen(
          (customers) {
        _customers = customers;
        clearError();
        notifyListeners();
      },
      onError: (error) {
        _setError('Real-time update failed: $error');
      },
    );
  }

  // ==========================================================================
  // CUSTOMER OPERATIONS
  // ==========================================================================

  /// Add a new customer
  Future<bool> addCustomer(Customer customer) async {
    if (!customer.isValid()) {
      _setError('Invalid customer data');
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      final customerId = await FirebaseService.addCustomer(customer);

      if (customerId != null) {
        // Add to local list with the new ID
        final newCustomer = customer.copyWith(id: customerId);
        _customers.insert(0, newCustomer); // Add to beginning (newest first)

        print('Customer added successfully: $customerId');
        return true;
      } else {
        _setError('Failed to add customer to database');
        return false;
      }
    } catch (e) {
      _setError('Error adding customer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing customer
  Future<bool> updateCustomer(Customer customer) async {
    if (!customer.isValid()) {
      _setError('Invalid customer data');
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      final success = await FirebaseService.updateCustomer(customer);

      if (success) {
        // Update local list
        final index = _customers.indexWhere((c) => c.id == customer.id);
        if (index != -1) {
          _customers[index] = customer;
        }

        // Update selected customer if it's the same one
        if (_selectedCustomer?.id == customer.id) {
          _selectedCustomer = customer;
        }

        print('Customer updated successfully: ${customer.id}');
        return true;
      } else {
        _setError('Failed to update customer in database');
        return false;
      }
    } catch (e) {
      _setError('Error updating customer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a customer and all their sheets
  Future<bool> deleteCustomer(String customerId) async {
    _setLoading(true);
    clearError();

    try {
      final success = await FirebaseService.deleteCustomer(customerId);

      if (success) {
        // Remove from local list
        _customers.removeWhere((customer) => customer.id == customerId);

        // Clear selected customer if it was deleted
        if (_selectedCustomer?.id == customerId) {
          _selectedCustomer = null;
        }

        print('Customer deleted successfully: $customerId');
        return true;
      } else {
        _setError('Failed to delete customer from database');
        return false;
      }
    } catch (e) {
      _setError('Error deleting customer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get a customer by ID
  Customer? getCustomerById(String customerId) {
    try {
      return _customers.firstWhere((customer) => customer.id == customerId);
    } catch (e) {
      return null;
    }
  }

  // ==========================================================================
  // SEARCH AND FILTER
  // ==========================================================================

  /// Set search query and filter customers
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

  /// Search customers remotely (useful for large datasets)
  Future<void> searchCustomersRemote(String searchTerm) async {
    _setLoading(true);
    clearError();

    try {
      final customers = await FirebaseService.searchCustomers(searchTerm);
      _customers = customers;
      _searchQuery = searchTerm;

      print('Remote search completed: ${customers.length} results');
    } catch (e) {
      _setError('Search failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==========================================================================
  // SELECTION MANAGEMENT
  // ==========================================================================

  /// Select a customer
  void selectCustomer(Customer customer) {
    if (_selectedCustomer?.id != customer.id) {
      _selectedCustomer = customer;
      notifyListeners();
    }
  }

  /// Clear selected customer
  void clearSelection() {
    if (_selectedCustomer != null) {
      _selectedCustomer = null;
      notifyListeners();
    }
  }

  // ==========================================================================
  // SORTING AND ORGANIZATION
  // ==========================================================================

  /// Sort customers by name (A-Z)
  void sortCustomersByName({bool ascending = true}) {
    _customers.sort((a, b) {
      final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return ascending ? comparison : -comparison;
    });
    notifyListeners();
  }

  /// Sort customers by creation date
  void sortCustomersByDate({bool newestFirst = true}) {
    _customers.sort((a, b) {
      final comparison = a.createdAt.compareTo(b.createdAt);
      return newestFirst ? -comparison : comparison;
    });
    notifyListeners();
  }

  /// Sort customers by last update
  void sortCustomersByLastUpdate({bool recentFirst = true}) {
    _customers.sort((a, b) {
      final comparison = a.updatedAt.compareTo(b.updatedAt);
      return recentFirst ? -comparison : comparison;
    });
    notifyListeners();
  }

  // ==========================================================================
  // STATISTICS AND ANALYTICS
  // ==========================================================================

  /// Get customers created in the last 7 days
  List<Customer> get recentCustomers {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _customers
        .where((customer) => customer.createdAt.isAfter(weekAgo))
        .toList();
  }

  /// Get customers updated recently
  List<Customer> get recentlyUpdatedCustomers {
    return _customers
        .where((customer) => customer.wasRecentlyUpdated)
        .toList();
  }

  /// Get customer statistics
  Map<String, dynamic> get statistics {
    return {
      'total': _customers.length,
      'recent': recentCustomers.length,
      'recentlyUpdated': recentlyUpdatedCustomers.length,
      'withNotes': _customers.where((c) => c.hasNotes).length,
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

  // ==========================================================================
  // BATCH OPERATIONS
  // ==========================================================================

  /// Delete multiple customers
  Future<bool> deleteMultipleCustomers(List<String> customerIds) async {
    _setLoading(true);
    clearError();

    try {
      bool allSuccess = true;

      for (String customerId in customerIds) {
        final success = await FirebaseService.deleteCustomer(customerId);
        if (!success) {
          allSuccess = false;
        } else {
          // Remove from local list
          _customers.removeWhere((customer) => customer.id == customerId);
        }
      }

      // Clear selection if any deleted customer was selected
      if (_selectedCustomer != null &&
          customerIds.contains(_selectedCustomer!.id)) {
        _selectedCustomer = null;
      }

      if (allSuccess) {
        print('All customers deleted successfully');
      } else {
        _setError('Some customers could not be deleted');
      }

      return allSuccess;
    } catch (e) {
      _setError('Error in batch delete: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==========================================================================
  // VALIDATION AND UTILITIES
  // ==========================================================================

  /// Check if customer name already exists
  bool isCustomerNameTaken(String name, {String? excludeId}) {
    return _customers.any((customer) =>
    customer.name.toLowerCase() == name.toLowerCase() &&
        customer.id != excludeId
    );
  }

  /// Get customer by phone number
  Customer? getCustomerByPhone(String phoneNumber) {
    try {
      return _customers.firstWhere(
              (customer) => customer.phoneNumber == phoneNumber
      );
    } catch (e) {
      return null;
    }
  }

  /// Reset provider to initial state
  void reset() {
    _customers = [];
    _isLoading = false;
    _error = null;
    _searchQuery = '';
    _selectedCustomer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up any subscriptions or resources
    super.dispose();
  }
}