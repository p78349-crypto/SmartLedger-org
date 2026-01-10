// 쇼핑 리스트 화면
//
// 날씨 예보 기반 자동 생성된 쇼핑 리스트 표시

import 'package:flutter/material.dart';
import '../utils/shopping_list_generator.dart';
import '../utils/weather_price_sensitivity.dart';
import '../widgets/weather_alert_widget.dart';

class ShoppingListScreen extends StatefulWidget {
  final ShoppingListResult shoppingList;

  const ShoppingListScreen({
    super.key,
    required this.shoppingList,
  });

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
                  _checkedItems.addAll(
                    List.generate(items.length, (i) => i),
                  );
                }
              });
            },
          ),
          // 공유
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareList,
          ),
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

  /// 긴급 알림 배너
  Widget _buildUrgentBanner(WeatherForecast forecast) {
    final urgency = forecast.urgency;
    if (urgency < 3) return const SizedBox.shrink();

    final color = urgency >= 4 ? Colors.red : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.warning, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shoppingList.urgentMessage,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  forecast.preparationTiming,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 요약 카드
  Widget _buildSummaryCard() {
    final result = widget.shoppingList;
    final checkedCount = _checkedItems.length;
    final totalCount = result.items.length;
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 진행률
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '진행률: $checkedCount/$totalCount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: progress == 1.0 ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 16),

            // 비용 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '예상 비용',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    Text(
                      '${ShoppingListGenerator.formatPrice(result.totalCost)}원',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (result.potentialSavings > 0) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '예상 절약',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        '${ShoppingListGenerator.formatPrice(result.potentialSavings)}원',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 쇼핑 아이템
  Widget _buildShoppingItem(ShoppingListItem item, int index) {
    final isChecked = _checkedItems.contains(index);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _checkedItems.add(index);
            } else {
              _checkedItems.remove(index);
            }
          });
        },
        title: Row(
          children: [
            // 카테고리 아이콘
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getCategoryColor(item.category).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getCategoryIcon(item.category),
                color: _getCategoryColor(item.category),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // 품목명
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: isChecked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (item.isUrgent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '긴급',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.quantity}${item.unit}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: isChecked
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // 가격
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${ShoppingListGenerator.formatPrice(item.totalCost)}원',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: isChecked
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 44, top: 4),
          child: Text(
            item.reason,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  /// 하단 바
  Widget _buildBottomBar() {
    final checkedCount = _checkedItems.length;
    final totalCount = widget.shoppingList.items.length;

    if (checkedCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$checkedCount개 선택됨',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: checkedCount == totalCount
                  ? _completeAllShopping
                  : null,
              icon: const Icon(Icons.check),
              label: const Text('장보기 완료'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 공유
  void _shareList() {
    final buffer = StringBuffer();
    buffer.writeln('📋 장보기 리스트');
    buffer.writeln(widget.shoppingList.urgentMessage);
    buffer.writeln();

    for (final item in widget.shoppingList.items) {
      buffer.writeln(
        '${item.isUrgent ? '🚨' : '▫️'} ${item.name} ${item.quantity}${item.unit}',
      );
    }

    buffer.writeln();
    buffer.writeln(
      '총 ${widget.shoppingList.items.length}개 품목, '
      '예상 비용: ${ShoppingListGenerator.formatPrice(widget.shoppingList.totalCost)}원',
    );

    // 실제 공유 기능은 share_plus 패키지 필요
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('공유 기능 준비 중입니다\n\n${buffer.toString()}')),
    );
  }

  /// 장보기 완료
  void _completeAllShopping() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 장보기 완료!'),
        content: Text(
          '모든 품목을 구매하셨습니다.\n'
          '${widget.shoppingList.forecast.condition == WeatherCondition.typhoon ? '태풍' : '극한 날씨'} 대비 완료!\n\n'
          '${widget.shoppingList.potentialSavings > 0 ? '약 ${ShoppingListGenerator.formatPrice(widget.shoppingList.potentialSavings)}원을 절약하셨습니다.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 화면 닫기
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(PrepCategory category) {
    switch (category) {
      case PrepCategory.safety:
        return Colors.red;
      case PrepCategory.freshFood:
        return Colors.green;
      case PrepCategory.storableFood:
        return Colors.brown;
      case PrepCategory.medicine:
        return Colors.purple;
      case PrepCategory.energy:
        return Colors.orange;
      case PrepCategory.water:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(PrepCategory category) {
    switch (category) {
      case PrepCategory.safety:
        return Icons.security;
      case PrepCategory.freshFood:
        return Icons.restaurant;
      case PrepCategory.storableFood:
        return Icons.inventory_2;
      case PrepCategory.medicine:
        return Icons.medical_services;
      case PrepCategory.energy:
        return Icons.bolt;
      case PrepCategory.water:
        return Icons.water_drop;
    }
  }
}
