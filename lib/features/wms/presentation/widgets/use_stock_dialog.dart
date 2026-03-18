library;

import 'package:flutter/material.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';

/// Dialog for using stock from an inventory item.
///
/// Allows user to specify amount and optional purpose.
class UseStockDialog extends StatefulWidget {
  final ConsumableInventoryItem item;
  final Future<void> Function(double amount, String? purpose) onUseStock;

  const UseStockDialog({
    required this.item,
    required this.onUseStock,
    super.key,
  });

  @override
  State<UseStockDialog> createState() => _UseStockDialogState();
}

class _UseStockDialogState extends State<UseStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Use Stock: ${widget.item.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current stock info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Stock',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    '${widget.item.currentStock.toStringAsFixed(1)} ${widget.item.unit}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Amount input
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount to use',
                suffixText: widget.item.unit,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.remove_circle_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }

                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid number';
                }

                if (amount <= 0) {
                  return 'Amount must be greater than 0';
                }

                if (amount > widget.item.currentStock) {
                  return 'Insufficient stock (available: ${widget.item.currentStock})';
                }

                return null;
              },
              autofocus: true,
            ),

            const SizedBox(height: 16),

            // Purpose input (optional)
            TextFormField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_outlined),
                hintText: 'e.g., Cooking, Cleaning',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleUseStock,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Use Stock'),
        ),
      ],
    );
  }

  Future<void> _handleUseStock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final purpose = _purposeController.text.trim().isEmpty
          ? null
          : _purposeController.text.trim();

      await widget.onUseStock(amount, purpose);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// Show the use stock dialog
Future<bool?> showUseStockDialog(
  BuildContext context,
  ConsumableInventoryItem item,
  Future<void> Function(double amount, String? purpose) onUseStock,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => UseStockDialog(item: item, onUseStock: onUseStock),
  );
}
