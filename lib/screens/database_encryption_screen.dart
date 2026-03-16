import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/db_encryption_key_manager.dart';
import '../utils/icon_catalog.dart';

class DatabaseEncryptionScreen extends StatefulWidget {
  const DatabaseEncryptionScreen({super.key});

  @override
  State<DatabaseEncryptionScreen> createState() => _DatabaseEncryptionScreenState();
}

class _DatabaseEncryptionScreenState extends State<DatabaseEncryptionScreen> {
  String? _key;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final key = await DbEncryptionKeyManager.exportKeyForBackup();
    if (!mounted) return;
    setState(() {
      _key = key;
      _loading = false;
    });
  }

  Future<void> _showExportDialog() async {
    final key = await DbEncryptionKeyManager.exportKeyForBackup();
    if (!mounted) return;

    if (key == null || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('암호화 키를 찾을 수 없습니다.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('데이터베이스 암호화 키'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '경고: 이 키는 데이터 복구를 위한 매우 민감한 정보입니다. '
                '타인에게 노출되면 데이터가 유출될 수 있습니다.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(dialogContext)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  key,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('닫기'),
            ),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: key));
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('클립보드에 복사되었습니다.')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('복사'),
            ),
          ],
        );
      },
    );

    await _load();
  }

  Future<void> _showRestoreDialog() async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('암호화 키 복구'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '주의: 잘못된 키를 복구하면 기존 데이터베이스를 열 수 없게 될 수 있습니다.\n'
                '키는 Base64Url 형식의 32바이트(256-bit) 값이어야 합니다.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '암호화 키 (Base64Url)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('복구'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      controller.dispose();
      return;
    }

    final input = controller.text.trim();
    controller.dispose();

    if (input.isEmpty) return;

    final ok = await DbEncryptionKeyManager.restoreKeyFromBackup(input);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '암호화 키를 복구했습니다. 앱을 완전히 종료 후 재실행하세요.'
              : '키 형식이 올바르지 않습니다.',
        ),
      ),
    );

    if (ok) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyPreview = (_key == null || _key!.isEmpty)
        ? '키 없음'
        : '${_key!.substring(0, _key!.length < 8 ? _key!.length : 8)}…';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(IconCatalog.lockOutline),
            SizedBox(width: 8),
            Text('데이터베이스 암호화'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.key_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '현재 키(미리보기)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _loading ? '불러오는 중…' : keyPreview,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '새로고침',
                    onPressed: _loading ? null : _load,
                    icon: const Icon(IconCatalog.refresh),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('암호화 키 백업(보기/복사)'),
            subtitle: const Text('기기 분실/초기화 대비용 (오프라인 보관 권장)'),
            trailing: const Icon(IconCatalog.navigateNext),
            onTap: _showExportDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('암호화 키 복구'),
            subtitle: const Text('기존 키를 백업해 둔 값으로 덮어씁니다'),
            trailing: const Icon(IconCatalog.navigateNext),
            onTap: _showRestoreDialog,
          ),
        ],
      ),
    );
  }
}
