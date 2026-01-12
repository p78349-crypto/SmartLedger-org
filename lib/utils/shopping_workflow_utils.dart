/// 쇼핑 카트 3단계 워크플로우 유틸리티
/// 1단계: 준비 (쇼핑 목록 작성)
/// 2단계: 쇼핑 (품목 체크)
/// 3단계: 기록 (가계부 저장)

library shopping_workflow_utils;

enum ShoppingMode { planning, shopping, recording }

class CartItem {
  final String id;
  final String name;
  String quantity;
  String estimatedPrice;
  bool isChecked;

  CartItem({
    required this.id,
    required this.name,
    this.quantity = '1',
    this.estimatedPrice = '0',
    this.isChecked = false,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as String? ?? '1',
      estimatedPrice: json['estimatedPrice'] as String? ?? '0',
      isChecked: json['isChecked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'estimatedPrice': estimatedPrice,
      'isChecked': isChecked,
    };
  }

  @override
  String toString() => 'CartItem($name x$quantity @ $estimatedPrice원)';
}

class ShoppingWorkflowUtils {
  /// 1단계: 항목 추가
  static CartItem createItem(String name) {
    return CartItem(id: DateTime.now().toString(), name: name);
  }

  /// 2단계: 체크 토글
  static void toggleItemCheck(CartItem item) {
    item.isChecked = !item.isChecked;
  }

  /// 2단계: 수량 및 가격 업데이트
  static void updateItemDetails(
    CartItem item, {
    String? quantity,
    String? price,
  }) {
    if (quantity != null) item.quantity = quantity;
    if (price != null) item.estimatedPrice = price;
  }

  /// 3단계: 체크된 항목만 필터링
  static List<CartItem> getCheckedItems(List<CartItem> items) {
    return items.where((item) => item.isChecked).toList();
  }

  /// 3단계: 총합 계산
  static double calculateTotal(List<CartItem> items) {
    double total = 0;
    for (final item in items) {
      final price = double.tryParse(item.estimatedPrice) ?? 0;
      final qty = double.tryParse(item.quantity) ?? 1;
      total += price * qty;
    }
    return total;
  }

  /// 체크된 항목 개수
  static int getCheckedCount(List<CartItem> items) {
    return items.where((item) => item.isChecked).length;
  }

  /// 다음 모드 결정
  static ShoppingMode getNextMode(
    ShoppingMode currentMode,
    List<CartItem> items,
  ) {
    return switch (currentMode) {
      ShoppingMode.planning =>
        items.isNotEmpty ? ShoppingMode.shopping : ShoppingMode.planning,
      ShoppingMode.shopping =>
        getCheckedItems(items).isNotEmpty
            ? ShoppingMode.recording
            : ShoppingMode.shopping,
      ShoppingMode.recording => ShoppingMode.planning,
    };
  }

  /// 모드 라벨
  static String getModeLabel(ShoppingMode mode) {
    return switch (mode) {
      ShoppingMode.planning => '1단계: 쇼핑 준비',
      ShoppingMode.shopping => '2단계: 쇼핑',
      ShoppingMode.recording => '3단계: 가계부 기록',
    };
  }

  /// 완료 후 초기화
  static void completeWorkflow(List<CartItem> items) {
    items.removeWhere((item) => item.isChecked);
  }
}
