import 'package:flutter/material.dart';
import '../models/shopping_cart_item.dart';
import '../services/store_layout_service.dart';
import '../services/user_pref_service.dart';
import '../utils/currency_formatter.dart';

/// 쇼핑 안내 화면
/// 
/// 장바구니 항목을 통로별로 그룹화하고 최적 경로로 안내합니다.
class ShoppingGuideScreen extends StatefulWidget {
  const ShoppingGuideScreen({
    super.key,
    required this.accountName,
    required this.items,
  });

  final String accountName;
  final List<ShoppingCartItem> items;

  @override
  State<ShoppingGuideScreen> createState() => _ShoppingGuideScreenState();
}

class _ShoppingGuideScreenState extends State<ShoppingGuideScreen> {
  List<ShoppingCartItem> _items = [];
  Map<String, List<ShoppingCartItem>> _groupedItems = {};
  List<String> _sortedLocations = [];
  int _currentLocationIndex = 0;

  @override
  void initState() {
    super.initState();
    _items = widget.items.toList();
    _organizeItems();
  }

  void _organizeItems() {
    final layoutService = StoreLayoutService.instance;

    // 위치가 있는 항목과 없는 항목 분리
    final (withLocation, withoutLocation) = layoutService.separateByLocation(
      items: _items,
      getLocation: (item) => item.storeLocation,
    );

    // 위치별로 그룹화
    _groupedItems = layoutService.groupByLocation(
      items: withLocation,
      getLocation: (item) => item.storeLocation,
    );

    // 위치 없는 항목도 별도 그룹으로 추가
    if (withoutLocation.isNotEmpty) {
      _groupedItems['위치 미정'] = withoutLocation;
    }

    // 통로 순서대로 정렬
    _sortedLocations = _groupedItems.keys.toList();
    _sortedLocations.sort((a, b) {
      if (a == '위치 미정') return 1; // 마지막으로
      if (b == '위치 미정') return -1;
      return layoutService.getAisleOrder(a).compareTo(
            layoutService.getAisleOrder(b),
          );
    });

    setState(() {});
  }

  void _toggleItemCheck(ShoppingCartItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    final updated = item.copyWith(
      isChecked: !item.isChecked,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _items[index] = updated;
    });

    _organizeItems();
    _saveItems();
  }

  Future<void> _saveItems() async {
    await UserPrefService.setShoppingCartItems(
      accountName: widget.accountName,
      items: _items,
    );
  }

  void _moveToNextLocation() {
    if (_currentLocationIndex < _sortedLocations.length - 1) {
      setState(() {
        _currentLocationIndex++;
      });
      _scrollToCurrentLocation();
    }
  }

  void _moveToPreviousLocation() {
    if (_currentLocationIndex > 0) {
      setState(() {
        _currentLocationIndex--;
      });
      _scrollToCurrentLocation();
    }
  }

  void _scrollToCurrentLocation() {
    // 자동 스크롤 구현은 선택사항
  }

  int get _totalItems => _items.length;
  int get _completedItems => _items.where((i) => i.isChecked).length;
  double get _progress =>
      _totalItems > 0 ? _completedItems / _totalItems : 0.0;

  String get _currentLocation {
    if (_sortedLocations.isEmpty) return '시작';
    if (_currentLocationIndex >= _sortedLocations.length) {
      return '완료';
    }
    return _sortedLocations[_currentLocationIndex];
  }

  String? get _nextLocation {
    if (_currentLocationIndex >= _sortedLocations.length - 1) return null;
    return _sortedLocations[_currentLocationIndex + 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('쇼핑 안내'),
        actions: [
          IconButton(
            tooltip: '진행 상황',
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showProgressDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 진행 상황 바
          _buildProgressBar(theme),
          
          // 현재 위치 안내
          _buildCurrentLocationGuide(theme),
          
          // 통로별 항목 리스트
          Expanded(
            child: _sortedLocations.isEmpty
                ? _buildEmptyState(theme)
                : _buildLocationGroupList(theme),
          ),
        ],
      ),
      floatingActionButton: _buildNavigationFAB(theme),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '진행률',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$_completedItems / $_totalItems',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 12,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationGuide(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '현재 위치',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _currentLocation,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          if (_nextLocation != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.secondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '다음: $_nextLocation',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationGroupList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _sortedLocations.length,
      itemBuilder: (context, index) {
        final location = _sortedLocations[index];
        final items = _groupedItems[location] ?? [];
        final isCurrent = index == _currentLocationIndex;
        
        return _buildLocationGroup(
          theme: theme,
          location: location,
          items: items,
          isCurrent: isCurrent,
          index: index,
        );
      },
    );
  }

  Widget _buildLocationGroup({
    required ThemeData theme,
    required String location,
    required List<ShoppingCartItem> items,
    required bool isCurrent,
    required int index,
  }) {
    final completedCount = items.where((i) => i.isChecked).length;
    final totalCount = items.length;
    final allCompleted = completedCount == totalCount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isCurrent ? 4 : 1,
      color: isCurrent
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: ExpansionTile(
        initiallyExpanded: isCurrent,
        leading: CircleAvatar(
          backgroundColor: allCompleted
              ? Colors.green.shade600
              : (isCurrent ? theme.colorScheme.primary : Colors.grey.shade400),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                location,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: allCompleted
                    ? Colors.green.shade100
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$completedCount/$totalCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: allCompleted ? Colors.green.shade700 : null,
                ),
              ),
            ),
          ],
        ),
        children: items.map((item) => _buildItemTile(theme, item)).toList(),
      ),
    );
  }

  Widget _buildItemTile(ThemeData theme, ShoppingCartItem item) {
    final total = item.unitPrice * item.quantity;

    return ListTile(
      dense: true,
      leading: Checkbox(
        value: item.isChecked,
        onChanged: (_) => _toggleItemCheck(item),
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.isChecked ? TextDecoration.lineThrough : null,
          color: item.isChecked ? theme.colorScheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: item.quantity > 1
          ? Text('${item.quantity}개 × ${CurrencyFormatter.format(item.unitPrice)}')
          : null,
      trailing: Text(
        CurrencyFormatter.format(total),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: item.isChecked
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '장바구니가 비어있습니다',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '상품에 위치를 설정하면\n최적 경로로 안내해드립니다',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildNavigationFAB(ThemeData theme) {
    if (_sortedLocations.isEmpty) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_currentLocationIndex > 0)
          FloatingActionButton.small(
            heroTag: 'prev',
            onPressed: _moveToPreviousLocation,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: const Icon(Icons.arrow_upward),
          ),
        const SizedBox(height: 8),
        if (_currentLocationIndex < _sortedLocations.length - 1)
          FloatingActionButton.extended(
            heroTag: 'next',
            onPressed: _moveToNextLocation,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('다음 위치'),
          ),
      ],
    );
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, size: 20),
            SizedBox(width: 8),
            Text('쇼핑 진행 상황'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('총 항목', '$_totalItems개'),
            _buildStatRow('완료', '$_completedItems개'),
            _buildStatRow('남은 항목', '${_totalItems - _completedItems}개'),
            const Divider(),
            _buildStatRow('현재 위치', _currentLocation),
            if (_nextLocation != null)
              _buildStatRow('다음 위치', _nextLocation!),
            const Divider(),
            _buildStatRow(
              '진행률',
              '${(_progress * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
