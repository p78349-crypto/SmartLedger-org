library shopping_guide_screen;

import 'package:flutter/material.dart';
import '../models/shopping_cart_item.dart';
import '../services/store_layout_service.dart';
import '../services/user_pref_service.dart';
import '../utils/currency_formatter.dart';

part 'shopping_guide_screen_builders.dart';
part 'shopping_guide_screen_groups.dart';

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
      return layoutService
          .getAisleOrder(a)
          .compareTo(layoutService.getAisleOrder(b));
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
  double get _progress => _totalItems > 0 ? _completedItems / _totalItems : 0.0;

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
}

