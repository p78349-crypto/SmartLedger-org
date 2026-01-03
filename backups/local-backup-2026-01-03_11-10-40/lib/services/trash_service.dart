import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/models/trash_entry.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

class TrashService {
  static final TrashService _instance = TrashService._internal();
  factory TrashService() => _instance;
  TrashService._internal();

  static String get _prefsKey => PrefKeys.trash;
  static const int _maxTotalBytes = 60 * 1024 * 1024; // 60MB

  final List<TrashEntry> _entries = [];
  bool _initialized = false;
  Future<void>? _loading;

  List<TrashEntry> get entries => List.unmodifiable(_entries);

  Future<void> loadEntries() {
    if (_initialized) {
      return Future.value();
    }
    _loading ??= _doLoad();
    return _loading!;
  }

  List<TrashEntry> getEntries({
    String? accountName,
    TrashEntityType? entityType,
  }) {
    return _entries.where((entry) {
      final accountMatches =
          accountName == null || entry.accountName == accountName;
      final typeMatches = entityType == null || entry.entityType == entityType;
      return accountMatches && typeMatches;
    }).toList()..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
  }

  TrashEntry? getEntryById(String id) {
    try {
      return _entries.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<TrashEntry> addTransaction(
    String accountName,
    Transaction transaction,
  ) async {
    final payload = transaction.toJson()..addAll({'accountName': accountName});
    final entry = TrashEntry.forPayload(
      id: _generateEntryId(),
      entityId: transaction.id,
      accountName: accountName,
      entityType: TrashEntityType.transaction,
      payload: payload,
    );
    await _addEntry(entry);
    return entry;
  }

  Future<TrashEntry> addAsset(String accountName, Asset asset) async {
    final payload = asset.toJson()..addAll({'accountName': accountName});
    final entry = TrashEntry.forPayload(
      id: _generateEntryId(),
      entityId: asset.id,
      accountName: accountName,
      entityType: TrashEntityType.asset,
      payload: payload,
    );
    await _addEntry(entry);
    return entry;
  }

  Future<TrashEntry> addAccountSnapshot({
    required String accountName,
    required Map<String, dynamic> snapshot,
  }) async {
    final entry = TrashEntry.forPayload(
      id: _generateEntryId(),
      entityId: accountName,
      accountName: accountName,
      entityType: TrashEntityType.account,
      payload: snapshot,
    );
    await _addEntry(entry);
    return entry;
  }

  Future<bool> removeEntry(String entryId) async {
    await loadEntries();
    final beforeLength = _entries.length;
    _entries.removeWhere((element) => element.id == entryId);
    final removed = _entries.length < beforeLength;
    if (removed) {
      await _persist();
    }
    return removed;
  }

  Future<void> purgeEntries(List<String> entryIds) async {
    await loadEntries();
    _entries.removeWhere((element) => entryIds.contains(element.id));
    await _persist();
  }

  Future<void> purgeAll() async {
    await loadEntries();
    _entries.clear();
    await _persist();
  }

  Future<void> purgeAccount(String accountName) async {
    await loadEntries();
    final before = _entries.length;
    _entries.removeWhere((e) => e.accountName == accountName);
    if (_entries.length != before) {
      await _persist();
    }
  }

  Future<void> replaceAccountEntries(
    String accountName,
    List<TrashEntry> entries,
  ) async {
    await loadEntries();
    _entries.removeWhere((e) => e.accountName == accountName);
    _entries.addAll(entries);
    _entries.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    await _enforceSizeLimit();
    await _persist();
  }

  Future<void> _addEntry(TrashEntry entry) async {
    await loadEntries();
    _entries.add(entry);
    _entries.sort((a, b) => a.deletedAt.compareTo(b.deletedAt));
    await _enforceSizeLimit();
    await _persist();
  }

  Future<void> _enforceSizeLimit() async {
    var totalBytes = _entries.fold<int>(
      0,
      (sum, entry) => sum + entry.sizeBytes,
    );
    if (totalBytes <= _maxTotalBytes) {
      return;
    }
    _entries.sort((a, b) => a.deletedAt.compareTo(b.deletedAt));
    while (_entries.isNotEmpty && totalBytes > _maxTotalBytes) {
      final removed = _entries.removeAt(0);
      totalBytes -= removed.sizeBytes;
    }
  }

  Future<void> _doLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
        _entries
          ..clear()
          ..addAll(
            data
                .map(
                  (item) => TrashEntry.fromJson(item as Map<String, dynamic>),
                )
                .toList(),
          );
        _entries.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
      } catch (_) {
        _entries.clear();
      }
    }
    _initialized = true;
    _loading = null;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _entries.map((entry) => entry.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  String _generateEntryId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
