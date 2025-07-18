import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/sheet.dart';
import '../providers/sheet_provider.dart';
import '../utils/constants.dart';

/// Sheet card widget optimized for Android phones
/// Displays sheet information with preview and actions
class SheetCard extends StatelessWidget {
  final CustomerSheet sheet;
  final Customer customer;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const SheetCard({
    Key? key,
    required this.sheet,
    required this.customer,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      elevation: AppDimensions.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and actions
              _buildHeader(context),

              const SizedBox(height: AppDimensions.paddingSmall),

              // Sheet statistics
              _buildStatistics(),

              const SizedBox(height: AppDimensions.paddingSmall),

              // Data preview (if sheet has data)
              if (sheet.isNotEmpty) ...[
                _buildDataPreview(),
                const SizedBox(height: AppDimensions.paddingSmall),
              ],

              // Footer with date and actions
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build sheet header with title and menu
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Sheet icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.table_chart,
            color: AppColors.primary,
            size: 24,
          ),
        ),

        const SizedBox(width: AppDimensions.paddingMedium),

        // Sheet title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheet.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'For ${customer.name}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Actions menu
        if (showActions) _buildActionsMenu(context),
      ],
    );
  }

  /// Build sheet statistics
  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        children: [
          // Dimensions
          _buildStatItem(
            icon: Icons.grid_on,
            label: 'Size',
            value: '${sheet.rowCount}×${sheet.columnCount}',
          ),

          const SizedBox(width: AppDimensions.paddingMedium),

          // Filled cells
          _buildStatItem(
            icon: Icons.description,
            label: 'Filled',
            value: '${sheet.nonEmptyCellCount}',
          ),

          const SizedBox(width: AppDimensions.paddingMedium),

          // Empty status
          if (sheet.isEmpty)
            _buildStatItem(
              icon: Icons.info_outline,
              label: 'Status',
              value: 'Empty',
              valueColor: AppColors.warning,
            ),
        ],
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build data preview section
  Widget _buildDataPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview header
          const Row(
            children: [
              Icon(
                Icons.preview,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 4),
              Text(
                'Data Preview',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Preview table (first few rows/columns)
          _buildPreviewTable(),
        ],
      ),
    );
  }

  /// Build preview table
  Widget _buildPreviewTable() {
    const maxRows = 3;
    const maxCols = 3;

    final previewRows = sheet.rowCount > maxRows ? maxRows : sheet.rowCount;
    final previewCols = sheet.columnCount > maxCols ? maxCols : sheet.columnCount;

    return Table(
      border: TableBorder.all(
        color: AppColors.border,
        width: 0.5,
      ),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: List.generate(previewRows, (row) {
        return TableRow(
          children: List.generate(previewCols, (col) {
            final cellData = sheet.getCell(row, col);
            final cellValue = cellData?.displayValue ?? '';

            return Container(
              padding: const EdgeInsets.all(4),
              child: Text(
                cellValue.isEmpty ? '—' : cellValue,
                style: TextStyle(
                  fontSize: 11,
                  color: cellValue.isEmpty
                      ? AppColors.textHint
                      : AppColors.textPrimary,
                  fontWeight: cellData?.isNumeric == true
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: cellData?.isNumeric == true
                    ? TextAlign.right
                    : TextAlign.left,
              ),
            );
          }) + (sheet.columnCount > maxCols ? [
            Container(
              padding: const EdgeInsets.all(4),
              child: const Text(
                '...',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ] : []),
        );
      }) + (sheet.rowCount > maxRows ? [
        TableRow(
          children: List.generate(
            previewCols + (sheet.columnCount > maxCols ? 1 : 0),
                (index) => Container(
              padding: const EdgeInsets.all(4),
              child: const Text(
                '⋮',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ] : []),
    );
  }

  /// Build sheet footer
  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Last updated
        Icon(
          Icons.access_time,
          size: 14,
          color: AppColors.textHint,
        ),
        const SizedBox(width: 4),
        Text(
          sheet.timeSinceCreated,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
          ),
        ),

        // Recently updated indicator
        if (sheet.wasRecentlyUpdated) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Updated',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        const Spacer(),

        // Quick actions
        _buildQuickActions(context),
      ],
    );
  }

  /// Build quick action buttons
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Export PDF button
        IconButton(
          onPressed: () => _exportToPdf(context),
          icon: const Icon(
            Icons.picture_as_pdf,
            color: AppColors.error,
            size: 20,
          ),
          tooltip: AppStrings.exportPdf,
          visualDensity: VisualDensity.compact,
        ),

        // Edit button
        IconButton(
          onPressed: onEdit,
          icon: const Icon(
            Icons.edit,
            color: AppColors.primary,
            size: 20,
          ),
          tooltip: AppStrings.editSheet,
          visualDensity: VisualDensity.compact,
        ),

        // Navigate arrow
        const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppColors.textHint,
        ),
      ],
    );
  }

  /// Build actions menu
  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.textSecondary,
      ),
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, color: AppColors.primary),
            title: Text(AppStrings.editSheet),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf, color: AppColors.error),
            title: Text(AppStrings.exportPdf),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: ListTile(
            leading: Icon(Icons.copy, color: AppColors.primary),
            title: Text('Duplicate Sheet'),
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
    );
  }

  /// Handle menu actions
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'export':
        _exportToPdf(context);
        break;
      case 'duplicate':
        _duplicateSheet(context);
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  /// Export sheet to PDF
  void _exportToPdf(BuildContext context) async {
    try {
      final sheetProvider = context.read<SheetProvider>();

      // Show loading
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
              Text('Generating PDF...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final success = await sheetProvider.exportSelectedSheetToPdf(customer);

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
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Duplicate sheet
  void _duplicateSheet(BuildContext context) {
    // TODO: Implement sheet duplication
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicate feature coming soon!')),
    );
  }

  /// Show delete confirmation
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.deleteSheetConfirm),
            const SizedBox(height: 8),
            Text(
              'Sheet: ${sheet.title}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.deleteCannotBeUndone,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSheet(context);
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

  /// Delete sheet
  void _deleteSheet(BuildContext context) async {
    try {
      final success = await context.read<SheetProvider>().deleteSheet(sheet.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sheet "${sheet.title}" deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        onDelete?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete sheet'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// Compact sheet card for list views
class CompactSheetCard extends StatelessWidget {
  final CustomerSheet sheet;
  final VoidCallback? onTap;

  const CompactSheetCard({
    Key? key,
    required this.sheet,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: 4,
      ),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.table_chart,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          sheet.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          sheet.summary,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textHint,
        ),
        onTap: onTap,
      ),
    );
  }
}