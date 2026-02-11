// ignore_for_file: invalid_use_of_protected_member
part of 'quick_stock_use_screen.dart';

/// Extension: name search, item selection, history, formatting.
extension QuickStockSearch on _QuickStockUseBodyState {
  String _formatQty(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) return rounded.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  void _onAmountChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onNameChanged() {
    final query = _nameController.text;
    setState(() {
      _suggestions = QuickStockUseUtils.searchItems(query);
      _selectedItem = QuickStockUseUtils.findExactItem(query);
      _historySuggestions = _selectedItem == null
          ? _searchHistoryNames(query, names: _shoppingHistoryNames)
          : [];
    });
  }

  List<String> _searchHistoryNames(
    String query, {
    required List<String> names,
  }) {
    final q = query.trim();
    if (q.isEmpty || names.isEmpty) return const [];

    final lowerQuery = q.toLowerCase();
    final chosungQuery = QuickStockUseUtils.extractChosung(lowerQuery);

    final scored = <_ScoredName>[];
    for (final name in names) {
      final lowerName = name.toLowerCase();
      final chosungName = QuickStockUseUtils.extractChosung(name);
      int score = 0;

      if (lowerName == lowerQuery) {
        score = 100;
      } else if (lowerName.startsWith(lowerQuery)) {
        score = 80;
      } else if (lowerName.contains(lowerQuery)) {
        score = 60;
      } else if (chosungName.startsWith(chosungQuery)) {
        score = 50;
      } else if (chosungName.contains(chosungQuery)) {
        score = 40;
      }

      if (score > 0) {
        scored.add(_ScoredName(name: name, score: score));
      }
    }

    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.name.compareTo(b.name);
    });

    return scored.map((s) => s.name).take(20).toList(growable: false);
  }

  Future<void> _loadShoppingHistoryNames() async {
    try {
      final entries = await UserPrefService.getShoppingCartHistory(
        accountName: widget.accountName,
      );
      final seen = <String>{};
      final names = <String>[];
      for (final e in entries) {
        final n = e.name.trim();
        if (n.isEmpty) continue;
        final key = n.toLowerCase();
        if (seen.contains(key)) continue;
        seen.add(key);
        names.add(n);
      }

      if (!mounted) return;
      setState(() {
        _shoppingHistoryNames = names;
        _historySuggestions = _selectedItem == null
            ? _searchHistoryNames(_nameController.text, names: names)
            : [];
      });
    } catch (_) {
      // Best-effort: history suggestions are optional.
    }
  }

  Future<void> _createAndSelectByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final existing = QuickStockUseUtils.findExactItem(trimmed);
    if (existing != null) {
      _selectItem(existing);
      return;
    }

    final input = WmsInventoryInput.quick(name: trimmed);
    final result = await WmsInventoryGateway.instance.addItem(
      input: input,
      source: WmsInputSource.quickUse,
    );

    if (result.success && result.data != null) {
      _selectItem(result.data!);
      return;
    } else if (result.type == WmsOperationType.duplicate &&
        result.data != null) {
      _selectItem(result.data!);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('상품 등록에 실패했습니다')),
    );
  }

  void _selectItem(ConsumableInventoryItem item) {
    setState(() {
      _nameController.text = item.name;
      _selectedItem = item;
      _suggestions = [];
    });
  }

  /// 상품명으로 단위/중량/가격 정보 조회
  _ProductUnitInfo? _getProductUnit(String productName) {
    if (productName.isEmpty) return null;
    final lowerName = productName.toLowerCase();
    for (final entry in _productUnitMap.entries) {
      if (lowerName.contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(lowerName)) {
        return entry.value;
      }
    }
    return null;
  }
}
