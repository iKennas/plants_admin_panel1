import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../utils/constants.dart';

/// Customer card widget optimized for Android phones
/// Displays customer information in a beautiful card format
class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showOptions;

  const CustomerCard({
    Key? key,
    required this.customer,
    this.onTap,
    this.onLongPress,
    this.showOptions = true,
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
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with avatar and customer info
              Row(
                children: [
                  // Customer avatar with initials
                  _buildAvatar(),
                  const SizedBox(width: AppDimensions.paddingMedium),

                  // Customer name and phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer name
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Phone number
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                customer.formattedPhoneNumber,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Options menu (if enabled)
                  if (showOptions) _buildOptionsMenu(context),
                ],
              ),

              // Notes section (if customer has notes)
              if (customer.hasNotes) ...[
                const SizedBox(height: AppDimensions.paddingSmall),
                _buildNotesSection(),
              ],

              // Footer with creation date and status
              const SizedBox(height: AppDimensions.paddingSmall),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build customer avatar with initials
  Widget _buildAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          customer.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Build options menu button
  Widget _buildOptionsMenu(BuildContext context) {
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
            title: Text(AppStrings.editCustomer),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'call',
          child: ListTile(
            leading: Icon(Icons.call, color: AppColors.primary),
            title: Text('Call Customer'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: AppColors.error),
            title: Text(AppStrings.deleteCustomer),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  /// Build notes preview section
  Widget _buildNotesSection() {
    final previewText = customer.notes.length > 100
        ? '${customer.notes.substring(0, 100)}...'
        : customer.notes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            previewText,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build footer with date and status info
  Widget _buildFooter() {
    return Row(
      children: [
        // Creation date
        Icon(
          Icons.access_time,
          size: 14,
          color: AppColors.textHint,
        ),
        const SizedBox(width: 4),
        Text(
          customer.timeSinceCreated,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
          ),
        ),

        const Spacer(),

        // Recently updated indicator
        if (customer.wasRecentlyUpdated) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
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

        // Navigation arrow
        const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: AppColors.textHint,
        ),
      ],
    );
  }

  /// Handle menu actions
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showEditCustomerDialog(context);
        break;
      case 'call':
        _callCustomer(context);
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  /// Show edit customer dialog
  void _showEditCustomerDialog(BuildContext context) {
    // TODO: Implement edit customer dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit customer feature coming soon!')),
    );
  }

  /// Call customer (open phone dialer)
  void _callCustomer(BuildContext context) {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${customer.formattedPhoneNumber}...')),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.deleteCustomerConfirm),
            const SizedBox(height: 8),
            Text(
              'Customer: ${customer.name}',
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
              _deleteCustomer(context);
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

  /// Delete customer
  void _deleteCustomer(BuildContext context) {
    // TODO: Implement delete customer functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleting ${customer.name}...')),
    );
  }
}

/// Optimized customer card for compact list view
class CompactCustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;

  const CompactCustomerCard({
    Key? key,
    required this.customer,
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
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(
            customer.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          customer.formattedPhoneNumber,
          style: const TextStyle(
            color: AppColors.textSecondary,
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