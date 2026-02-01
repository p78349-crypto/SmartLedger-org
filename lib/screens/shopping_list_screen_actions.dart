part of shopping_list_screen;

extension ShoppingListScreenActions on _ShoppingListScreenState {
  void _shareList() {
    final buffer = StringBuffer();
    buffer.writeln('📋 장보기 리스트');
    buffer.writeln(widget.shoppingList.urgentMessage);
    buffer.writeln();

    for (final item in widget.shoppingList.items) {
      final marker = item.isUrgent ? '🚨' : '▫️';
      buffer.writeln('$marker ${item.name} ${item.quantity}${item.unit}');
    }

    buffer.writeln();
    final count = widget.shoppingList.items.length;
    final cost = ShoppingListGenerator.formatPrice(
      widget.shoppingList.totalCost,
    );
    buffer.writeln('총 $count개 품목, 예상 비용: $cost원');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('공유 기능 준비 중입니다\n\n${buffer.toString()}')),
    );
  }

  void _completeAllShopping() {
    showDialog(
      context: context,
      builder: (context) {
        final isTyphoon =
            widget.shoppingList.forecast.condition == WeatherCondition.typhoon;
        final conditionLabel = isTyphoon ? '태풍' : '극한 날씨';

        final savings = widget.shoppingList.potentialSavings;
        final savingsText = savings > 0
            ? '약 ${ShoppingListGenerator.formatPrice(savings)}원을 '
                  '절약하셨습니다.'
            : '';

        return AlertDialog(
          title: const Text('🎉 장보기 완료!'),
          content: Text(
            '모든 품목을 구매하셨습니다.\n'
            '$conditionLabel 대비 완료!\n\n'
            '$savingsText',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}
