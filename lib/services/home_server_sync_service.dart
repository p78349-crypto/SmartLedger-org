import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '../models/fixed_cost.dart';
import '../models/transaction.dart';
import 'asset_service.dart';
import 'fixed_cost_service.dart';
import 'root_memo_service.dart';
import 'transaction_service.dart';
import 'server_config_service.dart';

/// 🏠 홈 서버(WireGuard VPN 내부)와의 데이터 동기화 서비스
class HomeServerSyncService {
  HomeServerSyncService._internal();
  static final HomeServerSyncService _instance = HomeServerSyncService._internal();
  factory HomeServerSyncService() => _instance;

  static const String _pullPath = '/api/ledger/sync/pull';
  static const String _pushBasePath = '/api/ledger/sync/push';
  static const String _lastPullKeyPrefix = 'home_server_last_pull_ms_';
  static const String _lastPushKeyPrefix = 'home_server_last_push_ms_';

  static const String tableTransactions = 'transactions';
  static const String tableAssets = 'assets';
  static const String tableFixedCosts = 'fixed-costs';
  static const String tableMemos = 'memos';

  /// 홈 서버 가용 여부 확인 (VPN 연결 상태 체크 대용)
  Future<bool> isServerAvailable() async {
    final serverConfigService = ServerConfigService();
    return await serverConfigService.checkHealth();
  }

  /// 특정 계정의 거래 내역을 홈 서버로 전송
  Future<SyncResult> syncTransactions(String accountName) async {
    return pushTableDelta(accountName, tableTransactions);
  }

  /// 서버 변경분(Delta) Pull 후 로컬 DB/저장소에 병합(Upsert)
  Future<SyncResult> pullLatestDelta(String accountName) async {
    if (!await isServerAvailable()) {
      return SyncResult.failed('홈 서버에 연결할 수 없습니다. VPN 상태를 확인하세요.');
    }

    final serverConfigService = ServerConfigService();
    final serverUrl = await serverConfigService.getServerAddress();
    if (serverUrl == null || serverUrl.isEmpty) {
      return SyncResult.failed('서버 주소가 설정되지 않았습니다.');
    }

    final prefs = await SharedPreferences.getInstance();
    final lastPullMs = prefs.getInt('$_lastPullKeyPrefix$accountName') ?? 0;
    final lastPullIso = DateTime.fromMillisecondsSinceEpoch(
      lastPullMs,
      isUtc: true,
    ).toIso8601String();

    try {
      final headers = await serverConfigService.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse(
              '$serverUrl$_pullPath?last_updated=${Uri.encodeQueryComponent(lastPullIso)}',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return SyncResult.failed('Pull 응답 오류 (HTTP ${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return SyncResult.failed('Pull 응답 형식이 올바르지 않습니다.');
      }

      final txItems = _extractList(decoded, const [
        'transactions',
        'tx',
        'ledger_transactions',
      ]);
      final assetItems = _extractList(decoded, const ['assets']);
      final fixedCostItems = _extractList(decoded, const [
        'fixed_costs',
        'fixedCosts',
      ]);
      final memoItems = _extractList(decoded, const ['memos', 'root_memos']);

      int mergedCount = 0;
      mergedCount += await _mergeTransactions(accountName, txItems);
      mergedCount += await _mergeAssets(accountName, assetItems);
      mergedCount += await _mergeFixedCosts(accountName, fixedCostItems);
      mergedCount += await _mergeRootMemos(memoItems);

      final serverNow = _extractServerUpdatedAt(decoded);
      await prefs.setInt(
        '$_lastPullKeyPrefix$accountName',
        (serverNow ?? DateTime.now()).millisecondsSinceEpoch,
      );

      return SyncResult.success(mergedCount, 'Pull 동기화 완료 ($mergedCount건 병합)');
    } catch (e) {
      return SyncResult.failed('Pull 동기화 중 오류 발생: $e');
    }
  }

  /// 테이블별 변경분 Push
  Future<SyncResult> pushTableDelta(String accountName, String tableName) async {
    if (!await isServerAvailable()) {
      return SyncResult.failed('홈 서버에 연결할 수 없습니다. VPN 상태를 확인하세요.');
    }

    final serverConfigService = ServerConfigService();
    final serverUrl = await serverConfigService.getServerAddress();
    if (serverUrl == null || serverUrl.isEmpty) {
      return SyncResult.failed('서버 주소가 설정되지 않았습니다.');
    }

    final normalizedTable = _normalizeTableName(tableName);
    if (normalizedTable.isEmpty) {
      return SyncResult.failed('테이블 이름이 비어 있습니다.');
    }

    final prefs = await SharedPreferences.getInstance();
    final lastPushKey = '$_lastPushKeyPrefix${normalizedTable}_$accountName';
    final lastPushMs = prefs.getInt(lastPushKey) ?? 0;
    final lastPushAt = DateTime.fromMillisecondsSinceEpoch(lastPushMs);

    final items = await _buildPushItems(
      accountName: accountName,
      tableName: normalizedTable,
      lastPushAt: lastPushAt,
    );

    if (items.isEmpty) {
      return SyncResult.success(0, 'Push할 변경분이 없습니다.');
    }

    try {
      final headers = await serverConfigService.getAuthHeaders();
      final payload = <String, dynamic>{
        'accountName': accountName,
        'last_updated': lastPushAt.toUtc().toIso8601String(),
        'items': items,
      };

      final response = await http
          .post(
            Uri.parse('$serverUrl$_pushBasePath/$normalizedTable'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt(lastPushKey, nowMs);
        return SyncResult.success(items.length, 'Push 동기화 완료 (${items.length}건 전송)');
      }

      return SyncResult.failed('Push 응답 오류 (HTTP ${response.statusCode})');
    } catch (e) {
      return SyncResult.failed('Push 동기화 중 오류 발생: $e');
    }
  }

  Future<SyncResult> pushAssets(String accountName) {
    return pushTableDelta(accountName, tableAssets);
  }

  Future<SyncResult> pushFixedCosts(String accountName) {
    return pushTableDelta(accountName, tableFixedCosts);
  }

  Future<SyncResult> pushMemos(String accountName) {
    return pushTableDelta(accountName, tableMemos);
  }

  /// 계정 단위 전체 동기화: Push(각 테이블) 후 Pull(Delta 병합)
  Future<SyncBatchResult> syncAllForAccount(String accountName) async {
    final pushTransactions = await pushTableDelta(accountName, tableTransactions);
    final pushAssets = await pushTableDelta(accountName, tableAssets);
    final pushFixedCosts = await pushTableDelta(accountName, tableFixedCosts);
    final pushMemos = await pushTableDelta(accountName, tableMemos);
    final pullResult = await pullLatestDelta(accountName);

    final all = [
      pushTransactions,
      pushAssets,
      pushFixedCosts,
      pushMemos,
      pullResult,
    ];
    final hasFailure = all.any((r) => !r.isSuccess);
    final mergedCount = all.fold<int>(0, (sum, r) => sum + r.count);

    if (hasFailure) {
      final failedMessages = all
          .where((r) => !r.isSuccess)
          .map((r) => r.message)
          .join(' | ');
      return SyncBatchResult(
        isSuccess: false,
        count: mergedCount,
        message: '일부 동기화 실패: $failedMessages',
      );
    }

    return SyncBatchResult(
      isSuccess: true,
      count: mergedCount,
      message: '전체 동기화 완료 (처리합계 $mergedCount건)',
    );
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> payload,
    List<String> keys,
  ) {
    for (final key in keys) {
      final raw = payload[key];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList();
      }
    }
    return const <Map<String, dynamic>>[];
  }

  DateTime? _extractServerUpdatedAt(Map<String, dynamic> payload) {
    final candidates = [
      payload['serverTime'],
      payload['lastUpdated'],
      payload['last_updated'],
    ];
    for (final raw in candidates) {
      if (raw is String && raw.isNotEmpty) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Future<int> _mergeTransactions(
    String accountName,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return 0;
    final service = TransactionService();
    await service.loadTransactions();
    final existing = service.getTransactions(accountName);
    final existingIds = existing.map((e) => e.id).toSet();

    var merged = 0;
    for (final row in rows) {
      if (!_matchesAccount(row, accountName)) {
        continue;
      }
      final normalized = _normalizeTransactionRow(row);
      final tx = Transaction.fromJson(normalized);
      final isDeleted = _isDeleted(row);
      if (isDeleted) {
        if (existingIds.contains(tx.id)) {
          await service.deleteTransaction(
            accountName,
            tx.id,
            moveToTrash: false,
          );
          existingIds.remove(tx.id);
          merged += 1;
        }
        continue;
      }
      if (existingIds.contains(tx.id)) {
        await service.updateTransaction(accountName, tx);
      } else {
        await service.addTransaction(accountName, tx);
        existingIds.add(tx.id);
      }
      merged += 1;
    }
    return merged;
  }

  Future<int> _mergeAssets(
    String accountName,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return 0;
    final service = AssetService();
    await service.loadAssets();
    final current = service.getAssets(accountName);
    final mergedById = <String, Asset>{for (final a in current) a.id: a};
    for (final row in rows) {
      if (!_matchesAccount(row, accountName)) {
        continue;
      }
      final normalized = _normalizeAssetRow(row);
      final asset = Asset.fromJson(normalized);
      if (_isDeleted(row)) {
        mergedById.remove(asset.id);
        continue;
      }
      mergedById[asset.id] = asset;
    }
    await service.replaceAssets(accountName, mergedById.values.toList());
    return rows.length;
  }

  Future<int> _mergeFixedCosts(
    String accountName,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return 0;
    final service = FixedCostService();
    await service.loadFixedCosts();
    final current = service.getFixedCosts(accountName);
    final mergedById = <String, FixedCost>{for (final c in current) c.id: c};
    for (final row in rows) {
      if (!_matchesAccount(row, accountName)) {
        continue;
      }
      final normalized = _normalizeFixedCostRow(row);
      final cost = FixedCost.fromJson(normalized);
      if (_isDeleted(row)) {
        mergedById.remove(cost.id);
        continue;
      }
      mergedById[cost.id] = cost;
    }
    await service.replaceFixedCosts(accountName, mergedById.values.toList());
    return rows.length;
  }

  Future<int> _mergeRootMemos(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return 0;
    final service = RootMemoService.getInstance();
    await service.loadMemos();
    final current = service.getAllMemos();
    final mergedById = <String, RootMemo>{for (final m in current) m.id: m};

    for (final row in rows) {
      final incoming = RootMemo.fromJson(_normalizeMemoRow(row));
      if (_isDeleted(row)) {
        mergedById.remove(incoming.id);
        continue;
      }
      final existing = mergedById[incoming.id];
      if (existing == null || incoming.updatedAt.isAfter(existing.updatedAt)) {
        mergedById[incoming.id] = incoming;
      }
    }

    await service.importData({
      'memos': mergedById.values.map((m) => m.toJson()).toList(),
      'importedAt': DateTime.now().toIso8601String(),
    });
    return rows.length;
  }

  Future<List<Map<String, dynamic>>> _buildPushItems({
    required String accountName,
    required String tableName,
    required DateTime lastPushAt,
  }) async {
    switch (tableName) {
      case tableTransactions:
        await TransactionService().loadTransactions();
        return TransactionService()
            .getTransactions(accountName)
            .where((tx) => tx.date.isAfter(lastPushAt))
            .map(_toServerTransactionRow)
            .toList();
      case tableAssets:
        await AssetService().loadAssets();
        return AssetService()
            .getAssets(accountName)
            .where((asset) => asset.date.isAfter(lastPushAt))
            .map((asset) => _toServerAssetRow(accountName, asset))
            .toList();
      case tableFixedCosts:
        await FixedCostService().loadFixedCosts();
        return FixedCostService()
            .getFixedCosts(accountName)
            .map((cost) => _toServerFixedCostRow(accountName, cost))
            .toList();
      case tableMemos:
        final memoService = RootMemoService.getInstance();
        await memoService.loadMemos();
        return memoService
            .getAllMemos()
            .where((memo) => memo.updatedAt.isAfter(lastPushAt))
            .map(_toServerMemoRow)
            .toList();
      default:
        return const <Map<String, dynamic>>[];
    }
  }

  String _normalizeTableName(String raw) {
    final value = raw.trim().toLowerCase();
    switch (value) {
      case 'fixed_costs':
      case 'fixedcosts':
      case tableFixedCosts:
        return tableFixedCosts;
      case 'root_memos':
      case 'memo':
      case tableMemos:
        return tableMemos;
      case 'transaction':
      case tableTransactions:
        return tableTransactions;
      case 'asset':
      case tableAssets:
        return tableAssets;
      default:
        return value;
    }
  }

  bool _matchesAccount(Map<String, dynamic> row, String accountName) {
    final rowAccountName = (row['account_name'] ?? row['accountName'])
        ?.toString();
    if (rowAccountName == null || rowAccountName.isEmpty) {
      return true;
    }
    return rowAccountName == accountName;
  }

  bool _isDeleted(Map<String, dynamic> row) {
    final raw = row['is_deleted'] ?? row['isDeleted'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      return normalized == '1' || normalized == 'true' || normalized == 'yes';
    }
    return false;
  }

  Map<String, dynamic> _normalizeTransactionRow(Map<String, dynamic> row) {
    final normalized = Map<String, dynamic>.from(row);
    normalized['cardChargedAmount'] = row['card_charged_amount'] ?? row['cardChargedAmount'];
    normalized['unitPrice'] = row['unit_price'] ?? row['unitPrice'];
    normalized['paymentMethod'] = row['payment_method'] ?? row['paymentMethod'];
    normalized['mainCategory'] = row['main_category'] ?? row['mainCategory'];
    normalized['subCategory'] = row['sub_category'] ?? row['subCategory'];
    normalized['detailCategory'] = row['detail_category'] ?? row['detailCategory'];
    normalized['originalTransactionId'] = row['original_transaction_id'] ?? row['originalTransactionId'];
    normalized['isRefund'] = row['is_refund'] ?? row['isRefund'];
    normalized['savingsAllocation'] = row['savings_allocation'] ?? row['savingsAllocation'];
    normalized['benefitJson'] = row['benefit_json'] ?? row['benefitJson'];
    normalized['expiryDate'] = row['expiry_date'] ?? row['expiryDate'];
    final weatherJson = row['weather_json'];
    if (weatherJson is String && weatherJson.isNotEmpty) {
      try {
        normalized['weather'] = jsonDecode(weatherJson);
      } catch (_) {
        // Ignore malformed weather payload.
      }
    }
    return normalized;
  }

  Map<String, dynamic> _normalizeAssetRow(Map<String, dynamic> row) {
    final normalized = Map<String, dynamic>.from(row);
    normalized['targetAmount'] = row['target_amount'] ?? row['targetAmount'];
    normalized['isInvestment'] = row['is_investment'] ?? row['isInvestment'];
    normalized['conversionDate'] = row['conversion_date'] ?? row['conversionDate'];
    normalized['costBasis'] = row['cost_basis'] ?? row['costBasis'];
    normalized['currencyCode'] = row['currency_code'] ?? row['currencyCode'];
    normalized['unitPrice'] = row['unit_price'] ?? row['unitPrice'];
    normalized['monthlyIncome'] = row['monthly_income'] ?? row['monthlyIncome'];
    return normalized;
  }

  Map<String, dynamic> _normalizeFixedCostRow(Map<String, dynamic> row) {
    final normalized = Map<String, dynamic>.from(row);
    normalized['paymentMethod'] = row['payment_method'] ?? row['paymentMethod'];
    normalized['dueDay'] = row['due_day'] ?? row['dueDay'];
    return normalized;
  }

  Map<String, dynamic> _normalizeMemoRow(Map<String, dynamic> row) {
    final normalized = Map<String, dynamic>.from(row);
    normalized['createdAt'] = row['created_at'] ?? row['createdAt'];
    normalized['updatedAt'] = row['updated_at'] ?? row['updatedAt'];
    normalized['isPinned'] = row['is_pinned'] ?? row['isPinned'];
    normalized['sortOrder'] = row['sort_order'] ?? row['sortOrder'];
    return normalized;
  }

  Map<String, dynamic> _toServerTransactionRow(Transaction tx) {
    final base = tx.toJson();
    return {
      'id': tx.id,
      'type': tx.type.name,
      'description': tx.description,
      'amount': tx.amount,
      'card_charged_amount': tx.cardChargedAmount,
      'date': tx.date.toIso8601String(),
      'quantity': tx.quantity,
      'unit_price': tx.unitPrice,
      'payment_method': tx.paymentMethod,
      'memo': tx.memo,
      'store': tx.store,
      'main_category': tx.mainCategory,
      'sub_category': tx.subCategory,
      'detail_category': tx.detailCategory,
      'location': tx.location,
      'supplier': tx.supplier,
      'expiry_date': tx.expiryDate?.toIso8601String(),
      'unit': tx.unit,
      'savings_allocation': tx.savingsAllocation?.name,
      'is_refund': tx.isRefund ? 1 : 0,
      'original_transaction_id': tx.originalTransactionId,
      'benefit_json': tx.benefitJson,
      'weather_json': tx.weather != null ? jsonEncode(tx.weather!.toJson()) : null,
      'created_at': tx.date.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'is_deleted': 0,
      'raw': base,
    };
  }

  Map<String, dynamic> _toServerAssetRow(String accountName, Asset asset) {
    return {
      'id': asset.id,
      'account_name': accountName,
      'name': asset.name,
      'amount': asset.amount,
      'memo': asset.memo,
      'date': asset.date.toIso8601String(),
      'category': asset.category.name,
      'is_investment': asset.isInvestment,
      'target_amount': asset.targetAmount,
      'cost_basis': asset.costBasis,
      'currency_code': asset.currencyCode,
      'unit_price': asset.unitPrice,
      'monthly_income': asset.monthlyIncome,
      'created_at': asset.date.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'is_deleted': 0,
    };
  }

  Map<String, dynamic> _toServerFixedCostRow(
    String accountName,
    FixedCost cost,
  ) {
    return {
      'id': cost.id,
      'account_name': accountName,
      'name': cost.name,
      'amount': cost.amount,
      'vendor': cost.vendor,
      'payment_method': cost.paymentMethod,
      'memo': cost.memo,
      'due_day': cost.dueDay,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'is_deleted': 0,
    };
  }

  Map<String, dynamic> _toServerMemoRow(RootMemo memo) {
    return {
      'id': memo.id,
      'title': memo.title,
      'content': memo.content,
      'is_pinned': memo.isPinned,
      'color': memo.color,
      'created_at': memo.createdAt.toUtc().toIso8601String(),
      'updated_at': memo.updatedAt.toUtc().toIso8601String(),
      'is_deleted': 0,
    };
  }
}

class SyncResult {
  final bool isSuccess;
  final int count;
  final String message;

  SyncResult.success(this.count, this.message) : isSuccess = true;
  SyncResult.failed(this.message) : isSuccess = false, count = 0;
}

class SyncBatchResult {
  final bool isSuccess;
  final int count;
  final String message;

  const SyncBatchResult({
    required this.isSuccess,
    required this.count,
    required this.message,
  });
}
