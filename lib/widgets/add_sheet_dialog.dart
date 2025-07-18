import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/sheet.dart';
import '../providers/sheet_provider.dart';
import '../utils/constants.dart';

/// Add sheet dialog optimized for Android phones
/// Beautiful form for creating new spreadsheets
class AddSheetDialog extends StatefulWidget {
  final Customer customer;
  final CustomerSheet? existingSheet; // For editing existing sheets

  const AddSheetDialog({
    Key? key,
    required this.customer,
    this.existingSheet,
  }) : super(key: key);

  @override
  State<AddSheetDialog> createState() => _AddSheetDialogState();
}

class _AddSheetDialogState extends State<AddSheetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Sheet dimensions
  int _rows = 10;
  int _columns = 5;

  // Focus node for title field
  final _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Pre-fill form if editing existing sheet
    if (widget.existingSheet != null) {
      _titleController.text = widget.existingSheet!.title;
      _rows = widget.existingSheet!.rowCount;
      _columns = widget.existingSheet!.columnCount;
    }

    // Auto-focus title field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSheet != null;

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
                child: _buildForm(isEditing),
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
            isEditing ? Icons.edit : Icons.table_chart_outlined,
            color: Colors.white,
            size: AppDimensions.iconSizeLarge,
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? AppStrings.editSheet : AppStrings.addSheet,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'For ${widget.customer.name}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
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
  Widget _buildForm(bool isEditing) {
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

          // Sheet title field
          _buildTitleField(),

          // Sheet dimensions (only for new sheets)
          if (!isEditing) ...[
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildDimensionsSection(),
          ],

          // Sheet templates (only for new sheets)
          if (!isEditing) ...[
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildTemplatesSection(),
          ],
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

  /// Build sheet title field
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      focusNode: _titleFocus,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: AppStrings.sheetTitle,
        hintText: 'Enter sheet title (e.g., Plant Orders, Inventory)',
        prefixIcon: const Icon(Icons.title, color: AppColors.primary),
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
        if (value.trim().length > 100) {
          return AppStrings.tooLong;
        }
        return null;
      },
    );
  }

  /// Build sheet dimensions section
  Widget _buildDimensionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sheet Size',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        const Text(
          'Choose the initial size for your spreadsheet',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),

        // Rows selector
        _buildDimensionSelector(
          label: 'Rows',
          value: _rows,
          min: 5,
          max: 50,
          onChanged: (value) => setState(() => _rows = value),
        ),

        const SizedBox(height: AppDimensions.paddingMedium),

        // Columns selector
        _buildDimensionSelector(
          label: 'Columns',
          value: _columns,
          min: 3,
          max: 15,
          onChanged: (value) => setState(() => _columns = value),
        ),

        // Size preview
        const SizedBox(height: AppDimensions.paddingSmall),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingSmall),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Total cells: ${_rows * _columns}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build dimension selector
  Widget _buildDimensionSelector({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Decrease button
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.primary,
        ),

        // Value display
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),

        // Increase button
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primary,
        ),

        // Slider for quick adjustment
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor: AppColors.primary,
            onChanged: (newValue) => onChanged(newValue.round()),
          ),
        ),
      ],
    );
  }

  /// Build templates section
  Widget _buildTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Templates',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        const Text(
          'Or choose a predefined template',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),

        // Template options
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTemplateChip(
              label: 'Small (5×3)',
              rows: 5,
              columns: 3,
            ),
            _buildTemplateChip(
              label: 'Medium (10×5)',
              rows: 10,
              columns: 5,
            ),
            _buildTemplateChip(
              label: 'Large (20×8)',
              rows: 20,
              columns: 8,
            ),
            _buildTemplateChip(
              label: 'Orders (15×6)',
              rows: 15,
              columns: 6,
            ),
          ],
        ),
      ],
    );
  }

  /// Build template chip
  Widget _buildTemplateChip({
    required String label,
    required int rows,
    required int columns,
  }) {
    final isSelected = _rows == rows && _columns == columns;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _rows = rows;
            _columns = columns;
          });
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
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

          // Create/Save button
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _saveSheet(context, isEditing),
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
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditing ? Icons.save : Icons.create,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? AppStrings.save : 'Create Sheet',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Save sheet (create or update)
  Future<void> _saveSheet(BuildContext context, bool isEditing) async {
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
      final sheetProvider = context.read<SheetProvider>();

      // Check for duplicate titles (if not editing same sheet)
      final title = _titleController.text.trim();
      final excludeId = isEditing ? widget.existingSheet!.id : null;

      if (sheetProvider.isSheetTitleTaken(title, excludeId: excludeId)) {
        setState(() {
          _errorMessage = 'A sheet with this title already exists for this customer';
          _isLoading = false;
        });
        return;
      }

      // Create or update sheet
      CustomerSheet sheet;
      bool success;

      if (isEditing) {
        // Update existing sheet title only
        sheet = widget.existingSheet!.update(title: title);
        success = await sheetProvider.updateSheet(sheet);
      } else {
        // Create new sheet
        sheet = CustomerSheet.create(
          customerId: widget.customer.id,
          title: title,
          rows: _rows,
          columns: _columns,
        );
        success = await sheetProvider.addSheet(sheet);
      }

      if (success) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Sheet updated successfully!'
                    : 'Sheet created successfully!',
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
          _errorMessage = sheetProvider.error ?? 'Failed to save sheet';
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

/// Quick add sheet dialog with minimal options
class QuickAddSheetDialog extends StatefulWidget {
  final Customer customer;

  const QuickAddSheetDialog({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  State<QuickAddSheetDialog> createState() => _QuickAddSheetDialogState();
}

class _QuickAddSheetDialogState extends State<QuickAddSheetDialog> {
  final _titleController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${AppStrings.addSheet} for ${widget.customer.name}'),
      content: TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: AppStrings.sheetTitle,
          hintText: 'Enter sheet title',
          prefixIcon: Icon(Icons.title),
        ),
        textInputAction: TextInputAction.done,
        autofocus: true,
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
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _quickSave() async {
    if (_titleController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sheet = CustomerSheet.create(
        customerId: widget.customer.id,
        title: _titleController.text.trim(),
      );

      final success = await context.read<SheetProvider>().addSheet(sheet);

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