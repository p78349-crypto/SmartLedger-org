part of 'settings_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension SettingsCards on _SettingsScreenState {
  Future<void> exportDbEncryptionKey() async {
    if (_isLoading) return;

    final key = await DbEncryptionKeyManager.exportKeyForBackup();
    if (key == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('암호화 키를 찾을 수 없습니다.')),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('데이터베이스 암호화 키'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '경고: 이 키는 기기 분실 시 데이터를 복구하기 위한 유일한 수단입니다. '
                '안전한 곳(종이, 오프라인 메모장 등)에 보관하세요. '
                '타인에게 노출되면 데이터가 유출될 수 있습니다.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  key,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('닫기'),
            ),
            TextButton.icon(
              onPressed: () async {
                try {
                  final directory = await getTemporaryDirectory();
                  final file = File('${directory.path}/SmartLedger_Recovery_Key.txt');
                  await file.writeAsString(
                    'SmartLedger 데이터베이스 암호화 복구 키\n\n'
                    '경고: 이 키는 기기 분실 시 데이터를 복구하기 위한 유일한 수단입니다.\n'
                    '타인에게 노출되지 않도록 안전한 곳에 보관하세요.\n\n'
                    '복구 키: $key\n'
                  );
                  
                  final xFile = XFile(file.path);
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [xFile],
                      text: 'SmartLedger 데이터베이스 암호화 복구 키',
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('공유 중 오류가 발생했습니다.')),
                  );
                }
              },
              icon: const Icon(Icons.share),
              label: const Text('공유'),
            ),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: key));
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
  }

  Future<void> disableBackupEncryption() async {
    if (_isLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('암호화 설정 해지'),
          content: const Text(
            '백업 암호화를 해지할까요?\n'
            '저장된 백업 암호가 삭제되고, 이후 백업은 암호 없이 저장될 수 있습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('해지'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.backupEncryptionEnabled, false);
    await prefs.setBool(PrefKeys.backupTwoFactorEnabled, false);
    await BackupService().clearStoredBackupEncryptionPassword();
    if (!mounted) return;
    setState(() {
      _backupEncryptionEnabled = false;
      _backupTwoFactorEnabled = false;
      _isLoading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('백업 암호화 설정을 해지했습니다')));
  }

  Future<void> setUserBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    if (enabled) {
      final can = await _authService.canUseDeviceAuth();
      if (!can) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이 기기에서 지문(기기 인증)을 사용할 수 없습니다')),
        );
        return;
      }
    }

    await prefs.setBool(PrefKeys.userBiometricEnabled, enabled);
    if (!mounted) return;
    setState(() => _userBiometricEnabled = enabled);
  }

  Future<void> setZeroQuickButtonsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await UserPrefService.setZeroQuickButtonsEnabled(enabled: enabled);
    await prefs.setBool(PrefKeys.zeroQuickButtonsEnabled, enabled);
    if (!mounted) return;
    setState(() => _zeroQuickButtonsEnabled = enabled);
  }

  Widget buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerLow.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: scheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  IconCatalog.chevronRight,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSwitchCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
