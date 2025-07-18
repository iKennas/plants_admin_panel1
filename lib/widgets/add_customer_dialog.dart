import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../utils/constants.dart';

/// Add customer dialog optimized for Android phones
/// Beautiful form with validation and error handling
class AddCustomerDialog extends StatefulWidget {
  final Customer? existingCustomer; // For editing existing customers

  const AddCustomerDialog({
    Key? key,
    this.existingCustomer,
  }) : super(key: key);

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Focus nodes for better UX
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _notesFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Pre-fill form if editing existing customer
    if (widget.existingCustomer != null) {
      _nameController.text = widget.existingCustomer!.name;
      _phoneController.text = widget.existingCustomer!.phoneNumber;
      _notesController.text = widget.existingCustomer!.notes;
    }

    // Auto-focus name field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCustomer != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(isEditing),

            // Form content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: _buildForm(),
              ),
            ),

            // Action buttons
            _buildActionButtons(context, isEditing),
          ],
        ),
      ),
    );
  }

  /// Build dialog header
  Widget _buildHeader(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusMedium),
          topRight: Radius.circular(AppDimensions.radiusMedium),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEditing ? Icons.edit : Icons.person_add,
            color: Colors.white,
            size: AppDimensions.iconSizeLarge,
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Text(
              isEditing ? AppStrings.editCustomer : AppStrings.addCustomer,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build form fields
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error message display
          if (_errorMessage != null) ...[
            _buildErrorMessage(),
            const SizedBox(height: AppDimensions.paddingMedium),
          ],

          // Customer name field
          _buildNameField(),
          const SizedBox(height: AppDimensions.paddingMedium),

          // Phone number field
          _buildPhoneField(),
          const SizedBox(height: AppDimensions.paddingMedium),

          // Notes field
          _buildNotesField(),
        ],
      ),
    );
  }

  /// Build error message widget
  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build customer name field
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocus,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
      decoration: InputDecoration(
        labelText: AppStrings.customerName,
        hintText: 'Enter customer full name',
        prefixIcon: const Icon(Icons.person, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppStrings.required;
        }
        if (value.trim().length < 2) {
          return AppStrings.tooShort;
        }
        if (value.trim().length > AppConstants.maxCustomerNameLength) {
          return AppStrings.tooLong;
        }
        return null;
      },
    );
  }

  /// Build phone number field
  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      focusNode: _phoneFocus,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _notesFocus.requestFocus(),
      decoration: InputDecoration(
        labelText: AppStrings.customerPhone,
        hintText: 'Enter phone number',
        prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppStrings.required;
        }
        if (value.trim().length < 8) {
          return AppStrings.invalidPhone;
        }
        if (value.trim().length > AppConstants.maxPhoneNumberLength) {
          return AppStrings.tooLong;
        }
        return null;
      },
    );
  }

  /// Build notes field
  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      focusNode: _notesFocus,
      textInputAction: TextInputAction.done,
      maxLines: 3,
      maxLength: AppConstants.maxNotesLength,
      decoration: InputDecoration(
        labelText: '${AppStrings.customerNotes} (Optional)',
        hintText: 'Enter any additional notes about the customer...',
        prefixIcon: const Icon(Icons.note, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value != null && value.length > AppConstants.maxNotesLength) {
          return AppStrings.tooLong;
        }
        return null;
      },
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context, bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusMedium),
          bottomRight: Radius.circular(AppDimensions.radiusMedium),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
              ),
              child: const Text(
                AppStrings.cancel,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),

          const SizedBox(width: AppDimensions.paddingMedium),

          // Save button
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _saveCustomer(context, isEditing),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                isEditing ? AppStrings.save : AppStrings.add,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Save customer (add or update)
  Future<void> _saveCustomer(BuildContext context, bool isEditing) async {
    // Clear any previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Start loading
    setState(() {
      _isLoading = true;
    });

    try {
      final customerProvider = context.read<CustomerProvider>();

      // Check for duplicate names (if not editing same customer)
      final name = _nameController.text.trim();
      final excludeId = isEditing ? widget.existingCustomer!.id : null;

      if (customerProvider.isCustomerNameTaken(name, excludeId: excludeId)) {
        setState(() {
          _errorMessage = 'A customer with this name already exists';
          _isLoading = false;
        });
        return;
      }

      // Create or update customer
      Customer customer;
      bool success;

      if (isEditing) {
        // Update existing customer
        customer = widget.existingCustomer!.update(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          notes: _notesController.text.trim(),
        );
        success = await customerProvider.updateCustomer(customer);
      } else {
        // Create new customer
        customer = Customer.create(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          notes: _notesController.text.trim(),
        );
        success = await customerProvider.addCustomer(customer);
      }

      if (success) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Customer updated successfully!'
                    : 'Customer added successfully!',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );

          // Close dialog
          Navigator.of(context).pop(true);
        }
      } else {
        // Show error from provider
        setState(() {
          _errorMessage = customerProvider.error ?? 'Failed to save customer';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }
}

/// Quick add customer dialog with minimal fields
class QuickAddCustomerDialog extends StatefulWidget {
  const QuickAddCustomerDialog({Key? key}) : super(key: key);

  @override
  State<QuickAddCustomerDialog> createState() => _QuickAddCustomerDialogState();
}

class _QuickAddCustomerDialogState extends State<QuickAddCustomerDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.addCustomer),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: AppStrings.customerName,
              prefixIcon: Icon(Icons.person),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: AppStrings.customerPhone,
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _quickSave,
          child: _isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text(AppStrings.add),
        ),
      ],
    );
  }

  Future<void> _quickSave() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customer = Customer.create(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      final success = await context.read<CustomerProvider>().addCustomer(customer);

      if (success && context.mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}