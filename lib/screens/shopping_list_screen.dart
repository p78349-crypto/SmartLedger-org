// 쇼핑 리스트 화면
//
// 날씨 예보 기반 자동 생성된 쇼핑 리스트 표시

library shopping_list_screen;

import 'package:flutter/material.dart';
import '../utils/shopping_list_generator.dart';
import '../utils/weather_price_sensitivity.dart';
import '../widgets/weather_alert_widget.dart';

part 'shopping_list_screen_builders.dart';
part 'shopping_list_screen_actions.dart';
part 'shopping_list_screen_category_map.dart';

class ShoppingListScreen extends StatefulWidget {
  final ShoppingListResult shoppingList;

  const ShoppingListScreen({super.key, required this.shoppingList});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final Set<int> _checkedItems = {}; // 체크된 아이템 인덱스

  @override
  Widget build(BuildContext context) {
    final forecast = widget.shoppingList.forecast;
    final items = widget.shoppingList.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('장보기 리스트'),
        actions: [
          // 전체 선택/해제
          IconButton(
            icon: Icon(
              _checkedItems.length == items.length
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
            ),
            onPressed: () {
              setState(() {
                if (_checkedItems.length == items.length) {
                  _checkedItems.clear();
                } else {
                  _checkedItems.addAll(List.generate(items.length, (i) => i));
                }
              });
            },
          ),
          // 공유
          IconButton(icon: const Icon(Icons.share), onPressed: _shareList),
        ],
      ),
      body: Column(
        children: [
          // 긴급 알림 배너
          _buildUrgentBanner(forecast),

          // 요약 정보
          _buildSummaryCard(),

          // 쇼핑 리스트
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildShoppingItem(items[index], index);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
}

