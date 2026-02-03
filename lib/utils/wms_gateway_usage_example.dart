/// WMS Gateway 사용 예시
///
/// 기존 Service 직접 호출 → Gateway를 통한 호출로 변경
library;

import 'package:flutter/material.dart';
import 'wms_data_gateway.dart';
import 'wms_unified_gateway.dart';

/// ============================================================================
/// 예시 1: 재고 목록 조회 (캐싱 적용)
/// ============================================================================

class InventoryListExample extends StatelessWidget {
  const InventoryListExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // ❌ 기존: ConsumableInventoryService.instance.items.value
      // ✅ 변경: Gateway 사용 (캐싱 자동 적용)
      future: WmsInventoryGateway.instance.getItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final items = snapshot.data!;
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item.name),
              subtitle: Text('재고: ${item.currentStock}${item.unit}'),
            );
          },
        );
      },
    );
  }
}

/// ============================================================================
/// 예시 2: 아이템 추가 (유효성 검사 자동)
/// ============================================================================

Future<void> addItemExample(BuildContext context) async {
  // ✅ 입력 데이터 생성
  final input = WmsInventoryInput.full(
    name: '두루마리 휴지',
    currentStock: 30.0,
    unit: '롤',
    threshold: 5.0,
    location: '욕실',
  );

  // ✅ Gateway를 통한 추가 (유효성 검사 + 중복 체크 자동)
  final result = await WmsInventoryGateway.instance.addItem(
    input: input,
  );

  if (!context.mounted) return;

  // ✅ 결과 처리
  if (result.type == WmsOperationType.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.data?.name} 추가 완료')),
    );
  } else if (result.type == WmsOperationType.duplicate) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('이미 존재: ${result.data?.name}')),
    );
  } else if (result.type == WmsOperationType.failure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('추가 실패: ${result.errorMessage}'),
        backgroundColor: Colors.red,
      ),
    );
  } else if (result.type == WmsOperationType.warning) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('경고: ${result.warningMessage}'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

/// ============================================================================
/// 예시 3: 빠른 아이템 생성 (quick_stock_use_screen)
/// ============================================================================

Future<void> quickCreateExample(String productName) async {
  // ✅ 빠른 입력 (최소 정보)
  final input = WmsInventoryInput.quick(name: productName);

  final result = await WmsInventoryGateway.instance.addItem(
    input: input,
    source: WmsInputSource.quickUse, // 소스 추적
  );

  if (result.success) {
    debugPrint('Created: ${result.data?.name}');
  } else if (result.type == WmsOperationType.duplicate) {
    debugPrint('Already exists: ${result.data?.name}');
    // 기존 아이템 사용
  }
}

/// ============================================================================
/// 예시 4: 통합 검색 (재고 + 유통기한)
/// ============================================================================

Future<void> unifiedSearchExample(String query) async {
  final result = await WmsUnifiedGateway.instance.search(query);

  debugPrint('재고: ${result.inventoryItems.length}개');
  debugPrint('전체: ${result.totalCount}개');

  for (final item in result.inventoryItems) {
    debugPrint('- [재고] ${item.name}: ${item.currentStock}${item.unit}');
  }

  for (final item in result.inventoryItems.where((e) => e.expiryDate != null)) {
    final daysLeft = item.expiryDate!
        .difference(DateTime.now())
        .inDays;
    debugPrint('- [유통기한] ${item.name}: D$daysLeft');
  }
}

/// ============================================================================
/// 예시 5: 알림 요약 조회
/// ============================================================================

Future<void> alertSummaryExample(BuildContext context) async {
  final alerts = await WmsUnifiedGateway.instance.getAlerts();

  if (!alerts.hasAlerts) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림 없음')),
    );
    return;
  }

  final message = '''
재고 부족: ${alerts.lowStockItems.length}개
유통기한 임박: ${alerts.expiringInventoryItems.length}개
유통기한 경과: ${alerts.expiredInventoryItems.length}개
''';

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

/// ============================================================================
/// 예시 6: 위치별 필터링
/// ============================================================================

Future<void> locationFilterExample() async {
  final bathroomItems = await WmsInventoryGateway.instance.getItemsByLocation(
    '욕실',
  );

  debugPrint('욕실 재고: ${bathroomItems.length}개');
  for (final item in bathroomItems) {
    debugPrint('- ${item.name}: ${item.currentStock}${item.unit}');
  }
}

/// ============================================================================
/// 마이그레이션 가이드
/// ============================================================================

/// 기존 코드 (❌):
/// ```dart
/// await ConsumableInventoryService.instance.addItem(
///   name: name,
///   currentStock: stock,
///   unit: unit,
///   threshold: threshold,
///   location: location,
/// );
/// ```
///
/// Gateway 사용 (✅):
/// ```dart
/// final input = WmsInventoryInput.full(
///   name: name,
///   currentStock: stock,
///   unit: unit,
///   threshold: threshold,
///   location: location,
/// );
///
/// final result = await WmsInventoryGateway.instance.addItem(
///   input: input,
///   source: WmsInputSource.manual,
/// );
///
/// if (result.success) {
///   // 성공 처리
/// } else if (result.type == WmsOperationType.duplicate) {
///   // 중복 처리
/// } else {
///   // 실패 처리
/// }
/// ```
///
/// 장점:
/// - ✅ 유효성 검사 자동
/// - ✅ 중복 체크 자동
/// - ✅ 캐싱으로 성능 향상
/// - ✅ 로깅/분석 자동
/// - ✅ 에러 처리 일관화
/// - ✅ 소스 추적 가능
