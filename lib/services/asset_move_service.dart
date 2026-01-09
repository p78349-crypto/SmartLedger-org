import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset_move.dart';

/// 자산 이동/전환 기록 관리 서비스
class AssetMoveService {
  static final AssetMoveService _instance = AssetMoveService._internal();
  factory AssetMoveService() => _instance;
  AssetMoveService._internal();

  static const String _prefsKey = 'asset_moves';

  final Map<String, List<AssetMove>> _accountMoves = {};
  bool _initialized = false;
  Future<void>? _loading;

  Future<void> loadMoves() {
    if (_initialized) {
      return Future.value();
    }
    _loading ??= _doLoad();
    return _loading!;
  }

  List<AssetMove> getMoves(String accountName) {
    final list = _accountMoves[accountName];
    if (list == null) {
      return const <AssetMove>[];
    }
    return List.unmodifiable(list);
  }

  /// 특정 자산의 이동 기록(from 또는 to)
  List<AssetMove> getMovesForAsset(String accountName, String assetId) {
    final moves = getMoves(accountName);
    return moves
        .where((m) => m.fromAssetId == assetId || m.toAssetId == assetId)
        .toList();
  }

  /// 날짜 범위로 필터
  List<AssetMove> getMovesByDateRange(
    String accountName,
    DateTime startDate,
    DateTime endDate,
  ) {
    final moves = getMoves(accountName);
    return moves
        .where(
          (m) =>
              m.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              m.date.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();
  }

  /// 이동 기록 추가
  Future<void> addMove(String accountName, AssetMove move) async {
    await loadMoves();
    final list = _accountMoves.putIfAbsent(accountName, () => []);
    list.add(move);
    await _persist();
  }

  Future<void> upsertMove(String accountName, AssetMove move) async {
    await loadMoves();
    final list = _accountMoves.putIfAbsent(accountName, () => []);
    final index = list.indexWhere((m) => m.id == move.id);
    if (index == -1) {
      list.add(move);
    } else {
      list[index] = move;
    }
    await _persist();
  }

  Future<void> removeMove(String accountName, String moveId) async {
    await loadMoves();
    final list = _accountMoves[accountName];
    if (list == null) return;
    final before = list.length;
    list.removeWhere((m) => m.id == moveId);
    if (list.length != before) {
      await _persist();
    }
  }

  Future<int> purgeMovesForAsset(String accountName, String assetId) async {
    await loadMoves();
    final list = _accountMoves[accountName];
    if (list == null || list.isEmpty) return 0;
    final before = list.length;
    list.removeWhere((m) => m.fromAssetId == assetId || m.toAssetId == assetId);
    final removed = before - list.length;
    if (removed > 0) {
      await _persist();
    }
    return removed;
  }

  /// 계정 삭제 시 해당 이동 기록도 삭제
  Future<void> deleteAccount(String accountName) async {
    await loadMoves();
    if (_accountMoves.remove(accountName) != null) {
      await _persist();
    }
  }

  Future<void> replaceMoves(String accountName, List<AssetMove> moves) async {
    await loadMoves();
    _accountMoves[accountName] = List<AssetMove>.from(moves);
    await _persist();
  }

  Future<void> _doLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(raw) as Map<String, dynamic>;
        _accountMoves
          ..clear()
          ..addAll(
            data.map(
              (key, value) => MapEntry(
                key,
                (value as List<dynamic>)
                    .map(
                      (item) =>
                          AssetMove.fromJson(item as Map<String, dynamic>),
                    )
                    .toList(),
              ),
            ),
          );
      } catch (_) {
        _accountMoves.clear();
      }
    }
    _initialized = true;
    _loading = null;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _accountMoves.map(
      (key, value) =>
          MapEntry(key, value.map((move) => move.toJson()).toList()),
    );
    await prefs.setString(_prefsKey, jsonEncode(data));
  }
}
