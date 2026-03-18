import 'package:flutter/material.dart';
import '../models/trash_entry.dart';
import '../services/trash_service.dart';
import '../utils/utils.dart';
import 'trash_screen_restore.dart';
import 'trash_screen_widgets.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen>
    with TrashScreenRestoreMixin {
  bool _loading = true;
  List<TrashEntry> _entries = const [];
  TrashEntityType? _filterType;

  @override
  void initState() {
    super.initState();
    loadEntries();
  }

  @override
  Future<void> loadEntries() async {
    setState(() => _loading = true);
    await TrashService().loadEntries();
    final entries = TrashService().getEntries(entityType: _filterType);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
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
      await loadEntries();
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
      await loadEntries();
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '휴지통이 비워졌습니다.');
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
        onRefresh: loadEntries,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
            ? const Center(child: Text('휴지통이 비어 있습니다.'))
            : _buildList(isLandscape),
      ),
    );
  }

  Widget _buildList(bool isLandscape) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader(isLandscape);
        return _buildEntryCard(_entries[index - 1], isLandscape);
      },
    );
  }

  Widget _buildHeader(bool isLandscape) {
    final chips = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TrashFilterChips(
        filterType: _filterType,
        onChanged: (type) {
          setState(() => _filterType = type);
          loadEntries();
        },
      ),
    );

    if (!isLandscape) return chips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [chips, const TrashLandscapeHeader(), const Divider(height: 1)],
    );
  }

  Widget _buildEntryCard(TrashEntry entry, bool isLandscape) {
    final deletedAtStr = DateFormatter.formatDateTime(entry.deletedAt);
    final trailingActions = Wrap(
      spacing: 4,
      children: [
        IconButton(
          icon: const Icon(Icons.settings_backup_restore),
          tooltip: '복원',
          onPressed: () => restoreEntry(entry),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(iconForType(entry.entityType)),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Text(
                      titleForEntry(entry),
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
              leading: Icon(iconForType(entry.entityType)),
              title: Text(titleForEntry(entry)),
              subtitle: Text(
                '계정: ${entry.accountName}\n'
                '삭제 시각: $deletedAtStr',
              ),
              isThreeLine: true,
              trailing: trailingActions,
            ),
    );
  }
}
