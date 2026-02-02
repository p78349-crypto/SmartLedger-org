import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../models/shopping_cart_item.dart';
import '../repositories/app_repositories.dart';
import '../services/consumable_inventory_service.dart';
import '../services/health_guardrail_service.dart';
import '../services/user_pref_service.dart';
import '../utils/wms_data_gateway.dart';

class ConsumableInventoryScreen extends StatefulWidget {
  final String accountName;

  const ConsumableInventoryScreen({super.key, required this.accountName});

  @override
  State<ConsumableInventoryScreen> createState() =>
      _ConsumableInventoryScreenState();
}

class _ConsumableInventoryScreenState extends State<ConsumableInventoryScreen> {
  String _locationFilter = '전체'; // 로케이션 필터 상태

  Set<String> _countLikeUnits = UserPrefService.defaultCountLikeUnitsV1.toSet();

  String _formatQty(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  bool _isCountLikeUnit(String unit) {
    final u = unit.trim();
    if (u.isEmpty) return false;
    return _countLikeUnits.contains(u);
  }

  Future<void> _loadCountLikeUnits() async {
    try {
      final units = await UserPrefService.getCountLikeUnitsV1();
      if (!mounted) return;
      setState(() {
        _countLikeUnits = units
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet();
      });
    } catch (_) {
      // Best-effort
    }
  }

  Future<void> _showCountLikeUnitsDialog() async {
    final initial = _countLikeUnits.toList()..sort();
    final controller = TextEditingController(text: initial.join(', '));

    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('개수형 단위 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('입력된 단위는 목록에서 -1 버튼이 크게 표시됩니다.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '단위 목록 (쉼표/줄바꿈 구분)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.text = UserPrefService.defaultCountLikeUnitsV1.join(
                ', ',
              );
            },
            child: const Text('기본값'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final parts = controller.text
                  .split(RegExp(r'[\n,]'))
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              Navigator.pop(ctx, parts);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result == null) return;
    await UserPrefService.setCountLikeUnitsV1(result);
    await _loadCountLikeUnits();
  }

  Future<void> _quickDecrementOne(ConsumableInventoryItem item) async {
    final warning = await ConsumableInventoryService.instance.useItem(
      item.id,
      1.0,
    );
    if (!mounted) return;
    if (warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(warning.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // ✅ Gateway를 통한 초기 로드 (캐싱 적용)
    WmsInventoryGateway.instance.getItems();
    _loadCountLikeUnits();
  }

  // 로케이션 필터 옵션 (전체 + 기본 옵션들)
  List<String> get _locationOptions => [
    '전체',
    ...ConsumableInventoryItem.locationOptions,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('생활용품 재고 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '개수형 단위 설정',
            onPressed: _showCountLikeUnitsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddItemDialog,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<ConsumableInventoryItem>>(
        // ✅ Gateway 캐싱 적용 후에도 실시간 업데이트 유지
        valueListenable: ConsumableInventoryService.instance.items,
        builder: (context, items, _) {
            // 로케이션 필터 적용
            final filteredItems = _locationFilter == '전체'
                ? items
                : items.where((e) => e.location == _locationFilter).toList();

          return Column(
            children: [
              // 로케이션 필터 칩
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: _locationOptions.map((loc) {
                    final isSelected = _locationFilter == loc;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(loc),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _locationFilter = loc);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              // 아이템 목록
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          _locationFilter == '전체'
                              ? '등록된 소모품이 없습니다.\n우측 상단 + 버튼으로 추가하세요.'
                              : '$_locationFilter에 등록된 소모품이 없습니다.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isLow = item.currentStock <= item.threshold;
                          final isEmpty = item.currentStock <= 0;

                          final theme = Theme.of(context);
                          final accentColor = isEmpty
                              ? theme.colorScheme.error
                              : (isLow
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.primary);

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isEmpty || isLow
                                    ? accentColor.withValues(alpha: 0.5)
                                    : theme.colorScheme.outlineVariant,
                                width: (isEmpty || isLow) ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '📍 ${item.location}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isLow)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isEmpty
                                                ? theme
                                                      .colorScheme
                                                      .errorContainer
                                                : theme
                                                      .colorScheme
                                                      .tertiaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            isEmpty ? '재고 없음' : '재고 부족',
                                            style: TextStyle(
                                              color: isEmpty
                                                  ? theme
                                                        .colorScheme
                                                        .onErrorContainer
                                                  : theme
                                                        .colorScheme
                                                        .onTertiaryContainer,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '현재고: '
                                        '${_formatQty(item.currentStock)}'
                                        '${item.unit}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: (isEmpty || isLow)
                                              ? accentColor
                                              : null,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '알림 기준: '
                                        '${_formatQty(item.threshold)}'
                                        '${item.unit} 이하',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      if (_isCountLikeUnit(item.unit)) ...[
                                        FilledButton.tonal(
                                          onPressed: () =>
                                              _quickDecrementOne(item),
                                          style: FilledButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.standard,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                          ),
                                          child: const Text(
                                            '-1',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      _ActionButton(
                                        icon: Icons.remove,
                                        label: '사용',
                                        onPressed: () => _useItem(item),
                                      ),
                                      const SizedBox(width: 8),
                                      _ActionButton(
                                        icon: Icons.add,
                                        label: '추가',
                                        onPressed: () => _refillItem(item),
                                      ),
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        onPressed: () => _sendToCart(item),
                                        icon: const Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('장바구니'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          foregroundColor: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _showEditItemDialog(item),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddItemDialog() {
    _showItemDialog();
  }

  void _showEditItemDialog(ConsumableInventoryItem item) {
    _showItemDialog(item: item);
  }

  void _showItemDialog({ConsumableInventoryItem? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final stockController = TextEditingController(
      text: item?.currentStock.toString() ?? '0',
    );
    final thresholdController = TextEditingController(
      text: item?.threshold.toString() ?? '1',
    );
    final bundleSizeController = TextEditingController(
      text: item?.bundleSize.toString() ?? '1',
    );
    final unitController = TextEditingController(text: item?.unit ?? '개');
    String selectedLocation = item?.location ?? '기타';

    final selectedTags = <String>{...?(item?.healthTags)};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(item == null ? '재고 추가' : '재고 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '품목명 (예: 휴지)',
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            decoration: const InputDecoration(labelText: '현재고'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: '단위 (예: 롤, 개)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 로케이션 선택 드롭다운
                    DropdownButtonFormField<String>(
                      initialValue: selectedLocation,
                      decoration: const InputDecoration(
                        labelText: '보관 위치',
                        border: OutlineInputBorder(),
                      ),
                      items: ConsumableInventoryItem.locationOptions
                          .map(
                            (loc) =>
                                DropdownMenuItem(value: loc, child: Text(loc)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedLocation = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: thresholdController,
                      decoration: const InputDecoration(
                        labelText: '알림 기준 (이하일 때 알림)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    TextField(
                      controller: bundleSizeController,
                      decoration: const InputDecoration(
                        labelText: '묶음 단위 (예: 30롤 묶음이면 30)',
                        hintText: '휴지 대형 묶음은 보통 30입니다.',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '건강 태그 (선택)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: HealthGuardrailService.defaultTags.map((tag) {
                        final isSelected = selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (v) {
                            setDialogState(() {
                              if (v) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                if (item != null)
                  TextButton(
                    onPressed: () {
                      ConsumableInventoryService.instance.deleteItem(item.id);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '삭제',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final stock = double.tryParse(stockController.text) ?? 0.0;
                    final threshold =
                        double.tryParse(thresholdController.text) ?? 1.0;
                    final bundleSize =
                        double.tryParse(bundleSizeController.text) ?? 1.0;
                    final unit = unitController.text.trim();
                    final tags = selectedTags.toList();

                    if (item == null) {
                      // ✅ Gateway를 통한 추가 (유효성 검사 + 중복 체크)
                      final input = WmsInventoryInput.full(
                        name: name,
                        currentStock: stock,
                        unit: unit,
                        threshold: threshold,
                        bundleSize: bundleSize,
                        location: selectedLocation,
                        healthTags: tags,
                      );

                      final result = await WmsInventoryGateway.instance.addItem(
                        input: input,
                      );

                      if (!context.mounted) return;

                      if (result.success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${result.data?.name} 추가 완료'),
                          ),
                        );
                      } else if (result.type == WmsOperationType.duplicate) {
                        // 중복 품목 - 사용자에게 알림
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('이미 존재하는 품목'),
                            content: Text(
                              '${result.data?.name}이(가) 이미 등록되어 있습니다.\n'
                              '현재 재고: ${result.data?.currentStock}'
                              '${result.data?.unit}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('확인'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // 유효성 검사 실패
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('추가 실패: ${result.errorMessage}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      // ✅ Gateway를 통한 수정
                      final updated = item.copyWith(
                        name: name,
                        currentStock: stock,
                        threshold: threshold,
                        bundleSize: bundleSize,
                        unit: unit,
                        location: selectedLocation,
                        healthTags: tags,
                      );

                      final result =
                          await WmsInventoryGateway.instance.updateItem(
                        item: updated,
                      );

                      if (!context.mounted) return;

                      if (result.success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${updated.name} 수정 완료')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('수정 실패: ${result.errorMessage}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _useItem(ConsumableInventoryItem item) {
    _showAmountDialog(
      title: '사용량 입력',
      item: item,
      onConfirm: (amount) async {
        final warning = await ConsumableInventoryService.instance.useItem(
          item.id,
          amount,
        );
        if (!mounted) return;
        if (warning != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(warning.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _refillItem(ConsumableInventoryItem item) {
    _showAmountDialog(
      title: '추가량 입력',
      item: item,
      onConfirm: (amount) async {
        await ConsumableInventoryService.instance.updateItem(
          item.copyWith(currentStock: item.currentStock + amount),
        );
      },
    );
  }

  void _showAmountDialog({
    required String title,
    required ConsumableInventoryItem item,
    required Future<void> Function(double) onConfirm,
  }) {
    final controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(suffixText: item.unit),
            ),
            const SizedBox(height: 16),
            const Text(
              '빠른 선택',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.bundleSize > 1)
                  ActionChip(
                    label: Text('1묶음 (${item.bundleSize.toInt()}${item.unit})'),
                    onPressed: () =>
                        controller.text = item.bundleSize.toString(),
                  ),
                ActionChip(
                  label: const Text('9개'),
                  onPressed: () => controller.text = '9',
                ),
                ActionChip(
                  label: const Text('10개'),
                  onPressed: () => controller.text = '10',
                ),
                ActionChip(
                  label: const Text('30개'),
                  onPressed: () => controller.text = '30',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null) {
                await onConfirm(val);
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendToCart(ConsumableInventoryItem item) async {
    final current = await AppRepositories.shoppingCart.getItems(
      accountName: widget.accountName,
    );

    // Check if already in cart
    if (current.any((i) => i.name == item.name)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name}은(는) 이미 장바구니에 있습니다.')),
        );
      }
      return;
    }

    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'cart_${now.microsecondsSinceEpoch}',
      name: item.name,
      memo: '재고 부족으로 자동 추가',
      createdAt: now,
      updatedAt: now,
    );

    final next = List<ShoppingCartItem>.from(current)..add(newItem);
    await AppRepositories.shoppingCart.setItems(
      accountName: widget.accountName,
      items: next,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${item.name}을(를) 장바구니에 담았습니다.')));
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
