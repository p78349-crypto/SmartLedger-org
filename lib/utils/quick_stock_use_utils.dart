import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../models/shopping_cart_item.dart';
import '../repositories/app_repositories.dart';
import '../services/consumable_inventory_service.dart';
import '../services/activity_household_estimator_service.dart';
import '../services/user_pref_service.dart';

/// 식료품/생활용품 사용기록 유틸리티
///
/// 상품명 입력 후 사용량 입력하면 자동 차감되는 기능 제공
class QuickStockUseUtils {
  const QuickStockUseUtils._();

  static DateTime _startOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static String _formatQty(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) return rounded.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  static double? _resolveQuantityFactorFromTrend(
    ActivityHouseholdTrendComparison? trend,
  ) {
    if (trend == null) return null;
    final r = trend.ratio;
    if (!r.isFinite || r <= 0) return null;
    if (r >= 0.9 && r <= 1.1) return null;
    return r.clamp(0.7, 1.5);
  }

  static int _applyFactorToIntQuantity(int baseQty, double? factor) {
    final b = baseQty <= 0 ? 1 : baseQty;
    if (factor == null) return b;
    final next = (b * factor).round();
    return next < 1 ? 1 : next;
  }

  /// Returns expected depletion days from today based on usage history.
  /// Requires enough usage history.
  static int? _calculateExpectedDepletionDays(ConsumableInventoryItem item) {
    if (item.currentStock <= 0) return null;
    if (item.usageHistory.length < 2) return null;

    final sorted = [...item.usageHistory]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final first = sorted.first.timestamp;
    final last = sorted.last.timestamp;
    final spanDays = _startOfDay(
      last,
    ).difference(_startOfDay(first)).inDays.abs();
    final denomDays = spanDays < 1 ? 1 : spanDays;
    final totalUsed = sorted.fold<double>(0.0, (sum, r) => sum + r.amount);
    final avgPerDay = totalUsed / denomDays;
    if (avgPerDay <= 0) return null;

    return (item.currentStock / avgPerDay).ceil();
  }

  // ============================================================
  // 한글 초성 테이블
  // ============================================================
  static const List<String> _chosung = [
    'ㄱ',
    'ㄲ',
    'ㄴ',
    'ㄷ',
    'ㄸ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅃ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅉ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ',
  ];

  /// 한글 문자의 초성 추출
  static String _getChosung(String char) {
    final code = char.codeUnitAt(0);
    // 한글 유니코드 범위: 가(0xAC00) ~ 힣(0xD7A3)
    if (code >= 0xAC00 && code <= 0xD7A3) {
      final index = ((code - 0xAC00) / 588).floor();
      return _chosung[index];
    }
    return char; // 한글이 아니면 그대로 반환
  }

  /// 문자열의 초성 추출
  static String extractChosung(String text) {
    return text.split('').map(_getChosung).join();
  }

  /// 상품명으로 재고 아이템 검색 (부분 일치 + 초성 검색)
  static List<ConsumableInventoryItem> searchItems(String query) {
    if (query.trim().isEmpty) return [];

    final items = ConsumableInventoryService.instance.items.value;
    final lowerQuery = query.toLowerCase().trim();
    final chosungQuery = extractChosung(lowerQuery);

    // 검색 결과를 점수 기반으로 정렬
    final scored = <_ScoredItem>[];

    for (final item in items) {
      final lowerName = item.name.toLowerCase();
      final chosungName = extractChosung(item.name);
      int score = 0;

      // 1. 정확히 일치 (최고 점수)
      if (lowerName == lowerQuery) {
        score = 100;
      }
      // 2. 시작 부분 일치
      else if (lowerName.startsWith(lowerQuery)) {
        score = 80;
      }
      // 3. 부분 일치
      else if (lowerName.contains(lowerQuery)) {
        score = 60;
      }
      // 4. 초성 일치 (시작)
      else if (chosungName.startsWith(chosungQuery)) {
        score = 50;
      }
      // 5. 초성 부분 일치
      else if (chosungName.contains(chosungQuery)) {
        score = 40;
      }

      if (score > 0) {
        scored.add(_ScoredItem(item: item, score: score));
      }
    }

    // 점수 높은 순, 같으면 이름순 정렬
    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.item.name.compareTo(b.item.name);
    });

    return scored.map((s) => s.item).toList();
  }

  /// 정확한 이름으로 아이템 찾기
  static ConsumableInventoryItem? findExactItem(String name) {
    final items = ConsumableInventoryService.instance.items.value;
    final lowerName = name.toLowerCase().trim();

    try {
      return items.firstWhere((item) => item.name.toLowerCase() == lowerName);
    } catch (_) {
      return null;
    }
  }

  /// 재고 차감 (부족분은 장바구니에 자동 추가)
  static Future<StockUseResult> useStockWithShortage({
    required String itemId,
    required double amount,
    required String accountName,
  }) async {
    try {
      final items = ConsumableInventoryService.instance.items.value;
      final item = items.firstWhere((e) => e.id == itemId);
      final currentStock = item.currentStock;

      double actualUsed = amount;
      double shortage = 0;

      if (amount > currentStock) {
        // 부족분 계산
        shortage = amount - currentStock;
        actualUsed = currentStock;

        // 장바구니에 자동 추가
        await _addToShoppingCart(
          accountName: accountName,
          itemName: item.name,
          shortage: shortage,
          unit: item.unit,
        );
      }

      // 실제 차감
      if (actualUsed > 0) {
        await ConsumableInventoryService.instance.useItem(itemId, actualUsed);
      }

      // Refresh item after use (usageHistory + currentStock updated)
      final updated = ConsumableInventoryService.instance.items.value
          .firstWhere((e) => e.id == itemId, orElse: () => item);

      // Activity-based shopping adjustment factor (short vs baseline).
      final trend = await ActivityHouseholdEstimatorService.compareTrend();
      final qtyFactor = _resolveQuantityFactorFromTrend(trend);

      // Auto add to shopping prep when expected depletion is imminent
      final autoAddDaysThreshold = updated.expiryDate != null
          ? await UserPrefService.getStockUseAutoAddDepletionDaysFoodV1()
          : await UserPrefService.getStockUseAutoAddDepletionDaysHouseholdV1();
      final expectedDaysLeft = _calculateExpectedDepletionDays(updated);
      var addedToCartByPrediction = false;
      if (expectedDaysLeft != null &&
          expectedDaysLeft <= autoAddDaysThreshold) {
        addedToCartByPrediction = await _addToShoppingCartWithMemo(
          accountName: accountName,
          itemName: updated.name,
          memo: '예상 소진 임박 ($expectedDaysLeft일 내 소진 예상)',
          quantity: _applyFactorToIntQuantity(1, qtyFactor),
        );
      }

      // 차감 후 남은 재고
      final remaining = (currentStock - actualUsed).clamp(0.0, double.infinity);

      return StockUseResult(
        success: true,
        actualUsed: actualUsed,
        shortage: shortage,
        remaining: remaining,
        addedToCart: shortage > 0,
        addedToCartByPrediction: addedToCartByPrediction,
        expectedDepletionDays: expectedDaysLeft,
      );
    } catch (e) {
      return StockUseResult(
        success: false,
        actualUsed: 0,
        shortage: 0,
        remaining: 0,
        addedToCart: false,
        addedToCartByPrediction: false,
        expectedDepletionDays: null,
        error: e.toString(),
      );
    }
  }

  /// 장바구니에 부족분 추가
  static Future<void> _addToShoppingCart({
    required String accountName,
    required String itemName,
    required double shortage,
    required String unit,
    int quantity = 1,
  }) async {
    final current = await AppRepositories.shoppingCart.getItems(
      accountName: accountName,
    );

    // 이미 장바구니에 있으면 메모만 업데이트
    final existingIndex = current.indexWhere((i) => i.name == itemName);
    if (existingIndex >= 0) {
      return; // 이미 있으면 추가하지 않음
    }

    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'cart_${now.microsecondsSinceEpoch}',
      name: itemName,
      quantity: quantity <= 0 ? 1 : quantity,
      memo: '재고 부족 (${_formatQty(shortage)}$unit 필요)',
      createdAt: now,
      updatedAt: now,
    );

    final next = List<ShoppingCartItem>.from(current)..add(newItem);
    await AppRepositories.shoppingCart.setItems(
      accountName: accountName,
      items: next,
    );
  }

  static Future<bool> _addToShoppingCartWithMemo({
    required String accountName,
    required String itemName,
    required String memo,
    int quantity = 1,
  }) async {
    final current = await AppRepositories.shoppingCart.getItems(
      accountName: accountName,
    );

    final existingIndex = current.indexWhere((i) => i.name == itemName);
    if (existingIndex >= 0) return false;

    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'cart_${now.microsecondsSinceEpoch}',
      name: itemName,
      quantity: quantity <= 0 ? 1 : quantity,
      memo: memo,
      createdAt: now,
      updatedAt: now,
    );

    final next = List<ShoppingCartItem>.from(current)..add(newItem);
    await AppRepositories.shoppingCart.setItems(
      accountName: accountName,
      items: next,
    );
    return true;
  }

  /// 재고 차감 (기본 - 호환성 유지)
  static Future<bool> useStock({
    required String itemId,
    required double amount,
  }) async {
    try {
      await ConsumableInventoryService.instance.useItem(itemId, amount);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 빠른 차감 다이얼로그 표시
  static Future<void> showQuickUseDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _QuickStockUseSheet(),
    );
  }
}

/// 재고 차감 결과
class StockUseResult {
  final bool success;
  final double actualUsed;
  final double shortage;
  final double remaining;
  final bool addedToCart;
  final bool addedToCartByPrediction;
  final int? expectedDepletionDays;
  final String? error;

  const StockUseResult({
    required this.success,
    required this.actualUsed,
    required this.shortage,
    required this.remaining,
    required this.addedToCart,
    required this.addedToCartByPrediction,
    required this.expectedDepletionDays,
    this.error,
  });
}

/// 검색 점수 계산용 내부 클래스
class _ScoredItem {
  final ConsumableInventoryItem item;
  final int score;

  _ScoredItem({required this.item, required this.score});
}

class _QuickStockUseSheet extends StatefulWidget {
  const _QuickStockUseSheet();

  @override
  State<_QuickStockUseSheet> createState() => _QuickStockUseSheetState();
}

class _QuickStockUseSheetState extends State<_QuickStockUseSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '1');
  final _nameFocus = FocusNode();

  ConsumableInventoryItem? _selectedItem;
  List<ConsumableInventoryItem> _suggestions = [];

  @override
  void initState() {
    super.initState();
    ConsumableInventoryService.instance.load();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final query = _nameController.text;
    setState(() {
      _suggestions = QuickStockUseUtils.searchItems(query);
      // 정확히 일치하는 아이템 자동 선택
      _selectedItem = QuickStockUseUtils.findExactItem(query);
    });
  }

  void _selectItem(ConsumableInventoryItem item) {
    setState(() {
      _nameController.text = item.name;
      _selectedItem = item;
      _suggestions = [];
    });
  }

  Future<void> _submit() async {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상품을 선택해주세요')));
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사용량을 입력해주세요')));
      return;
    }

    final success = await QuickStockUseUtils.useStock(
      itemId: _selectedItem!.id,
      amount: amount,
    );

    if (mounted) {
      if (success) {
        final remaining = (_selectedItem!.currentStock - amount).clamp(
          0.0,
          double.infinity,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedItem!.name} '
              '${amount.toStringAsFixed(0)}${_selectedItem!.unit} '
              '사용 완료\n'
              '남은 재고: '
              '${remaining.toStringAsFixed(0)}${_selectedItem!.unit}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차감 실패'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomPadding + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                '식료품/생활용품 사용기록',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // 상품명 입력
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '상품명',
              hintText: '휴지, 세제 등 입력',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _selectedItem != null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          ),

          // 자동완성 목록
          if (_suggestions.isNotEmpty && _selectedItem == null)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  final isLow = item.currentStock <= item.threshold;
                  return ListTile(
                    dense: true,
                    title: Text(item.name),
                    subtitle: Text(
                      '재고: ${item.currentStock.toStringAsFixed(0)}${item.unit}',
                      style: TextStyle(color: isLow ? Colors.orange : null),
                    ),
                    trailing: Text('📍${item.location}'),
                    onTap: () => _selectItem(item),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // 선택된 아이템 정보
          if (_selectedItem != null) ...[
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedItem!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '현재 재고: '
                            '${_selectedItem!.currentStock.toStringAsFixed(0)}'
                            '${_selectedItem!.unit} '
                            '| 📍${_selectedItem!.location}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 사용량 입력
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '사용량',
                    border: const OutlineInputBorder(),
                    suffixText: _selectedItem?.unit ?? '개',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 빠른 선택 버튼
              ...(_selectedItem != null && _selectedItem!.bundleSize > 1
                  ? [
                      ActionChip(
                        label: const Text('1묶음'),
                        onPressed: () {
                          _amountController.text = _selectedItem!.bundleSize
                              .toStringAsFixed(0);
                        },
                      ),
                      const SizedBox(width: 4),
                    ]
                  : []),
              ActionChip(
                label: const Text('1'),
                onPressed: () => _amountController.text = '1',
              ),
              const SizedBox(width: 4),
              ActionChip(
                label: const Text('5'),
                onPressed: () => _amountController.text = '5',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 차감 버튼
          FilledButton.icon(
            onPressed: _selectedItem != null ? _submit : null,
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('차감하기'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
