import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/sheet.dart';
import '../utils/constants.dart';

/// Firebase service for all database operations
/// Handles CRUD operations for customers and sheets
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================================================
  // CUSTOMER OPERATIONS
  // ==========================================================================

  /// Get all customers ordered by creation date (newest first)
  static Future<List<Customer>> getCustomers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.customersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Customer.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      print('Error getting customers: $e');
      return [];
    }
  }

  /// Add a new customer to Firebase
  static Future<String?> addCustomer(Customer customer) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(AppConstants.customersCollection)
          .add(customer.toMap());

      print('Customer added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding customer: $e');
      return null;
    }
  }

  /// Update an existing customer
  static Future<bool> updateCustomer(Customer customer) async {
    try {
      await _firestore
          .collection(AppConstants.customersCollection)
          .doc(customer.id)
          .update(customer.toMap());

      print('Customer updated: ${customer.id}');
      return true;
    } catch (e) {
      print('Error updating customer: $e');
      return false;
    }
  }

  /// Delete a customer and all their sheets
  static Future<bool> deleteCustomer(String customerId) async {
    try {
      // First, delete all sheets for this customer
      QuerySnapshot sheets = await _firestore
          .collection(AppConstants.sheetsCollection)
          .where('customerId', isEqualTo: customerId)
          .get();

      // Delete each sheet
      for (QueryDocumentSnapshot sheet in sheets.docs) {
        await sheet.reference.delete();
      }

      // Then delete the customer
      await _firestore
          .collection(AppConstants.customersCollection)
          .doc(customerId)
          .delete();

      print('Customer and all sheets deleted: $customerId');
      return true;
    } catch (e) {
      print('Error deleting customer: $e');
      return false;
    }
  }

  /// Get a single customer by ID
  static Future<Customer?> getCustomer(String customerId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.customersCollection)
          .doc(customerId)
          .get();

      if (doc.exists) {
        return Customer.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting customer: $e');
      return null;
    }
  }

  /// Search customers by name or phone
  static Future<List<Customer>> searchCustomers(String searchTerm) async {
    try {
      // Get all customers and filter locally (Firestore has limited search)
      List<Customer> allCustomers = await getCustomers();

      if (searchTerm.trim().isEmpty) {
        return allCustomers;
      }

      return allCustomers
          .where((customer) => customer.matchesSearch(searchTerm))
          .toList();
    } catch (e) {
      print('Error searching customers: $e');
      return [];
    }
  }

  // ==========================================================================
  // SHEET OPERATIONS
  // ==========================================================================

  /// Get all sheets for a specific customer
  static Future<List<CustomerSheet>> getCustomerSheets(String customerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.sheetsCollection)
          .where('customerId', isEqualTo: customerId)
          .get();

      List<CustomerSheet> sheets = snapshot.docs
          .map((doc) => CustomerSheet.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();

      // Sort by creation date locally (newest first)
      sheets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return sheets;
    } catch (e) {
      print('Error getting customer sheets: $e');
      return [];
    }
  }

  /// Add a new sheet for a customer
  static Future<String?> addSheet(CustomerSheet sheet) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(AppConstants.sheetsCollection)
          .add(sheet.toMap());

      print('Sheet added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding sheet: $e');
      return null;
    }
  }

  /// Update an existing sheet
  static Future<bool> updateSheet(CustomerSheet sheet) async {
    try {
      await _firestore
          .collection(AppConstants.sheetsCollection)
          .doc(sheet.id)
          .update(sheet.toMap());

      print('Sheet updated: ${sheet.id}');
      return true;
    } catch (e) {
      print('Error updating sheet: $e');
      return false;
    }
  }

  /// Delete a sheet
  static Future<bool> deleteSheet(String sheetId) async {
    try {
      await _firestore
          .collection(AppConstants.sheetsCollection)
          .doc(sheetId)
          .delete();

      print('Sheet deleted: $sheetId');
      return true;
    } catch (e) {
      print('Error deleting sheet: $e');
      return false;
    }
  }

  /// Get a single sheet by ID
  static Future<CustomerSheet?> getSheet(String sheetId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.sheetsCollection)
          .doc(sheetId)
          .get();

      if (doc.exists) {
        return CustomerSheet.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting sheet: $e');
      return null;
    }
  }

  // ==========================================================================
  // STREAM OPERATIONS (Real-time updates)
  // ==========================================================================

  /// Stream of customers (real-time updates)
  static Stream<List<Customer>> customersStream() {
    return _firestore
        .collection(AppConstants.customersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Customer.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    });
  }

  /// Stream of sheets for a customer (real-time updates)
  static Stream<List<CustomerSheet>> customerSheetsStream(String customerId) {
    return _firestore
        .collection(AppConstants.sheetsCollection)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      List<CustomerSheet> sheets = snapshot.docs
          .map((doc) => CustomerSheet.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();

      // Sort by creation date locally (newest first)
      sheets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return sheets;
    });
  }

  // ==========================================================================
  // UTILITY OPERATIONS
  // ==========================================================================

  /// Check if Firestore connection is working
  static Future<bool> testConnection() async {
    try {
      // Try to read from a collection (this will fail if no connection)
      await _firestore
          .collection('test')
          .limit(1)
          .get();

      print('Firebase connection test: SUCCESS');
      return true;
    } catch (e) {
      print('Firebase connection test: FAILED - $e');
      return false;
    }
  }
}