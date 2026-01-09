import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/asset.dart';
import 'asset_move_service.dart';
import 'trash_service.dart';

class AssetService {
  static final AssetService _instance = AssetService._internal();
  factory AssetService() => _instance;
  AssetService._internal();

  static const String _prefsKey = 'assets';

  final Map<String, List<Asset>> _accountAssets = {};
  bool _initialized = false;
  Future<void>? _loading;

  Future<void> loadAssets() {
    if (_initialized) {
      return Future.value();
    }
    _loading ??= _doLoad();
    return _loading!;
  }

  List<Asset> getAssets(String accountName) {
    final list = _accountAssets[accountName];
    if (list == null) {
      return const <Asset>[];
    }
    return List.unmodifiable(list);
  }

  List<String> getTrackedAccountNames() {
    return List.unmodifiable(_accountAssets.keys);
  }

  Future<void> addAsset(String accountName, Asset asset) async {
    await loadAssets();
    final list = _accountAssets.putIfAbsent(accountName, () => []);
    list.add(asset);

    // 투자 목표 달성 확인 및 자동 전환
    await _checkAndConvertInvestments(accountName);

    await _persist();
  }

  Future<bool> updateAsset(String accountName, Asset updated) async {
    await loadAssets();
    final list = _accountAssets[accountName];
    if (list == null) {
      return false;
    }
    final index = list.indexWhere((asset) => asset.id == updated.id);
    if (index == -1) {
      return false;
    }
    list[index] = updated;

    // 투자 목표 달성 확인 및 자동 전환
    await _checkAndConvertInvestments(accountName);

    await _persist();
    return true;
  }

  Future<bool> deleteAsset(
    String accountName,
    String assetId, {
    bool moveToTrash = true,
  }) async {
    await loadAssets();
    final list = _accountAssets[accountName];
    if (list == null) {
      return false;
    }
    final index = list.indexWhere((asset) => asset.id == assetId);
    if (index == -1) {
      return false;
    }
    final removed = list.removeAt(index);
    if (moveToTrash) {
      await TrashService().addAsset(accountName, removed);
    }

    // Keep move timelines consistent by removing orphaned moves.
    await AssetMoveService().purgeMovesForAsset(accountName, assetId);

    await _persist();
    return true;
  }

  Future<void> replaceAssets(String accountName, List<Asset> assets) async {
    await loadAssets();
    _accountAssets[accountName] = List<Asset>.from(assets);
    await _persist();
  }

  Future<void> deleteAccount(String accountName) async {
    await loadAssets();
    if (_accountAssets.remove(accountName) != null) {
      await _persist();
    }
  }

  Future<void> _doLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(raw) as Map<String, dynamic>;
        var needsPersist = false;
        _accountAssets
          ..clear()
          ..addAll(
            data.map(
              (key, value) => MapEntry(
                key,
                (value as List<dynamic>).map((item) {
                  final map = item as Map<String, dynamic>;
                  final hasId = (map['id'] as String?)?.isNotEmpty ?? false;
                  final asset = Asset.fromJson(map);
                  if (!hasId) {
                    needsPersist = true;
                  }
                  return asset;
                }).toList(),
              ),
            ),
          );
        if (needsPersist) {
          await _persist();
        }
      } catch (_) {
        _accountAssets.clear();
      }
    }
    _initialized = true;
    _loading = null;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _accountAssets.map(
      (key, value) =>
          MapEntry(key, value.map((asset) => asset.toJson()).toList()),
    );
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  /// 투자 자산이 목표액에 도달하면 자동으로 전환
  Future<void> _checkAndConvertInvestments(String accountName) async {
    final list = _accountAssets[accountName];
    if (list == null) return;

    for (int i = 0; i < list.length; i++) {
      final asset = list[i];

      // 투자 중이고, 목표액이 있고, 아직 전환되지 않은 자산
      if (asset.isInvestment &&
          asset.targetAmount != null &&
          asset.targetAmount! > 0 &&
          asset.conversionDate == null) {
        // 목표액 달성 확인
        if (asset.amount >= asset.targetAmount!) {
          // 자산으로 전환 (투자 상태 해제 및 전환 날짜 기록)
          list[i] = asset.copyWith(
            isInvestment: false,
            conversionDate: DateTime.now(),
            memo: asset.memo.isEmpty
                ? '목표액 달성으로 자산으로 전환 (${asset.targetAmount}원)'
                : '${asset.memo}\n→ 목표액 달성으로 자산으로 전환 (${asset.targetAmount}원)',
          );
        }
      }
    }
  }
}
