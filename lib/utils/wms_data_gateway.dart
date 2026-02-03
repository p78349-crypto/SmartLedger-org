/// WMS 데이터 경유지 (Data Gateway Pattern)
///
/// 목적:
/// - 모든 WMS 데이터 입출력을 단일 지점에서 제어
/// - 데이터 유효성 검사 및 변환
/// - 로깅 및 분석
/// - 캐싱 및 성능 최적화
/// - 임시저장 (Draft) 기능
library;

import 'package:flutter/foundation.dart';
import '../models/consumable_inventory_item.dart';
import '../models/wms_inventory_draft_entry.dart';
import '../services/consumable_inventory_service.dart';
import '../services/user_pref_service.dart';

/// WMS 데이터 Gateway - 재고 관리
class WmsInventoryGateway {
  WmsInventoryGateway._();
  static final WmsInventoryGateway instance = WmsInventoryGateway._();

  // 데이터 캐시 (성능 최적화)
  List<ConsumableInventoryItem>? _cachedItems;
  DateTime? _lastCacheTime;
  static const _cacheDuration = Duration(seconds: 30);

  /// 재고 목록 조회 (캐싱 적용)
  Future<List<ConsumableInventoryItem>> getItems({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();

    // 캐시 유효성 체크
    if (!forceRefresh &&
        _cachedItems != null &&
        _lastCacheTime != null &&
        now.difference(_lastCacheTime!) < _cacheDuration) {
      return _cachedItems!;
    }

    // Service에서 로드
    await ConsumableInventoryService.instance.load();
    final items = ConsumableInventoryService.instance.items.value;

    // 캐시 업데이트
    _cachedItems = List.unmodifiable(items);
    _lastCacheTime = now;

    _logRead('Loaded ${items.length} inventory items');
    return _cachedItems!;
  }

  /// 단일 아이템 조회 (이름 기준)
  Future<ConsumableInventoryItem?> findByName(String name) async {
    final items = await getItems();
    final normalized = name.trim().toLowerCase();

    for (final item in items) {
      if (item.name.trim().toLowerCase() == normalized) {
        return item;
      }
    }
    return null;
  }

  /// 단일 아이템 조회 (ID 기준)
  Future<ConsumableInventoryItem?> findById(String id) async {
    final items = await getItems();

    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  /// 위치별 필터링
  Future<List<ConsumableInventoryItem>> getItemsByLocation(
    String location,
  ) async {
    final items = await getItems();

    if (location == '전체') return items;

    return items.where((e) => e.location == location).toList();
  }

  /// 재고 부족 아이템 조회
  Future<List<ConsumableInventoryItem>> getLowStockItems() async {
    final items = await getItems();

    return items.where((e) => e.currentStock <= e.threshold).toList();
  }

  /// 아이템 추가 (유효성 검사 포함)
  Future<WmsOperationResult<ConsumableInventoryItem>> addItem({
    required WmsInventoryInput input,
    WmsInputSource? source,
  }) async {
    try {
      // 1. 유효성 검사
      final validation = input.validate();
      if (!validation.isValid) {
        return WmsOperationResult.failure(
          'Validation failed: ${validation.errors.join(', ')}',
        );
      }

      // 2. 중복 체크
      final existing = await findByName(input.name);
      if (existing != null) {
        return WmsOperationResult.duplicate(existing);
      }

      // 3. Service를 통한 추가
      await ConsumableInventoryService.instance.addItem(
        name: input.name,
        currentStock: input.currentStock,
        unit: input.unit,
        threshold: input.threshold,
        bundleSize: input.bundleSize,
        category: input.category,
        detailCategory: input.detailCategory,
        location: input.location,
        healthTags: input.healthTags,
      );

      // 4. 캐시 무효화
      _invalidateCache();

      // 5. 추가된 아이템 반환
      final newItem = await findByName(input.name);
      if (newItem == null) {
        return WmsOperationResult.failure('Item creation failed');
      }

      _logWrite(
        'Added item: ${newItem.name} (source: ${source?.name ?? 'manual'})',
      );
      return WmsOperationResult.success(newItem);
    } catch (e) {
      _logError('Add item failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  /// 아이템 수정
  Future<WmsOperationResult<ConsumableInventoryItem>> updateItem({
    required ConsumableInventoryItem item,
  }) async {
    try {
      await ConsumableInventoryService.instance.updateItem(item);
      _invalidateCache();

      _logWrite('Updated item: ${item.name}');
      return WmsOperationResult.success(item);
    } catch (e) {
      _logError('Update item failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  /// 아이템 삭제
  Future<WmsOperationResult<void>> deleteItem(String id) async {
    try {
      await ConsumableInventoryService.instance.deleteItem(id);
      _invalidateCache();

      _logWrite('Deleted item: $id');
      return WmsOperationResult.success(null);
    } catch (e) {
      _logError('Delete item failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  /// 아이템 사용 기록
  Future<WmsOperationResult<void>> useItem({
    required String id,
    required double amount,
  }) async {
    try {
      if (amount <= 0) {
        return WmsOperationResult.failure('Amount must be positive');
      }

      final warning = await ConsumableInventoryService.instance.useItem(
        id,
        amount,
      );
      _invalidateCache();

      _logWrite('Used item: $id (amount: $amount)');

      if (warning != null) {
        return WmsOperationResult.warning(null, warning.message);
      }

      return WmsOperationResult.success(null);
    } catch (e) {
      _logError('Use item failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  /// 캐시 무효화
  void _invalidateCache() {
    _cachedItems = null;
    _lastCacheTime = null;
  }

  /// 강제 리로드
  Future<void> reload() async {
    _invalidateCache();
    await getItems(forceRefresh: true);
  }

  // 로깅 메서드들
  void _logRead(String message) {
    debugPrint('[WMS Gateway][READ] $message');
  }

  void _logWrite(String message) {
    debugPrint('[WMS Gateway][WRITE] $message');
  }

  void _logError(String message, Object error) {
    debugPrint('[WMS Gateway][ERROR] $message: $error');
  }
}


// ============================================================================
// 데이터 모델
// ============================================================================

/// 재고 아이템 입력 인터페이스
class WmsInventoryInput {
  final String name;
  final double currentStock;
  final String unit;
  final double threshold;
  final double bundleSize;
  final String category;
  final String? detailCategory;
  final String location;
  final List<String> healthTags;

  const WmsInventoryInput({
    required this.name,
    this.currentStock = 0.0,
    this.unit = '',
    this.threshold = 1.0,
    this.bundleSize = 1.0,
    this.category = '생활용품',
    this.detailCategory,
    this.location = '기타',
    this.healthTags = const [],
  });

  /// 빠른 생성 (품목명만)
  factory WmsInventoryInput.quick({required String name}) {
    return WmsInventoryInput(name: name);
  }

  /// 전체 정보 생성
  factory WmsInventoryInput.full({
    required String name,
    required double currentStock,
    required String unit,
    required double threshold,
    double bundleSize = 1.0,
    String category = '생활용품',
    String? detailCategory,
    String location = '기타',
    List<String> healthTags = const [],
  }) {
    return WmsInventoryInput(
      name: name,
      currentStock: currentStock,
      unit: unit,
      threshold: threshold,
      bundleSize: bundleSize,
      category: category,
      detailCategory: detailCategory,
      location: location,
      healthTags: healthTags,
    );
  }

  /// 유효성 검사
  WmsValidationResult validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('품목명을 입력하세요');
    }
    if (currentStock < 0) {
      errors.add('재고는 0 이상이어야 합니다');
    }
    if (threshold < 0) {
      errors.add('알림 기준은 0 이상이어야 합니다');
    }
    if (bundleSize <= 0) {
      errors.add('묶음 크기는 0보다 커야 합니다');
    }
    if (!ConsumableInventoryItem.locationOptions.contains(location)) {
      errors.add('유효하지 않은 보관 위치입니다: $location');
    }

    return WmsValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

/// 유통기한 아이템 입력 인터페이스
class WmsExpiryInput {
  final String name;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final String memo;
  final double quantity;
  final String unit;
  final String category;
  final String location;
  final double price;
  final String supplier;
  final List<String> healthTags;

  const WmsExpiryInput({
    required this.name,
    required this.purchaseDate,
    required this.expiryDate,
    this.memo = '',
    this.quantity = 1.0,
    this.unit = '',
    this.category = '기타',
    this.location = '냉장',
    this.price = 0.0,
    this.supplier = '',
    this.healthTags = const [],
  });

  WmsValidationResult validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('식품명을 입력하세요');
    }
    if (expiryDate.isBefore(purchaseDate)) {
      errors.add('유통기한은 구입일 이후여야 합니다');
    }
    if (quantity <= 0) {
      errors.add('수량은 0보다 커야 합니다');
    }
    if (price < 0) {
      errors.add('가격은 0 이상이어야 합니다');
    }

    return WmsValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

/// 유효성 검사 결과
class WmsValidationResult {
  final bool isValid;
  final List<String> errors;

  const WmsValidationResult({
    required this.isValid,
    this.errors = const <String>[],
  });
}

/// 작업 결과
class WmsOperationResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final String? warningMessage;
  final WmsOperationType type;

  const WmsOperationResult._({
    required this.success,
    this.data,
    this.errorMessage,
    this.warningMessage,
    this.type = WmsOperationType.success,
  });

  factory WmsOperationResult.success(T? data) {
    return WmsOperationResult._(
      success: true,
      data: data,
    );
  }

  factory WmsOperationResult.failure(String message) {
    return WmsOperationResult._(
      success: false,
      errorMessage: message,
      type: WmsOperationType.failure,
    );
  }

  factory WmsOperationResult.duplicate(T existingData) {
    return WmsOperationResult._(
      success: false,
      data: existingData,
      errorMessage: '이미 존재하는 품목입니다',
      type: WmsOperationType.duplicate,
    );
  }

  factory WmsOperationResult.warning(T? data, String message) {
    return WmsOperationResult._(
      success: true,
      data: data,
      warningMessage: message,
      type: WmsOperationType.warning,
    );
  }
}

enum WmsOperationType {
  success,
  failure,
  duplicate,
  warning,
}

/// 입력 소스
enum WmsInputSource {
  manual, // 수동 입력 (재고 관리 화면)
  quickUse, // 빠른 차감
  shoppingCart, // 장바구니
  voiceCommand, // 음성 명령
  autoSync, // 자동 동기화
  draftRestore, // 임시저장 복원
}

// ============================================================================
// WMS Draft 관리 (임시저장)
// ============================================================================

/// WMS 임시저장 관리자
///
/// 사용 시나리오:
/// - 재고 입력 중 앱 종료 → 자동 저장
/// - 장바구니 자동등록 체크 → 임시 저장
/// - 나중에 일괄 등록
class WmsDraftManager {
  WmsDraftManager._();
  static final WmsDraftManager instance = WmsDraftManager._();

  /// 임시저장 목록 조회
  Future<List<WmsInventoryDraftEntry>> getDrafts({
    required String accountName,
  }) async {
    try {
      final drafts = await UserPrefService.getWmsInventoryDrafts(
        accountName: accountName,
      );
      _logRead('Loaded ${drafts.length} WMS drafts');
      return drafts;
    } catch (e) {
      _logError('Get drafts failed', e);
      return const [];
    }
  }

  /// 임시저장 추가
  Future<WmsOperationResult<WmsInventoryDraftEntry>> addDraft({
    required String accountName,
    required WmsInventoryDraftEntry draft,
  }) async {
    try {
      await UserPrefService.addWmsInventoryDraft(
        accountName: accountName,
        draft: draft,
      );
      _logWrite('Added draft: ${draft.name} (source: ${draft.source})');
      return WmsOperationResult.success(draft);
    } catch (e) {
      _logError('Add draft failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  /// 임시저장 수정
  Future<WmsOperationResult<WmsInventoryDraftEntry>> updateDraft({
    required String accountName,
    required WmsInventoryDraftEntry draft,
  }) async {
    try {
      await UserPrefService.updateWmsInventoryDraft(
        accountName: accountName,
        draft: draft,
      );
      _logWrite('Updated draft: ${draft.name}');
      return WmsOperationResult.success(draft);
    } catch (e) {
      _logError('Update draft failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  /// 임시저장 삭제
  Future<WmsOperationResult<void>> removeDraft({
    required String accountName,
    required String draftId,
  }) async {
    try {
      await UserPrefService.removeWmsInventoryDraft(
        accountName: accountName,
        id: draftId,
      );
      _logWrite('Removed draft: $draftId');
      return WmsOperationResult.success(null);
    } catch (e) {
      _logError('Remove draft failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  /// 임시저장을 실제 재고로 변환
  Future<WmsOperationResult<ConsumableInventoryItem>> convertToInventory({
    required String accountName,
    required WmsInventoryDraftEntry draft,
  }) async {
    try {
      // 1. Draft를 WmsInventoryInput으로 변환
      final input = WmsInventoryInput.full(
        name: draft.name,
        currentStock: draft.currentStock ?? 1.0,
        unit: draft.unit ?? '개',
        threshold: draft.threshold ?? 1.0,
        bundleSize: draft.bundleSize ?? 1.0,
        category: draft.category ?? '생활용품',
        detailCategory: draft.detailCategory,
        location: draft.location ?? '기타',
      );

      // 2. Gateway를 통해 추가
      final result = await WmsInventoryGateway.instance.addItem(input: input);

      // 3. 성공 시 Draft 삭제
      if (result.success) {
        await removeDraft(accountName: accountName, draftId: draft.id);
        _logWrite('Converted draft to inventory: ${draft.name}');
      }

      return result;
    } catch (e) {
      _logError('Convert draft failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  /// 여러 임시저장을 일괄 변환
  Future<List<WmsOperationResult<ConsumableInventoryItem>>>
      convertMultipleDrafts({
    required String accountName,
    required List<WmsInventoryDraftEntry> drafts,
  }) async {
    final results = <WmsOperationResult<ConsumableInventoryItem>>[];

    for (final draft in drafts) {
      final result = await convertToInventory(
        accountName: accountName,
        draft: draft,
      );
      results.add(result);
    }

    final successCount = results.where((r) => r.success).length;
    _logWrite('Converted $successCount/${drafts.length} drafts to inventory');

    return results;
  }

  /// 모든 임시저장 삭제
  Future<WmsOperationResult<void>> clearAllDrafts({
    required String accountName,
  }) async {
    try {
      await UserPrefService.clearAllWmsInventoryDrafts(
        accountName: accountName,
      );
      _logWrite('Cleared all drafts');
      return WmsOperationResult.success(null);
    } catch (e) {
      _logError('Clear all drafts failed', e);
      return WmsOperationResult.failure(e.toString());
    }
  }

  void _logRead(String message) {
    if (kDebugMode) {
      print('[WMS Draft][READ] $message');
    }
  }

  void _logWrite(String message) {
    if (kDebugMode) {
      print('[WMS Draft][WRITE] $message');
    }
  }

  void _logError(String message, Object error) {
    if (kDebugMode) {
      print('[WMS Draft][ERROR] $message: $error');
    }
  }
}
