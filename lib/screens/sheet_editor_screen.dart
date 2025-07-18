import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/sheet.dart';
import '../providers/sheet_provider.dart';
import '../widgets/editable_table.dart';
import '../utils/constants.dart';

/// Sheet editor screen for editing spreadsheet data
/// Full-featured editor optimized for Android phones
class SheetEditorScreen extends StatefulWidget {
  final CustomerSheet sheet;
  final Customer customer;

  const SheetEditorScreen({
    Key? key,
    required this.sheet,
    required this.customer,
  }) : super(key: key);

  @override
  State<SheetEditorScreen> createState() => _SheetEditorScreenState();
}

class _SheetEditorScreenState extends State<SheetEditorScreen> {
  late CustomerSheet _currentSheet;
  bool _hasUnsavedChanges = false;
  bool _isAutoSaving = false;
  bool _isViewMode = false;

  @override
  void initState() {
    super.initState();
    _currentSheet = widget.sheet;

    // Select this sheet in the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SheetProvider>().selectSheet(widget.sheet);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Sheet info header
            _buildSheetHeader(),

            // Toolbar
            _buildToolbar(),

            // Sheet editor
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  child: EditableTable(
                    sheet: _currentSheet,
                    onSheetChanged: _onSheetChanged,
                    isReadOnly: _isViewMode,
                    cellWidth: 120.0,
                    cellHeight: 50.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        bottomNavigationBar: _buildBottomAppBar(),
      ),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentSheet.title,
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            widget.customer.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // View/Edit mode toggle
        IconButton(
          onPressed: _toggleViewMode,
          icon: Icon(_isViewMode ? Icons.edit : Icons.visibility),
          tooltip: _isViewMode ? 'وضع التعديل' : 'وضع العرض',
        ),

        // Save button
        if (_hasUnsavedChanges)
          IconButton(
            onPressed: _isAutoSaving ? null : _saveSheet,
            icon: _isAutoSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.save),
            tooltip: AppStrings.save,
          ),

        // More options
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export_pdf',
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf, color: AppColors.error),
                title: Text(AppStrings.exportPdf),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share, color: AppColors.primary),
                title: Text('مشاركة'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'rename',
              child: ListTile(
                leading: Icon(Icons.edit, color: AppColors.primary),
                title: Text('إعادة تسمية'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy, color: AppColors.primary),
                title: Text('نسخ الجدول'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'clear_all',
              child: ListTile(
                leading: Icon(Icons.clear_all, color: AppColors.warning),
                title: Text('مسح جميع البيانات'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text(AppStrings.deleteSheet),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build sheet info header
  Widget _buildSheetHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sheet stats
          Expanded(
            child: Row(
              children: [
                _buildStatChip(
                  icon: Icons.grid_on,
                  label: 'الحجم',
                  value: '${_currentSheet.rowCount}×${_currentSheet.columnCount}',
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.description,
                  label: 'المملوء',
                  value: '${_currentSheet.nonEmptyCellCount}',
                ),
              ],
            ),
          ),

          // Unsaved changes indicator
          if (_hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'غير محفوظ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // View mode indicator
          if (_isViewMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility,
                    size: 14,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'عرض فقط',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build stat chip
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build toolbar
  Widget _buildToolbar() {
    if (_isViewMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Add row button
          _buildToolbarButton(
            icon: Icons.add,
            label: AppStrings.addRow,
            onPressed: _addRow,
          ),

          const SizedBox(width: 8),

          // Add column button
          _buildToolbarButton(
            icon: Icons.add,
            label: AppStrings.addColumn,
            onPressed: _addColumn,
          ),

          const SizedBox(width: 16),

          // Separator
          Container(
            height: 20,
            width: 1,
            color: AppColors.border,
          ),

          const SizedBox(width: 16),

          // Undo button (placeholder)
          _buildToolbarButton(
            icon: Icons.undo,
            label: 'تراجع',
            onPressed: null, // TODO: Implement undo
          ),

          const SizedBox(width: 8),

          // Redo button (placeholder)
          _buildToolbarButton(
            icon: Icons.redo,
            label: 'إعادة',
            onPressed: null, // TODO: Implement redo
          ),

          const Spacer(),

          // Auto-save toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'حفظ تلقائي',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: true, // TODO: Implement auto-save preference
                onChanged: (value) {
                  // TODO: Toggle auto-save
                },
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build toolbar button
  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: onPressed != null
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: onPressed != null
                  ? AppColors.primary
                  : AppColors.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: onPressed != null
                    ? AppColors.primary
                    : AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build floating action button
  Widget? _buildFloatingActionButton() {
    if (_isViewMode) return null;

    return FloatingActionButton(
      onPressed: _saveSheet,
      backgroundColor: _hasUnsavedChanges ? AppColors.primary : AppColors.textHint,
      foregroundColor: Colors.white,
      tooltip: AppStrings.save,
      child: _isAutoSaving
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : const Icon(Icons.save),
    );
  }

  /// Build bottom app bar
  Widget _buildBottomAppBar() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Export PDF button
            TextButton.icon(
              onPressed: _exportToPdf,
              icon: const Icon(Icons.picture_as_pdf, color: AppColors.error),
              label: const Text(
                AppStrings.exportPdf,
                style: TextStyle(color: AppColors.error),
              ),
            ),

            const Spacer(),

            // Last saved info
            if (!_hasUnsavedChanges)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'محفوظ ${_currentSheet.timeSinceCreated}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Handle sheet changes
  void _onSheetChanged(CustomerSheet newSheet) {
    setState(() {
      _currentSheet = newSheet;
      _hasUnsavedChanges = true;
    });

    // Auto-save after 2 seconds of inactivity
    Future.delayed(const Duration(seconds: 2), () {
      if (_hasUnsavedChanges && mounted) {
        _autoSave();
      }
    });
  }

  /// Handle back button press
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغييرات غير محفوظة'),
        content: const Text('لديك تغييرات غير محفوظة. هل تريد حفظها؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('خروج بدون حفظ'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveSheet();
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('حفظ والخروج'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Toggle view/edit mode
  void _toggleViewMode() {
    setState(() {
      _isViewMode = !_isViewMode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isViewMode ? 'تم التبديل إلى وضع العرض' : 'تم التبديل إلى وضع التعديل'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Add row to sheet
  void _addRow() {
    final newSheet = _currentSheet.addRow();
    _onSheetChanged(newSheet);
    HapticFeedback.lightImpact();
  }

  /// Add column to sheet
  void _addColumn() {
    final newSheet = _currentSheet.addColumn();
    _onSheetChanged(newSheet);
    HapticFeedback.lightImpact();
  }

  /// Save sheet
  Future<void> _saveSheet() async {
    if (!_hasUnsavedChanges || _isAutoSaving) return;

    setState(() {
      _isAutoSaving = true;
    });

    try {
      final success = await context.read<SheetProvider>().updateSheet(_currentSheet);

      if (success) {
        setState(() {
          _hasUnsavedChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحفظ بنجاح'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في الحفظ'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isAutoSaving = false;
      });
    }
  }

  /// Auto-save sheet
  Future<void> _autoSave() async {
    await _saveSheet();
  }

  /// Export to PDF
  void _exportToPdf() async {
    try {
      final sheetProvider = context.read<SheetProvider>();
      sheetProvider.selectSheet(_currentSheet);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('جاري إنشاء ملف PDF...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final success = await sheetProvider.exportSelectedSheetToPdf(widget.customer);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.pdfGenerated),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.pdfError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_pdf':
        _exportToPdf();
        break;
      case 'share':
        _shareSheet();
        break;
      case 'rename':
        _renameSheet();
        break;
      case 'duplicate':
        _duplicateSheet();
        break;
      case 'clear_all':
        _clearAllData();
        break;
      case 'delete':
        _deleteSheet();
        break;
    }
  }

  /// Share sheet
  void _shareSheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة المشاركة - قريباً!')),
    );
  }

  /// Rename sheet
  void _renameSheet() {
    final controller = TextEditingController(text: _currentSheet.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تسمية الجدول'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: AppStrings.sheetTitle,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != _currentSheet.title) {
                final updatedSheet = _currentSheet.update(title: newTitle);
                _onSheetChanged(updatedSheet);
              }
              Navigator.of(context).pop();
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  /// Duplicate sheet
  void _duplicateSheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة نسخ الجدول - قريباً!')),
    );
  }

  /// Clear all data
  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح جميع البيانات'),
        content: const Text('هل أنت متأكد من مسح جميع البيانات؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // Create empty sheet with same dimensions
              final emptySheet = CustomerSheet.create(
                customerId: _currentSheet.customerId,
                title: _currentSheet.title,
                rows: _currentSheet.rowCount,
                columns: _currentSheet.columnCount,
              ).copyWith(
                id: _currentSheet.id,
                createdAt: _currentSheet.createdAt,
              );

              _onSheetChanged(emptySheet);
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم مسح جميع البيانات'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  /// Delete sheet
  void _deleteSheet() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: Text('${AppStrings.deleteSheetConfirm}\n\nالجدول: ${_currentSheet.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final success = await context.read<SheetProvider>().deleteSheet(_currentSheet.id);

              if (success && mounted) {
                Navigator.of(context).pop(); // Go back to customer detail
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الجدول'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}