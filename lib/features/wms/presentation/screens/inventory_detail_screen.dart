library;

import 'package:flutter/material.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/features/wms/presentation/notifiers/inventory_notifier.dart';
import 'package:smart_ledger/features/wms/presentation/widgets/use_stock_dialog.dart';
import 'package:intl/intl.dart';

/// Detail screen for viewing a single inventory item.
///
/// Shows all information about an item with actions to edit, delete, or use stock.
class InventoryDetailScreen extends StatelessWidget {
  final ConsumableInventoryItem item;
  final InventoryNotifier notifier;

  const InventoryDetailScreen({
    required this.item,
    required this.notifier,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isLowStock = item.currentStock <= item.threshold;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _handleEdit(context),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _handleDelete(context),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stock status card
          Card(
            color: isLowStock ? Colors.orange.shade50 : Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (isLowStock)
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Low Stock',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  if (isLowStock) const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Stock',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isLowStock
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Threshold',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.threshold.toStringAsFixed(1)} ${item.unit}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Basic information
          _buildSection(context, 'Basic Information', [
            _buildInfoRow(context, 'Name', item.name),
            _buildInfoRow(context, 'Category', item.category),
            if (item.detailCategory != null)
              _buildInfoRow(context, 'Subcategory', item.detailCategory!),
            _buildInfoRow(context, 'Unit', item.unit),
            _buildInfoRow(context, 'Bundle Size', item.bundleSize.toString()),
          ]),

          const SizedBox(height: 16),

          // Location and supplier
          _buildSection(context, 'Storage & Supply', [
            _buildInfoRow(context, 'Location', item.location),
            if (item.supplier != null)
              _buildInfoRow(context, 'Supplier', item.supplier!),
            if (item.price != null)
              _buildInfoRow(
                context,
                'Price',
                '\$${item.price!.toStringAsFixed(2)}',
              ),
          ]),

          const SizedBox(height: 16),

          // Dates
          _buildSection(context, 'Dates', [
            _buildInfoRow(
              context,
              'Created',
              dateFormat.format(item.createdAt),
            ),
            _buildInfoRow(
              context,
              'Last Updated',
              dateFormat.format(item.lastUpdated),
            ),
            if (item.purchaseDate != null)
              _buildInfoRow(
                context,
                'Purchase Date',
                dateFormat.format(item.purchaseDate!),
              ),
            if (item.expiryDate != null)
              _buildInfoRow(
                context,
                'Expiry Date',
                dateFormat.format(item.expiryDate!),
                highlight: item.expiryDate!.isBefore(DateTime.now()),
              ),
          ]),

          const SizedBox(height: 16),

          // Predicted Depletion

          // Usage history
          if (item.usageHistory.isNotEmpty)
            _buildSection(context, 'Usage History', [
              ...item.usageHistory.take(5).map((record) {
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('${record.amount} ${item.unit}'),
                  subtitle: Text(dateFormat.format(record.timestamp)),
                  dense: true,
                );
              }),
              if (item.usageHistory.length > 5)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '+ ${item.usageHistory.length - 5} more entries',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ]),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _handleUseStock(context),
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('Use Stock'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: highlight ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUseStock(BuildContext context) async {
    final result = await showUseStockDialog(context, item, (
      amount,
      purpose,
    ) async {
      await notifier.useStock(item.id, amount, purpose: purpose);
    });

    if (result == true && context.mounted) {
      Navigator.of(context).pop(); // Go back after using stock
    }
  }

  void _handleEdit(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit screen - Coming soon')));
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await notifier.deleteItem(item.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // Go back after deletion
      }
    }
  }
}
