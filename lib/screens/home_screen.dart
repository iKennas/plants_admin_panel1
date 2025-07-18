import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../widgets/customer_card.dart';
import '../widgets/add_customer_dialog.dart';
import '../utils/constants.dart';
import 'customer_detail_screen.dart';

/// Main home screen showing list of customers
/// Optimized for Android phones with beautiful UI
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load customers when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          if (customerProvider.isLoading && customerProvider.customers.isEmpty) {
            return _buildLoadingState();
          }

          if (customerProvider.hasError) {
            return _buildErrorState(customerProvider.error!);
          }

          return _buildCustomersList(customerProvider);
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build app bar with search functionality
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(AppStrings.appName),
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: _showSearchDialog,
          icon: const Icon(Icons.search),
          tooltip: 'البحث',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text(AppStrings.refresh),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'sort_name',
              child: ListTile(
                leading: Icon(Icons.sort_by_alpha),
                title: Text('ترتيب بالاسم'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'sort_date',
              child: ListTile(
                leading: Icon(Icons.date_range),
                title: Text('ترتيب بالتاريخ'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
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
            AppStrings.loading,
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
              onPressed: () => context.read<CustomerProvider>().loadCustomers(),
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

  /// Build customers list
  Widget _buildCustomersList(CustomerProvider customerProvider) {
    final customers = customerProvider.searchQuery.isEmpty
        ? customerProvider.customers
        : customerProvider.filteredCustomers;

    if (customers.isEmpty && customerProvider.searchQuery.isEmpty) {
      return _buildEmptyState();
    }

    if (customers.isEmpty && customerProvider.searchQuery.isNotEmpty) {
      return _buildNoSearchResults();
    }

    return Column(
      children: [
        // Search bar (if searching)
        if (customerProvider.searchQuery.isNotEmpty) _buildSearchHeader(customerProvider),

        // Statistics header
        _buildStatisticsHeader(customers.length, customerProvider.customerCount),

        // Customers list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => customerProvider.refreshCustomers(),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return CustomerCard(
                  customer: customer,
                  onTap: () => _navigateToCustomerDetail(customer),
                  onLongPress: () => _showCustomerOptions(customer),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Build empty state when no customers
  Widget _buildEmptyState() {
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
                Icons.people_outline,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            const Text(
              AppStrings.noCustomers,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            const Text(
              AppStrings.addFirstCustomer,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            ElevatedButton.icon(
              onPressed: _showAddCustomerDialog,
              icon: const Icon(Icons.person_add),
              label: const Text(AppStrings.addCustomer),
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

  /// Build no search results state
  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'لم يتم العثور على عملاء يطابقون "${context.read<CustomerProvider>().searchQuery}"',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            OutlinedButton(
              onPressed: () => context.read<CustomerProvider>().clearSearch(),
              child: const Text('مسح البحث'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build search header
  Widget _buildSearchHeader(CustomerProvider customerProvider) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      color: AppColors.primary.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'البحث: "${customerProvider.searchQuery}"',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: customerProvider.clearSearch,
            icon: const Icon(Icons.close, color: AppColors.primary),
            tooltip: 'مسح البحث',
          ),
        ],
      ),
    );
  }

  /// Build statistics header
  Widget _buildStatisticsHeader(int filteredCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      child: Row(
        children: [
          Text(
            context.read<CustomerProvider>().searchQuery.isEmpty
                ? 'إجمالي العملاء: $totalCount'
                : 'النتائج: $filteredCount من أصل $totalCount',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (context.read<CustomerProvider>().isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  /// Build floating action button
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showAddCustomerDialog,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      tooltip: AppStrings.addCustomer,
      child: const Icon(Icons.person_add),
    );
  }

  /// Navigate to customer detail screen
  void _navigateToCustomerDetail(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customer: customer),
      ),
    );
  }

  /// Show add customer dialog
  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddCustomerDialog(),
    );
  }

  /// Show search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('البحث عن العملاء'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'ادخل اسم العميل أو رقم الهاتف',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.of(context).pop();
            context.read<CustomerProvider>().setSearchQuery(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<CustomerProvider>().setSearchQuery(_searchController.text);
            },
            child: const Text('بحث'),
          ),
        ],
      ),
    );
  }

  /// Show customer options (edit/delete)
  void _showCustomerOptions(Customer customer) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text(AppStrings.editCustomer),
              onTap: () {
                Navigator.pop(context);
                _showEditCustomerDialog(customer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text(AppStrings.deleteCustomer),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(customer);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show edit customer dialog
  void _showEditCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AddCustomerDialog(existingCustomer: customer),
    );
  }

  /// Show delete confirmation
  void _showDeleteConfirmation(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: Text('${AppStrings.deleteCustomerConfirm}\n\nالعميل: ${customer.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<CustomerProvider>().deleteCustomer(customer.id);
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

  /// Handle menu actions
  void _handleMenuAction(String action) {
    final customerProvider = context.read<CustomerProvider>();

    switch (action) {
      case 'refresh':
        customerProvider.refreshCustomers();
        break;
      case 'sort_name':
        customerProvider.sortCustomersByName();
        break;
      case 'sort_date':
        customerProvider.sortCustomersByDate();
        break;
    }
  }
}