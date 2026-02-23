library;

import 'package:flutter/material.dart';

/// Empty state widget for inventory list.
/// 
/// Shows when there are no items or search results.
class InventoryEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  
  const InventoryEmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.inventory_2_outlined,
    this.onAction,
    this.actionLabel,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading overlay widget for operations.
class InventoryLoadingOverlay extends StatelessWidget {
  final String message;
  
  const InventoryLoadingOverlay({
    this.message = 'Processing...',
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Low stock warning banner.
class LowStockBanner extends StatelessWidget {
  final int itemCount;
  final VoidCallback onViewTap;
  
  const LowStockBanner({
    required this.itemCount,
    required this.onViewTap,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Stock Alert',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$itemCount item${itemCount > 1 ? 's' : ''} need${itemCount > 1 ? '' : 's'} restocking',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewTap,
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade700,
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

/// Stock level indicator badge.
class StockLevelBadge extends StatelessWidget {
  final double currentStock;
  final double threshold;
  final String unit;
  
  const StockLevelBadge({
    required this.currentStock,
    required this.threshold,
    required this.unit,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final percentage = threshold > 0 
        ? (currentStock / threshold).clamp(0.0, 1.0) 
        : 1.0;
    
    final isLow = currentStock <= threshold;
    final color = isLow ? Colors.orange : Colors.green;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLow ? Icons.arrow_downward : Icons.check_circle,
            size: 16,
            color: color.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            '${(percentage * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: color.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
