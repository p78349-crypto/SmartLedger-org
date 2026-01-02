import 'package:flutter/material.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/store_alias_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/store_memo_utils.dart';

class StoreMergeScreen extends StatefulWidget {
  const StoreMergeScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<StoreMergeScreen> createState() => _StoreMergeScreenState();
}

class _StoreMergeScreenState extends State<StoreMergeScreen> {
  static const int _maxTxScan = 1500;

  bool _isLoading = true;
  List<_StoreCount> _stores = const <_StoreCount>[];
  Map<String, String> _aliasMap = const <String, String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _startOfLookback() {
    final now = DateTime.now();
    return now.subtract(const Duration(days: 183));
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final scanStart = _startOfLookback();

    await TransactionService().loadTransactions();
    final all = List<Transaction>.from(
      TransactionService().getTransactions(widget.accountName),
    )..sort((a, b) => b.date.compareTo(a.date));

    final limited = all.take(_maxTxScan);
    final txs = limited.where((t) => !t.date.isBefore(scanStart));

    final counts = <String, int>{};
    for (final t in txs) {
      final store = _rawStoreKeyOf(t);
      if (store == null) continue;
      counts[store] = (counts[store] ?? 0) + 1;
    }

    final aliasMap = await StoreAliasService.loadMap(widget.accountName);

    final stores = counts.entries
        .map((e) => _StoreCount(store: e.key, count: e.value))
        .toList(growable: false)
      ..sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        if (byCount != 0) return byCount;
        return a.store.compareTo(b.store);
      });

    if (!mounted) return;
    setState(() {
      _stores = stores;
      _aliasMap = aliasMap;
      _isLoading = false;
    });
  }

  String? _rawStoreKeyOf(Transaction t) {
    final store = t.store?.trim();
    if (store != null && store.isNotEmpty) return store;
    return StoreMemoUtils.extractStoreKey(t.memo);
  }

  String _canonicalOf(String raw) {
    return StoreAliasService.resolve(raw, _aliasMap);
  }

  Future<void> _editAlias(_StoreCount item) async {
    final alias = item.store;
    final currentCanonical = _aliasMap[alias];

    final controller = TextEditingController(text: currentCanonical ?? '');

    final candidates = _stores
        .where((e) => e.store != alias)
        .take(12)
        .map((e) => e.store)
        .toList(growable: false);

    if (!mounted) {
      controller.dispose();
      return;
    }

    final result = await showDialog<_StoreMergeDialogResult>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(alias),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('대표 마트명을 입력/선택하세요.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '대표 마트명',
                  border: OutlineInputBorder(),
                ),
              ),
              if (candidates.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in candidates)
                      ActionChip(
                        label: Text(c),
                        onPressed: () {
                          controller.text = c;
                          controller.selection = TextSelection.collapsed(
                            offset: controller.text.length,
                          );
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('취소'),
            ),
            if (currentCanonical != null)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    const _StoreMergeDialogResult(remove: true),
                  );
                },
                child: const Text('해제'),
              ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  _StoreMergeDialogResult(
                    canonical: controller.text.trim(),
                  ),
                );
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (result == null) return;

    if (result.remove) {
      await StoreAliasService.removeAlias(
        widget.accountName,
        alias: alias,
      );
    } else {
      await StoreAliasService.setAlias(
        widget.accountName,
        alias: alias,
        canonical: result.canonical ?? '',
      );
    }

    await _load();

    if (!mounted) return;
    final canonNow = _canonicalOf(alias);
    final message = canonNow == alias
        ? '병합 해제됨'
        : '대표 마트명: $canonNow';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('마트명 병합/정리'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(IconCatalog.refresh),
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '최근 6개월(최대 $_maxTxScan건) 기준으로 마트명을 정리합니다.\n'
                        '별칭을 대표 마트명으로 병합하면 통계/추천에서 대표명 기준으로 집계됩니다.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_stores.isEmpty)
                    Text(
                      '최근 6개월 내 마트명이 있는 거래가 없습니다.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ..._stores.map((item) {
                      final canonical = _canonicalOf(item.store);
                      final mapped = _aliasMap.containsKey(item.store) &&
                          canonical != item.store;
                      final subtitle = mapped
                          ? '최근 6개월 ${item.count}건 · 대표: $canonical'
                          : '최근 6개월 ${item.count}건';
                      return Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: ListTile(
                          title: Text(item.store),
                          subtitle: Text(subtitle),
                          trailing: const Icon(IconCatalog.editOutlined),
                          onTap: () => _editAlias(item),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}

class _StoreCount {
  const _StoreCount({required this.store, required this.count});

  final String store;
  final int count;
}

class _StoreMergeDialogResult {
  const _StoreMergeDialogResult({this.canonical, this.remove = false});

  final String? canonical;
  final bool remove;
}

