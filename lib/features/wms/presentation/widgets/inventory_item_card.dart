library;

import 'package:flutter/material.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';

/// Card widget for displaying a single inventory item.
/// 
/// Shows item name, current stock, threshold, and low stock indicator.
class InventoryItemCard extends StatelessWidget {
  final ConsumableInventoryItem item;
  final bool isLowStock;
  final VoidCallback? onTap;
  final VoidCallback? onUseStock;
  
  const InventoryItemCard({
    required this.item,
    this.isLowStock = false,
    this.onTap,
    this.onUseStock,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockPercentage = item.threshold > 0 
        ? (item.currentStock / item.threshold).clamp(0.0, 1.0)
        : 1.0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Item name
                  Expanded(
                    child: Text(
                      item.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Low stock badge
                  if (isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Low',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Stock info row
              Row(
                children: [
                  // Stock amount
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Stock',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLowStock 
                                ? Colors.orange.shade700 
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Threshold
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Threshold',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.threshold.toStringAsFixed(1)} ${item.unit}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Stock level indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stockPercentage,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isLowStock ? Colors.orange : Colors.green,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Bottom row: Category and action button
              Row(
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  if (item.location.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      item.location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Use stock button
                  if (onUseStock != null)
                    TextButton.icon(
                      onPressed: onUseStock,
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: const Text('Use'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
