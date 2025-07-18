import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/sheet.dart';
import '../providers/sheet_provider.dart';
import '../widgets/sheet_card.dart';
import '../widgets/add_sheet_dialog.dart';
import '../utils/constants.dart';
import 'sheet_editor_screen.dart';

/// Customer detail screen showing customer info and their sheets
class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load customer sheets when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SheetProvider>().loadCustomerSheets(widget.customer.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Customer info header
          _buildCustomerHeader(),

          // Sheets section
          Expanded(
            child: Consumer<SheetProvider>(
              builder: (context, sheetProvider, child) {
                if (sheetProvider.isLoading && sheetProvider.sheets.isEmpty) {
                  return _buildLoadingState();
                }

                if (sheetProvider.hasError) {
                  return _buildErrorState(sheetProvider.error!);
                }

                return _buildSheetsList(sheetProvider);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.customer.name),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _refreshSheets,
          icon: const Icon(Icons.refresh),
          tooltip: AppStrings.refresh,
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'call',
              child: ListTile(
                leading: Icon(Icons.call),
                title: Text('اتصال'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text(AppStrings.editCustomer),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build customer info header
  Widget _buildCustomerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer avatar and basic info
          Row(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.customer.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppDimensions.paddingMedium),

              // Customer details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      widget.customer.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Phone
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.customer.formattedPhoneNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Created date
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'عميل منذ ${widget.customer.timeSinceCreated}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick actions
              Column(
                children: [
                  IconButton(
                    onPressed: _callCustomer,
                    icon: const Icon(
                      Icons.call,
                      color: AppColors.primary,
                    ),
                    tooltip: 'اتصال',
                  ),
                  IconButton(
                    onPressed: _editCustomer,
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.primary,
                    ),
                    tooltip: AppStrings.editCustomer,
                  ),
                ],
              ),
            ],
          ),

          // Notes section
          if (widget.customer.hasNotes) ...[
            const SizedBox(height: AppDimensions.paddingMedium),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        AppStrings.customerNotes,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.customer.notes,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'جاري تحميل الجداول...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Text(
              AppStrings.error,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            ElevatedButton.icon(
              onPressed: _refreshSheets,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build sheets list
  Widget _buildSheetsList(SheetProvider sheetProvider) {
    final sheets = sheetProvider.sheets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sheets header
        _buildSheetsHeader(sheets.length),

        // Sheets list or empty state
        Expanded(
          child: sheets.isEmpty
              ? _buildEmptySheetsState()
              : _buildSheetsList2(sheets),
        ),
      ],
    );
  }

  /// Build sheets header
  Widget _buildSheetsHeader(int sheetCount) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        children: [
          const Icon(
            Icons.table_chart,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '$sheetCount ${AppStrings.sheets}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (context.read<SheetProvider>().isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  /// Build empty sheets state
  Widget _buildEmptySheetsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.table_chart_outlined,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            const Text(
              AppStrings.noSheets,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            const Text(
              AppStrings.addFirstSheet,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            ElevatedButton.icon(
              onPressed: _showAddSheetDialog,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addSheet),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build actual sheets list
  Widget _buildSheetsList2(List<CustomerSheet> sheets) {
    return RefreshIndicator(
      onRefresh: _refreshSheets,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
        itemCount: sheets.length,
        itemBuilder: (context, index) {
          final sheet = sheets[index];
          return SheetCard(
            sheet: sheet,
            customer: widget.customer,
            onTap: () => _navigateToSheetEditor(sheet),
            onEdit: () => _showEditSheetDialog(sheet),
            onDelete: () => _deleteSheet(sheet),
          );
        },
      ),
    );
  }

  /// Build floating action button
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showAddSheetDialog,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      tooltip: AppStrings.addSheet,
      child: const Icon(Icons.add),
    );
  }

  /// Navigate to sheet editor
  void _navigateToSheetEditor(CustomerSheet sheet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SheetEditorScreen(
          sheet: sheet,
          customer: widget.customer,
        ),
      ),
    );
  }

  /// Show add sheet dialog
  void _showAddSheetDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSheetDialog(customer: widget.customer),
    );
  }

  /// Show edit sheet dialog
  void _showEditSheetDialog(CustomerSheet sheet) {
    showDialog(
      context: context,
      builder: (context) => AddSheetDialog(
        customer: widget.customer,
        existingSheet: sheet,
      ),
    );
  }

  /// Delete sheet
  void _deleteSheet(CustomerSheet sheet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: Text('${AppStrings.deleteSheetConfirm}\n\nالجدول: ${sheet.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SheetProvider>().deleteSheet(sheet.id);
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

  /// Refresh sheets
  Future<void> _refreshSheets() async {
    await context.read<SheetProvider>().loadCustomerSheets(widget.customer.id);
  }

  /// Call customer
  void _callCustomer() {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري الاتصال بـ ${widget.customer.formattedPhoneNumber}...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  /// Edit customer
  void _editCustomer() {
    // TODO: Implement edit customer functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تعديل العميل - قريباً!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'call':
        _callCustomer();
        break;
      case 'edit':
        _editCustomer();
        break;
    }
  }
}