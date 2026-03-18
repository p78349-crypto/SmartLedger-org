/// WMS 임시저장(Draft) 관리
///
/// 사용 시나리오:
/// - 재고 입력 중 앱 종료 → 자동 저장
/// - 장바구니 자동등록 체크 → 임시 저장
/// - 나중에 일괄 등록
library;

import 'package:flutter/foundation.dart';

import '../models/consumable_inventory_item.dart';
import '../models/wms_inventory_draft_entry.dart';
import '../services/user_pref_service.dart';
import 'app_logger.dart';
import 'wms_data_gateway.dart';

/// WMS 임시저장 관리자
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
      AppLogger.info('[WMS Draft][READ] $message');
    }
  }

  void _logWrite(String message) {
    if (kDebugMode) {
      AppLogger.info('[WMS Draft][WRITE] $message');
    }
  }

  void _logError(String message, Object error) {
    if (kDebugMode) {
      AppLogger.error('[WMS Draft][ERROR] $message', error: error);
    }
  }
}
