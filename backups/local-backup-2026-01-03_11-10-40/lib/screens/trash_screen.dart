import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smart_ledger/models/account.dart';
import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/models/trash_entry.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/asset_service.dart';
import 'package:smart_ledger/services/backup_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/services/trash_service.dart';
import 'package:smart_ledger/utils/account_name_language_tag.dart';
import 'package:smart_ledger/utils/utils.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  bool _loading = true;
  List<TrashEntry> _entries = const [];
  TrashEntityType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    await TrashService().loadEntries();
    final entries = TrashService().getEntries(entityType: _filterType);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _restoreEntry(TrashEntry entry) async {
    switch (entry.entityType) {
      case TrashEntityType.transaction:
        await _restoreTransaction(entry);
        break;
      case TrashEntityType.asset:
        await _restoreAsset(entry);
        break;
      case TrashEntityType.account:
        await _restoreAccount(entry);
        break;
    }
  }

  Future<void> _restoreTransaction(TrashEntry entry) async {
    try {
      final accountName = entry.accountName;
      final accountService = AccountService();
      await accountService.loadAccounts();
      if (accountService.getAccountByName(accountName) == null) {
        final added = await accountService.addAccount(
          Account(name: accountName),
        );
        if (!added) {
          if (!mounted) return;
          SnackbarUtils.showError(context, '계정을 생성할 수 없습니다: $accountName');
          return;
        }
      }
      final transaction = Transaction.fromJson(entry.payload);
      await TransactionService().addTransaction(accountName, transaction);
      await TrashService().removeEntry(entry.id);
      await _loadEntries();
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '거래가 복원되었습니다.');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '거래 복원 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _restoreAsset(TrashEntry entry) async {
    try {
      final accountName = entry.accountName;
      final accountService = AccountService();
      await accountService.loadAccounts();
      if (accountService.getAccountByName(accountName) == null) {
        final added = await accountService.addAccount(
          Account(name: accountName),
        );
        if (!added) {
          if (!mounted) return;
          SnackbarUtils.showError(context, '계정을 생성할 수 없습니다: $accountName');
          return;
        }
      }
      final asset = Asset.fromJson(entry.payload);
      await AssetService().addAsset(accountName, asset);
      await TrashService().removeEntry(entry.id);
      await _loadEntries();
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '자산이 복원되었습니다.');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '자산 복원 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _restoreAccount(TrashEntry entry) async {
    final originalName = entry.accountName;
    final controller = TextEditingController(text: originalName);
    String? confirmedName;
    try {
      confirmedName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('계정 복원'),
          content: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final locale = Localizations.localeOf(ctx);
              final suffix = AccountNameLanguageTag.suffixForLocale(locale);
              final baseName = value.text.trim();
              final finalName = AccountNameLanguageTag.applyForcedSuffix(
                baseName,
                locale,
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('복원할 계정 이름을 입력하세요.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: '계정명'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '언어 태그가 강제 삽입됩니다: $suffix',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                    ),
                  ),
                  if (baseName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '최종 계정명: $finalName',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final baseName = controller.text.trim();
                if (baseName.isNotEmpty) {
                  final locale = Localizations.localeOf(ctx);
                  final finalName = AccountNameLanguageTag.applyForcedSuffix(
                    baseName,
                    locale,
                  );
                  Navigator.of(ctx).pop(finalName);
                }
              },
              child: const Text('복원'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
    if (!mounted) return;
    if (confirmedName == null || confirmedName.isEmpty) {
      return;
    }
    final accountService = AccountService();
    await accountService.loadAccounts();
    if (accountService.getAccountByName(confirmedName) != null) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '이미 존재하는 계정입니다: $confirmedName');
      return;
    }
    try {
      final snapshot = Map<String, dynamic>.from(entry.payload);

      // Always restore as a NEW account (no overwrite/merge).
      final encoded = jsonEncode(snapshot);
      await BackupService().importAccountDataAsNew(encoded, confirmedName);
      await TrashService().removeEntry(entry.id);
      await _loadEntries();
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '$confirmedName 계정이 복원되었습니다.');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '계정 복원 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _purgeEntry(TrashEntry entry) async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: '영구 삭제',
      message: '선택한 항목을 영구 삭제할까요? 복원할 수 없습니다.',
      confirmText: '삭제',
      isDangerous: true,
    );
    if (confirmed) {
      await TrashService().removeEntry(entry.id);
      await _loadEntries();
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '휴지통에서 삭제되었습니다.');
    }
  }

  Future<void> _purgeAll() async {
    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: '휴지통 비우기',
      message: '휴지통을 완전히 비울까요? 삭제된 항목은 복원할 수 없습니다.',
      confirmText: '비우기',
      isDangerous: true,
    );
    if (confirmed) {
      await TrashService().purgeAll();
      await _loadEntries();
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '휴지통이 비워졌습니다.');
    }
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('전체'),
          selected: _filterType == null,
          onSelected: (_) {
            setState(() => _filterType = null);
            _loadEntries();
          },
        ),
        for (final type in TrashEntityType.values)
          FilterChip(
            label: Text(_labelForType(type)),
            selected: _filterType == type,
            onSelected: (_) {
              setState(() => _filterType = type);
              _loadEntries();
            },
          ),
      ],
    );
  }

  String _labelForType(TrashEntityType type) {
    switch (type) {
      case TrashEntityType.transaction:
        return '거래';
      case TrashEntityType.asset:
        return '자산';
      case TrashEntityType.account:
        return '계정';
    }
  }

  IconData _iconForType(TrashEntityType type) {
    switch (type) {
      case TrashEntityType.transaction:
        return Icons.receipt_long;
      case TrashEntityType.asset:
        return Icons.account_balance_wallet;
      case TrashEntityType.account:
        return Icons.admin_panel_settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('휴지통'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '휴지통 비우기',
            onPressed: _entries.isEmpty ? null : _purgeAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
            ? const Center(child: Text('휴지통이 비어 있습니다.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _entries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final chips = Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildFilterChips(),
                    );

                    if (!isLandscape) return chips;

                    const headerStyle = TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        chips,
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 24),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 6,
                                child: Text(
                                  '항목',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: headerStyle,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '계정',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: headerStyle,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  '삭제 시각',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: headerStyle,
                                ),
                              ),
                              SizedBox(width: 80),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  }
                  final entry = _entries[index - 1];
                  final deletedAtStr = DateFormatter.formatDateTime(
                    entry.deletedAt,
                  );

                  final trailingActions = Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings_backup_restore),
                        tooltip: '복원',
                        onPressed: () => _restoreEntry(entry),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '영구 삭제',
                        onPressed: () => _purgeEntry(entry),
                      ),
                    ],
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: isLandscape
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(_iconForType(entry.entityType)),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    _titleForEntry(entry),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    entry.accountName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    deletedAtStr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailingActions,
                              ],
                            ),
                          )
                        : ListTile(
                            leading: Icon(_iconForType(entry.entityType)),
                            title: Text(_titleForEntry(entry)),
                            subtitle: Text(
                              '계정: ${entry.accountName}\n'
                              '삭제 시각: $deletedAtStr',
                            ),
                            isThreeLine: true,
                            trailing: trailingActions,
                          ),
                  );
                },
              ),
      ),
    );
  }

  String _titleForEntry(TrashEntry entry) {
    switch (entry.entityType) {
      case TrashEntityType.transaction:
        final tx = Transaction.fromJson(entry.payload);
        final amount = CurrencyFormatter.format(tx.amount, showUnit: false);
        return '${tx.description} (${tx.type.sign}$amount원)';
      case TrashEntityType.asset:
        final asset = Asset.fromJson(entry.payload);
        return '${asset.name} (${CurrencyFormatter.format(asset.amount)})';
      case TrashEntityType.account:
        return '${entry.accountName} 계정 백업';
    }
  }
}
