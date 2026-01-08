import 'package:flutter/material.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/services/consumable_inventory_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/quick_stock_use_utils.dart';

/// 식료품/생활용품 사용기록 화면
///
/// 상품명 입력 → 사용량 입력 → 자동 차감
class QuickStockUseScreen extends StatefulWidget {
  final String accountName;
  final String? initialProductName;

  const QuickStockUseScreen({
    super.key,
    required this.accountName,
    this.initialProductName,
  });

  @override
  State<QuickStockUseScreen> createState() => _QuickStockUseScreenState();
}

class _QuickStockUseScreenState extends State<QuickStockUseScreen> {
  @override
  void initState() {
    super.initState();
    ConsumableInventoryService.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('빠른 재고 차감'),
      ),
      body: _QuickStockUseBody(
        accountName: widget.accountName,
        initialProductName: widget.initialProductName,
      ),
    );
  }
}

class _QuickStockUseBody extends StatefulWidget {
  final String accountName;
  final String? initialProductName;

  const _QuickStockUseBody({
    required this.accountName,
    this.initialProductName,
  });

  @override
  State<_QuickStockUseBody> createState() => _QuickStockUseBodyState();
}

class _QuickStockUseBodyState extends State<_QuickStockUseBody> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '1');

  ConsumableInventoryItem? _selectedItem;
  List<ConsumableInventoryItem> _suggestions = [];
  List<String> _shoppingHistoryNames = [];
  List<String> _historySuggestions = [];
  List<_RecentUse> _recentUses = [];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _amountController.addListener(_onAmountChanged);
    _loadShoppingHistoryNames();
    
    // 초기 상품명 설정 (생활용품 화면에서 전달된 경우)
    if (widget.initialProductName != null && widget.initialProductName!.isNotEmpty) {
      _nameController.text = widget.initialProductName!;
      _onNameChanged();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatQty(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) return rounded.toStringAsFixed(0);
    // Keep one decimal for fractional unit usage (e.g., 1.5롤/일).
    return value.toStringAsFixed(1);
  }

  void _onAmountChanged() {
    // Live preview: update the UI as the user types.
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

  List<String> _searchHistoryNames(String query, {required List<String> names}) {
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

    await ConsumableInventoryService.instance.addItem(
      name: trimmed,
    );

    final created = QuickStockUseUtils.findExactItem(trimmed);
    if (created != null) {
      _selectItem(created);
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

  // 현재 재고량 기반 동적 빠른 선택 버튼 생성
  List<Widget> _buildQuickButtons() {
    if (_selectedItem == null) {
      const defaults = [1, 2, 5, 10];
      return [
        for (final value in defaults)
          _QuickButton(
            label: value.toString(),
            onTap: () => _amountController.text = value.toString(),
          )
      ];
    }

    final currentStock = _selectedItem!.currentStock;
    final List<double> buttonValues = [];

    // 재고의 25%, 50%, 75%, 100% 계산
    if (currentStock > 0) {
      final step25 = (currentStock / 4).floorToDouble();
      final step50 = (currentStock / 2).floorToDouble();
      final step75 = ((currentStock * 3) / 4).floorToDouble();

      if (step25 > 0) buttonValues.add(step25);
      if (step50 > 0 && step50 != step25) buttonValues.add(step50);
      if (step75 > 0 && step75 != step50) buttonValues.add(step75);
      buttonValues.add(currentStock); // 100%
    }

    // 중복 제거 및 정렬
    final uniqueValues = buttonValues.toSet().toList()..sort();

    return [
      for (final value in uniqueValues)
        _QuickButton(
          label: _formatQty(value),
          onTap: () => _amountController.text = _formatQty(value),
          isHighRisk: value >= (currentStock * 0.6), // 60% 이상 사용
        ),
      if (_selectedItem != null && _selectedItem!.bundleSize > 1)
        _QuickButton(
          label: '묶음',
          onTap: () => _amountController.text =
              _selectedItem!.bundleSize.toStringAsFixed(0),
        ),
    ];
  }

  Widget _buildPrimaryActionRow() {
    final hasItem = _selectedItem != null;
    final stockText = hasItem
        ? '${_formatQty(_selectedItem!.currentStock)}${_selectedItem!.unit}'
        : '상품 선택';
    final pillRadius = BorderRadius.circular(8);
    const pillPadding = EdgeInsets.symmetric(vertical: 12, horizontal: 16);

    Widget buildPill({
      required Widget child,
      VoidCallback? onTap,
      EdgeInsetsGeometry? padding,
      bool isPrimary = false,
    }) {
      final enabled = onTap != null;
      final colorScheme = Theme.of(context).colorScheme;
      return InkWell(
        onTap: onTap,
        borderRadius: pillRadius,
        child: Container(
          padding: padding ?? pillPadding,
          decoration: BoxDecoration(
            color: isPrimary && enabled
                ? colorScheme.primary
                : (enabled ? colorScheme.surface : colorScheme.surfaceContainerHighest),
            border: Border.all(width: 1.3, color: isPrimary && enabled ? colorScheme.primary : colorScheme.outline),
            borderRadius: pillRadius,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
            child: buildPill(
              onTap: hasItem ? () => _showStockInfo(stockText) : null,
              padding: pillPadding,
              child: Builder(
                builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '현재고량 ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: stockText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: hasItem ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextSpan(
                          text: '  ⊖ ENT',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
            child: buildPill(
              onTap: hasItem ? _submit : null,
              padding: pillPadding,
              isPrimary: true,
              child: Builder(
                builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Center(
                    child: Text(
                      'ENT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: hasItem ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
        ),
      ],
    );
  }

  void _showStockInfo(String stockText) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('현재 재고: $stockText'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품을 선택해주세요')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용량을 입력해주세요')),
      );
      return;
    }

    // 재고 초과 체크
    if (amount > _selectedItem!.currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '재고 부족! 현재: ${_formatQty(_selectedItem!.currentStock)}${_selectedItem!.unit}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 개선된 차감 로직 (부족분 장바구니 자동 추가)
    final result = await QuickStockUseUtils.useStockWithShortage(
      itemId: _selectedItem!.id,
      amount: amount,
      accountName: widget.accountName,
    );

    if (mounted) {
      if (result.success) {
        // 최근 사용 기록 추가
        setState(() {
          _recentUses.insert(
            0,
            _RecentUse(
              name: _selectedItem!.name,
              amount: result.actualUsed,
              unit: _selectedItem!.unit,
              remaining: result.remaining,
              time: DateTime.now(),
              shortage: result.shortage,
              addedToCart: result.addedToCart,
            ),
          );
          if (_recentUses.length > 5) {
            _recentUses = _recentUses.take(5).toList();
          }
        });

        // 결과 메시지 생성
        String message;
        Color bgColor;

        if (result.addedToCart) {
          // 부족분이 장바구니에 추가됨
          message = '⚠️ ${_selectedItem!.name} '
              '${_formatQty(result.actualUsed)}${_selectedItem!.unit} 차감\n'
              '부족분 ${_formatQty(result.shortage)}${_selectedItem!.unit} → 장바구니 추가됨';
          bgColor = Colors.orange;
        } else if (result.remaining == 0) {
          // 재고 소진
          message = '✅ ${_selectedItem!.name} '
              '${_formatQty(result.actualUsed)}${_selectedItem!.unit} 차감 완료\n'
              '⚠️ 재고가 모두 소진되었습니다!';
          bgColor = Colors.orange.shade700;
        } else {
          // 정상 차감
          message = '✅ ${_selectedItem!.name} '
              '${_formatQty(result.actualUsed)}${_selectedItem!.unit} 차감 완료\n'
              '남은 재고: ${_formatQty(result.remaining)}${_selectedItem!.unit}'
              '${result.addedToCartByPrediction ? '\n예상 소진 임박 → 장바구니 추가됨' : ''}';
          bgColor = Colors.green;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: bgColor,
            duration: const Duration(seconds: 3),
          ),
        );

        // 입력 초기화
        _nameController.clear();
        _amountController.text = '1';
        _selectedItem = null;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('차감 실패: ${result.error ?? "알 수 없는 오류"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ConsumableInventoryService.instance.items.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 안내 카드
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '상품명 입력 → 사용량 입력 → ENT',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 상품명 입력
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '상품명',
              hintText: '휴지, 세제, 샴푸 등',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              suffixIcon: _selectedItem != null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          ),

          // 자동완성 목록
          if ((_suggestions.isNotEmpty || _historySuggestions.isNotEmpty) &&
              _selectedItem == null)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final item in _suggestions) ...[
                    Builder(
                      builder: (context) {
                        final isLow = item.currentStock <= item.threshold;
                        final isEmpty = item.currentStock == 0;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isEmpty
                                ? Colors.red
                                : isLow
                                    ? Colors.orange
                                    : Colors.grey,
                            child: isEmpty
                                ? const Icon(
                                    Icons.warning,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : Text(item.name[0]),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(item.name)),
                              if (isEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '재고 없음',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '재고: ${_formatQty(item.currentStock)}${item.unit} | 📍${item.location}',
                            style: TextStyle(
                              color: isEmpty
                                  ? Colors.red
                                  : isLow
                                      ? Colors.orange
                                      : null,
                            ),
                          ),
                          onTap: () => _selectItem(item),
                        );
                      },
                    ),
                  ],
                  if (_suggestions.isEmpty && _historySuggestions.isNotEmpty)
                    const Divider(height: 1),
                  for (final name in _historySuggestions) ...[
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.history, size: 18),
                      ),
                      title: Text(name),
                      subtitle: const Text('쇼핑 기록에서 찾음 (탭하면 등록 후 선택)'),
                      onTap: () => _createAndSelectByName(name),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 16),

          // 사용량 입력 + 빠른 선택
          Builder(
            builder: (context) {
              final quickButtons = _buildQuickButtons();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: '사용량',
                        border: const OutlineInputBorder(),
                        suffixText: _selectedItem?.unit ?? '개',
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 108,
                    child: Column(
                      children: [
                        const Text(
                          '빠른 선택',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            runSpacing: 4,
                            children: quickButtons,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          _buildPrimaryActionRow(),

          if (_selectedItem != null) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final item = _selectedItem!;
                final amount = double.tryParse(_amountController.text) ?? 0;
                final used = amount < 0 ? 0 : amount;
                final remaining = item.currentStock - used;
                final remainingClamped = remaining < 0 ? 0.0 : remaining;
                final shortage = used - item.currentStock;
                final shortageClamped = shortage < 0 ? 0.0 : shortage;

                String relativeLastUpdated() {
                  final now = DateTime.now();
                  var diff = now.difference(item.lastUpdated);
                  if (diff.isNegative) diff = Duration.zero;
                  if (diff.inMinutes < 1) return '방금 전';
                  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
                  if (diff.inDays < 1) return '${diff.inHours}시간 전';
                  return '${diff.inDays}일 전';
                }

                DateTime startOfDay(DateTime dt) =>
                    DateTime(dt.year, dt.month, dt.day);

                String formatDate(DateTime dt) {
                  final y = dt.year.toString().padLeft(4, '0');
                  final m = dt.month.toString().padLeft(2, '0');
                  final d = dt.day.toString().padLeft(2, '0');
                  return '$y-$m-$d';
                }

                // Usage-based expected depletion (for non-expiry items)
                int? expectedDaysLeft;
                int? avgIntervalDays;
                DateTime? expectedDepletionDate;

                if (item.expiryDate == null && item.usageHistory.length >= 2) {
                  final sorted = [...item.usageHistory]
                    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                  final first = sorted.first.timestamp;
                  final last = sorted.last.timestamp;
                  final spanDays = startOfDay(last)
                      .difference(startOfDay(first))
                      .inDays
                      .abs();
                  final denomDays = spanDays < 1 ? 1 : spanDays;
                  final totalUsed =
                      sorted.fold<double>(0.0, (sum, r) => sum + r.amount);
                  final avgPerDay = totalUsed / denomDays;

                  if (avgPerDay > 0 && item.currentStock > 0) {
                    expectedDaysLeft = (item.currentStock / avgPerDay).ceil();
                    expectedDepletionDate =
                    startOfDay(DateTime.now()).add(Duration(days: expectedDaysLeft));
                  }

                  final intervals = <int>[];
                  for (var i = 1; i < sorted.length; i++) {
                    final delta = startOfDay(sorted[i].timestamp)
                        .difference(startOfDay(sorted[i - 1].timestamp))
                        .inDays;
                    if (delta > 0) intervals.add(delta);
                  }
                  if (intervals.isNotEmpty) {
                    final avg =
                        intervals.reduce((a, b) => a + b) / intervals.length;
                    avgIntervalDays = avg.round();
                  }
                }

                String? secondaryLine;
                Color? secondaryColor;

                final expiry = item.expiryDate;
                if (expiry != null) {
                  final dDayValue = startOfDay(expiry)
                    .difference(startOfDay(DateTime.now()))
                    .inDays;

                  secondaryLine = '유통기한: ${formatDate(expiry)}'
                    '${dDayValue < 0 ? ' (경과 ${-dDayValue}일)' : ' (D-$dDayValue)'}';
                  secondaryColor = dDayValue < 0
                    ? Colors.red
                    : (dDayValue <= 2
                      ? Colors.orange
                      : Theme.of(context).colorScheme.onSurfaceVariant);
                } else if (expectedDaysLeft != null && expectedDepletionDate != null) {
                  final expectedLeft = expectedDaysLeft;
                  final expectedDate = expectedDepletionDate;
                  secondaryLine = '예상 소진: $expectedLeft일 뒤 (${formatDate(expectedDate)})'
                    '${avgIntervalDays == null ? '' : ' (평균 $avgIntervalDays일 사용)'}';
                  secondaryColor = expectedLeft <= 2
                    ? Colors.orange
                    : Theme.of(context).colorScheme.onSurfaceVariant;
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  final value = item.currentStock;
                                  final label = _formatQty(value);
                                  _amountController.text = label;
                                  FocusScope.of(context).unfocus();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    '현재 ${_formatQty(item.currentStock)}${item.unit} 남음',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            if (item.currentStock > 0)
                              TextButton(
                                onPressed: () {
                                  _amountController.text =
                                      _formatQty(item.currentStock);
                                  FocusScope.of(context).unfocus();
                                },
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('전량'),
                              ),
                            Text(
                              '최근 차감: ${relativeLastUpdated()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        if (secondaryLine != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            secondaryLine,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: secondaryColor),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '차감 후 예상 남은 재고: '
                                '${_formatQty(remainingClamped)}${item.unit}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (shortageClamped > 0)
                              Text(
                                '부족 ${_formatQty(shortageClamped)}${item.unit}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.orange),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          // 최근 사용 기록
          if (_recentUses.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              '최근 차감 기록',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...(_recentUses.map((r) {
              final hasShortage = r.shortage > 0;
              final isEmpty = r.remaining == 0;

              return Card(
                color: hasShortage
                    ? Colors.orange.shade50
                    : isEmpty
                        ? Colors.red.shade50
                        : null,
                child: ListTile(
                  leading: Icon(
                    hasShortage
                        ? Icons.shopping_cart
                        : isEmpty
                            ? Icons.warning
                            : Icons.check_circle,
                    color: hasShortage
                        ? Colors.orange
                        : isEmpty
                            ? Colors.red
                            : Colors.green,
                  ),
                  title: Text('${r.name} -${r.amount.toStringAsFixed(0)}${r.unit}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEmpty
                            ? '⚠️ 재고 없음!'
                            : '남은 재고: ${r.remaining.toStringAsFixed(0)}${r.unit}',
                        style: TextStyle(
                          color: isEmpty ? Colors.red : null,
                          fontWeight: isEmpty ? FontWeight.bold : null,
                        ),
                      ),
                      if (hasShortage)
                        Text(
                          '🛒 부족분 ${r.shortage.toStringAsFixed(0)}${r.unit} 장바구니 추가됨',
                          style: const TextStyle(color: Colors.orange),
                        ),
                    ],
                  ),
                  trailing: Text(
                    '${r.time.hour}:${r.time.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  isThreeLine: hasShortage,
                ),
              );
            })),
          ],

          // 등록된 재고가 없을 때
          if (items.isEmpty) ...[
            const SizedBox(height: 32),
            Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 32, color: Colors.orange),
                    SizedBox(height: 8),
                    Text(
                      '등록된 재고가 없습니다.\n먼저 소모품 재고 화면에서 상품을 등록해주세요.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isHighRisk;

  const _QuickButton({
    required this.label,
    required this.onTap,
    this.isHighRisk = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseBorderColor = Colors.grey.shade600;
    final borderRadius = BorderRadius.circular(12);
    final textColor = isHighRisk ? Colors.red.shade700 : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
        child: Container(
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38, maxWidth: 38, maxHeight: 38),
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: isHighRisk ? Colors.red.shade50 : Colors.white,
          border: Border.all(
            color: isHighRisk ? Colors.red.shade600 : baseBorderColor,
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentUse {
  final String name;
  final double amount;
  final String unit;
  final double remaining;
  final DateTime time;
  final double shortage;
  final bool addedToCart;

  _RecentUse({
    required this.name,
    required this.amount,
    required this.unit,
    required this.remaining,
    required this.time,
    this.shortage = 0,
    this.addedToCart = false,
  });
}

class _ScoredName {
  final String name;
  final int score;

  const _ScoredName({
    required this.name,
    required this.score,
  });
}
