library;

import 'package:flutter/material.dart';
import 'package:smart_ledger/features/wms/presentation/notifiers/inventory_notifier.dart';
import 'package:smart_ledger/features/wms/presentation/state/inventory_state.dart';
import 'package:smart_ledger/features/wms/presentation/widgets/inventory_item_card.dart';

/// Main inventory list screen showing all items.
///
/// Displays inventory items in a list with filtering and sorting options.
class InventoryListScreen extends StatefulWidget {
  final InventoryNotifier notifier;

  const InventoryListScreen({required this.notifier, super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  bool _showLowStockOnly = false;
  String _sortBy = 'name'; // 'name', 'stock', 'category'

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onStateChanged);
    // Load inventory on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.notifier.loadInventory();
    });
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.notifier.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          // Filter button
          IconButton(
            icon: Icon(
              _showLowStockOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: () {
              setState(() {
                _showLowStockOnly = !_showLowStockOnly;
              });
            },
            tooltip: 'Show low stock only',
          ),
          // Sort button
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(
                value: 'stock',
                child: Text('Sort by Stock Level'),
              ),
              const PopupMenuItem(
                value: 'category',
                child: Text('Sort by Category'),
              ),
            ],
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.notifier.refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(state, theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add item screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add item screen - Coming soon')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildBody(InventoryState state, ThemeData theme) {
    return switch (state) {
      InventoryInitial() => const Center(
        child: Text('Press refresh to load inventory'),
      ),

      InventoryLoading() => const Center(child: CircularProgressIndicator()),

      InventoryError(:final message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => widget.notifier.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),

      InventoryLoaded(:final items, :final lowStockItems) => _buildLoadedList(
        items,
        lowStockItems,
        theme,
      ),

      InventoryOperating(:final items) => Stack(
        children: [
          _buildLoadedList(items, [], theme),
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),

      InventoryOperationSuccess(:final items, :final message) =>
        _buildSuccessState(items, message, theme),
    };
  }

  Widget _buildLoadedList(
    List<dynamic> items,
    List<dynamic> lowStockItems,
    ThemeData theme,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No items yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first inventory item',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // Filter items
    var filteredItems = items;
    if (_showLowStockOnly) {
      final lowStockIds = lowStockItems.map((item) => item.id).toSet();
      filteredItems = items
          .where((item) => lowStockIds.contains(item.id))
          .toList();
    }

    // Sort items
    filteredItems = List.from(filteredItems);
    switch (_sortBy) {
      case 'name':
        filteredItems.sort((a, b) => a.name.compareTo(b.name));
      case 'stock':
        filteredItems.sort((a, b) => a.currentStock.compareTo(b.currentStock));
      case 'category':
        filteredItems.sort((a, b) => a.category.compareTo(b.category));
    }

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No items match filter',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.notifier.refresh(),
      child: Column(
        children: [
          // Low stock banner
          if (lowStockItems.isNotEmpty && !_showLowStockOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${lowStockItems.length} item${lowStockItems.length > 1 ? 's' : ''} low on stock',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showLowStockOnly = true;
                      });
                    },
                    child: const Text('View'),
                  ),
                ],
              ),
            ),

          // Items list
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final lowStockIds = lowStockItems.map((i) => i.id).toSet();
                final isLowStock = lowStockIds.contains(item.id);

                return InventoryItemCard(
                  item: item,
                  isLowStock: isLowStock,
                  onTap: () {
                    // TODO: Navigate to detail screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('View details: ${item.name}')),
                    );
                  },
                  onUseStock: () {
                    // TODO: Show use stock dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Use stock: ${item.name}')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(
    List<dynamic> items,
    String message,
    ThemeData theme,
  ) {
    // Show success message and reload
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
      widget.notifier.refresh();
    });

    return _buildLoadedList(items, [], theme);
  }
}
