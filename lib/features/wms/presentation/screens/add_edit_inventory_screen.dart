library;

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/features/wms/presentation/notifiers/inventory_notifier.dart';

/// Screen for adding or editing an inventory item.
///
/// If [item] is provided, it's edit mode. Otherwise, it's add mode.
class AddEditInventoryScreen extends StatefulWidget {
  final ConsumableInventoryItem? item;
  final InventoryNotifier notifier;

  const AddEditInventoryScreen({this.item, required this.notifier, super.key});

  bool get isEditMode => item != null;

  @override
  State<AddEditInventoryScreen> createState() => _AddEditInventoryScreenState();
}

class _AddEditInventoryScreenState extends State<AddEditInventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _stockController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _unitController;
  late final TextEditingController _bundleSizeController;
  late final TextEditingController _priceController;
  late final TextEditingController _supplierController;

  // Selected values
  late String _category;
  late String _location;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _stockController = TextEditingController(
      text: item?.currentStock.toString() ?? '0',
    );
    _thresholdController = TextEditingController(
      text: item?.threshold.toString() ?? '1',
    );
    _unitController = TextEditingController(text: item?.unit ?? 'pcs');
    _bundleSizeController = TextEditingController(
      text: item?.bundleSize.toString() ?? '1',
    );
    _priceController = TextEditingController(
      text: item?.price?.toString() ?? '',
    );
    _supplierController = TextEditingController(text: item?.supplier ?? '');

    _category = item?.category ?? '생활용품';
    _location = item?.location ?? '기타';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _unitController.dispose();
    _bundleSizeController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Item' : 'Add New Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Stock and Unit row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Current Stock *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final num = double.tryParse(value);
                      if (num == null || num < 0) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                      hintText: 'kg, pcs',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Threshold
            TextFormField(
              controller: _thresholdController,
              decoration: const InputDecoration(
                labelText: 'Low Stock Threshold *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning_amber),
                helperText: 'Alert when stock falls below this level',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter threshold';
                }
                final num = double.tryParse(value);
                if (num == null || num < 0) {
                  return 'Please enter valid number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Bundle size
            TextFormField(
              controller: _bundleSizeController,
              decoration: const InputDecoration(
                labelText: 'Bundle Size',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag),
                helperText: 'Default purchase quantity',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),

            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: ['생활용품', '식료품', '위생용품', '청소용품', '기타']
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _category = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Location dropdown
            DropdownButtonFormField<String>(
              value: _location,
              decoration: const InputDecoration(
                labelText: 'Storage Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: ConsumableInventoryItem.locationOptions
                  .map(
                    (location) => DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _location = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '\$',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),

            const SizedBox(height: 16),

            // Supplier
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Supplier (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEditMode ? 'Update Item' : 'Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();

      final newItem = ConsumableInventoryItem(
        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        currentStock: double.parse(_stockController.text),
        unit: _unitController.text.trim(),
        threshold: double.parse(_thresholdController.text),
        bundleSize: double.parse(
          _bundleSizeController.text.isEmpty ? '1' : _bundleSizeController.text,
        ),
        category: _category,
        location: _location,
        price: _priceController.text.isEmpty
            ? null
            : double.tryParse(_priceController.text),
        supplier: _supplierController.text.trim().isEmpty
            ? null
            : _supplierController.text.trim(),
        createdAt: widget.item?.createdAt ?? now,
        lastUpdated: now,
      );

      if (widget.isEditMode) {
        await widget.notifier.updateItem(newItem);
      } else {
        await widget.notifier.addItem(newItem);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? 'Item updated successfully'
                  : 'Item added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
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
