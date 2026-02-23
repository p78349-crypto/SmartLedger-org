part of 'food_expiry_upsert_dialog.dart';
// ignore_for_file: invalid_use_of_protected_member

/// Preferences, save, helper methods for [_FoodExpiryUpsertDialogState].
extension FoodExpiryUpsertLogic on _FoodExpiryUpsertDialogState {
  // ── SharedPreferences helpers ──────────────────────────────────────

  Future<void> _loadLastCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_FoodExpiryUpsertDialogState._kLastCategory)?.trim();
    if (!mounted) return;
    if (last == null || last.isEmpty) return;
    if (!_categories.contains(last)) return;
    setState(() {
      _category = last;
    });
  }

  Future<void> _saveLastCategory(String category) async {
    final next = category.trim();
    if (next.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_FoodExpiryUpsertDialogState._kLastCategory, next);
  }

  Future<void> _loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_FoodExpiryUpsertDialogState._kLastLocation)?.trim();
    if (!mounted) return;
    if (last == null || last.isEmpty) return;
    if (!_locations.contains(last)) return;
    setState(() {
      _location = last;
    });
  }

  Future<void> _saveLastLocation(String location) async {
    final next = location.trim();
    if (next.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_FoodExpiryUpsertDialogState._kLastLocation, next);
  }

  Future<void> _loadLastUnit() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_FoodExpiryUpsertDialogState._kLastUnit)?.trim();
    if (!mounted) return;
    if (last == null || last.isEmpty) return;

    // Only override when the field is still at default / empty.
    final current = _unitController.text.trim();
    if (current.isNotEmpty && current != '개') return;

    setState(() {
      _unitController.text = last;
    });
  }

  Future<void> _saveLastUnit(String unit) async {
    final next = unit.trim();
    if (next.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_FoodExpiryUpsertDialogState._kLastUnit, next);
  }

  // ── Small helpers ─────────────────────────────────────────────────

  String _historySubtitle(ShoppingCartHistoryEntry item) {
    final timeLabel = DateFormat('HH:mm').format(item.at);
    return '${item.quantity}개 / $timeLabel';
  }

  String _expiryButtonLabel(DateTime? suggestedDate) {
    if (_pickedExpiryDate == null) {
      if (suggestedDate == null) return '날짜 선택';
      final predicted = DateFormat('yyyy-MM-dd').format(suggestedDate);
      return '예측: $predicted';
    }

    final manual = DateFormat('yyyy-MM-dd').format(_pickedExpiryDate!);
    return '수동: $manual';
  }

  void _updateTotal() {
    if (widget.existing == null) return;
    final double current = widget.existing!.quantity;
    final double add = double.tryParse(_addQtyController.text) ?? 0;
    final double sub = double.tryParse(_subQtyController.text) ?? 0;
    double result = current + add - sub;
    if (result < 0) result = 0;

    final String text = result == result.toInt()
        ? result.toInt().toString()
        : result.toString();

    if (_quantityController.text != text) {
      _quantityController.text = text;
    }
  }

  // 박스 수량 자동 계산 로직
  void _calculateTotalQuantity() {
    final box = double.tryParse(_boxQtyController.text);
    final pcs = double.tryParse(_pcsPerBoxController.text);

    if (box != null && box > 0 && pcs != null && pcs > 0) {
      final total = box * pcs;
      final text = total == total.toInt()
          ? total.toInt().toString()
          : total.toString();

      if (_quantityController.text != text) {
        _quantityController.text = text;
      }
    }
  }

  // 최근 지출 내역 연동(One-Stop Flow)
  Future<void> _prefillFromLatestTransaction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? account = prefs.getString('lastAccountName');

      if (account == null) {
        final accounts = TransactionService().getAllAccountNames();
        if (accounts.isNotEmpty) account = accounts.first;
      }

      if (account != null) {
        await TransactionByDateUtils.syncFromDatabase(account);
        final groupedData = await TransactionByDateUtils.load(account);

        if (groupedData.isNotEmpty) {
          final sortedDates = groupedData.keys.toList()
            ..sort((a, b) => b.compareTo(a));
          final latestDate = sortedDates.first;
          final txList = groupedData[latestDate];

          if (txList != null && txList.isNotEmpty) {
            final latestTx = txList.first;

            if (!mounted) return;
            setState(() {
              if (_nameController.text.isEmpty) {
                _nameController.text = latestTx['name'] ?? '';
              }
              if (latestTx['amount'] != null) {
                _priceController.text =
                    (latestTx['amount'] as num).toInt().toString();
              }
              if (latestTx['quantity'] != null) {
                _quantityController.text = latestTx['quantity'].toString();
              }
            });
          }
        }
      }
    } catch (e) {
      // Auto-fill error silently ignored
    }
  }

  // ── Save ──────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final effective = _pickedExpiryDate;
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final unit = _unitController.text.trim().isEmpty
        ? '개'
        : _unitController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final supplier = _supplierController.text.trim();

    if (name.isEmpty || effective == null) {
      return;
    }

    if (widget.existing == null) {
      await ConsumableInventoryService.instance.addItem(
        name: name,
        purchaseDate: _purchaseDate,
        expiryDate: effective,
        currentStock: quantity,
        unit: unit,
        category: _category,
        location: _location,
        price: price,
        supplier: supplier,
      );
    } else {
      final updatedItem = ConsumableInventoryItem(
        id: widget.existing!.id,
        name: name,
        currentStock: quantity,
        unit: unit,
        category: _category,
        location: _location,
        createdAt: widget.existing!.createdAt,
        lastUpdated: DateTime.now(),
        expiryDate: effective,
        purchaseDate: _purchaseDate,
        price: price,
        supplier: supplier,
      );
      await ConsumableInventoryService.instance.updateItem(updatedItem);
    }

    if (_importQueue.isEmpty) {
      final message =
          await FeedbackService.getFoodExpirySavedMessageWithTemplate(
            itemName: name,
            expiryDate: effective,
          );
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, message);
    }

    await _saveLastCategory(_category);
    await _saveLastLocation(_location);
    await _saveLastUnit(unit);

    // Handle "Add to shopping list" if checked
    if (_addToShoppingList) {
      final accountName = await UserPrefService.getLastAccountName();
      if (accountName != null) {
        final currentItems = await UserPrefService.getShoppingCartItems(
          accountName: accountName,
        );
        final now = DateTime.now();
        final newItem = ShoppingCartItem(
          id: 'sc_${now.microsecondsSinceEpoch}',
          name: name,
          quantity: quantity.toInt(),
          unitPrice: price,
          createdAt: now,
          updatedAt: now,
        );
        await UserPrefService.setShoppingCartItems(
          accountName: accountName,
          items: [newItem, ...currentItems],
        );
      }
    }

    if (_importQueue.isNotEmpty) {
      _loadNextFromQueue();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }
}
