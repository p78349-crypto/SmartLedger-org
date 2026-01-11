import 'dart:async';

import '../models/visit_price_entry.dart';

/// 실방문 가격 저장소 (인메모리 캐시 + 이벤트 스트림)
class VisitPriceRepository {
  VisitPriceRepository._();

  static final VisitPriceRepository instance = VisitPriceRepository._();

  final _entriesByKey = <String, List<VisitPriceEntry>>{};
  final _eventController = StreamController<VisitPriceEvent>.broadcast();

  Stream<VisitPriceEvent> get events => _eventController.stream;

  /// 최근 입력값을 최신 순으로 정렬한 리스트 반환
  List<VisitPriceEntry> getRecentEntries({
    required String skuId,
    String? storeId,
    Duration within = const Duration(days: 7),
  }) {
    final now = DateTime.now();
    final result = <VisitPriceEntry>[];
    _entriesByKey.forEach((key, entries) {
      if (!key.contains('#$skuId')) return;
      if (storeId != null && !key.startsWith('${storeId}_')) return;
      for (final entry in entries) {
        if (now.difference(entry.capturedAt) <= within) {
          result.add(entry);
        }
      }
    });
    result.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return result;
  }

  /// 가장 최신의 사용자 우선 가격 반환 (없으면 null)
  VisitPriceEntry? getLatestEffective({
    required String skuId,
    required String storeId,
  }) {
    final entries = _entriesByKey[_composeKey(storeId, skuId)];
    if (entries == null || entries.isEmpty) return null;
    entries.sort(_prioritySort); // 우선순위 + 최신순
    return entries.first;
  }

  Future<void> upsert(VisitPriceEntry entry) async {
    final key = _composeKey(entry.storeId, entry.skuId);
    final entries = _entriesByKey.putIfAbsent(key, () => <VisitPriceEntry>[]);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    entries.sort(_prioritySort);
    _eventController.add(VisitPriceEvent(entry: entry));
  }

  /// 외부에서 공식 API 가격을 저장할 때 사용
  Future<void> saveOfficialBaseline(VisitPriceEntry baseline) {
    final entry = baseline.copyWith(source: VisitPriceSource.officialBaseline);
    return upsert(entry);
  }

  Future<void> addCrowdEntry(VisitPriceEntry entry) {
    final updated = entry.copyWith(source: VisitPriceSource.crowdContribution);
    return upsert(updated);
  }

  Future<void> addUserEntry(VisitPriceEntry entry) {
    final updated = entry.copyWith(source: VisitPriceSource.userReceipt);
    return upsert(updated);
  }

  void dispose() {
    _eventController.close();
  }

  String _composeKey(String storeId, String skuId) => '${storeId}_#$skuId';

  int _prioritySort(VisitPriceEntry a, VisitPriceEntry b) {
    final priority = _priorityScore(
      b.source,
    ).compareTo(_priorityScore(a.source));
    if (priority != 0) return priority;
    return b.capturedAt.compareTo(a.capturedAt);
  }

  int _priorityScore(VisitPriceSource source) {
    switch (source) {
      case VisitPriceSource.userReceipt:
        return 3;
      case VisitPriceSource.crowdContribution:
        return 2;
      case VisitPriceSource.officialBaseline:
        return 1;
    }
  }
}

class VisitPriceEvent {
  final VisitPriceEntry entry;

  const VisitPriceEvent({required this.entry});
}
