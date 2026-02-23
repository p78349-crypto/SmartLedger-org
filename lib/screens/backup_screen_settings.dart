part of 'backup_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension BackupScreenSettings on _BackupScreenState {
  String _buildBackupFileName(DateTime timestamp, {_BackupType backupType = _BackupType.full}) {
    final date = [
      timestamp.year.toString(),
      timestamp.month.toString().padLeft(2, '0'),
      timestamp.day.toString().padLeft(2, '0'),
    ].join();
    final time = [
      timestamp.hour.toString().padLeft(2, '0'),
      timestamp.minute.toString().padLeft(2, '0'),
      timestamp.second.toString().padLeft(2, '0'),
    ].join();
    
    String typePrefix = '';
    if (backupType == _BackupType.transactionsOnly) {
      typePrefix = '_transactions';
    } else if (backupType == _BackupType.assetsOnly) {
      typePrefix = '_assets';
    } else if (backupType == _BackupType.wmsOnly) {
      typePrefix = '_wms';
    }
    
    return '${widget.accountName}${typePrefix}_${date}_$time.json';
  }

  Future<void> _loadBackupEncryptionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(PrefKeys.backupEncryptionEnabled) ?? false;
    if (!mounted) return;
    setState(() {
      _backupEncryptionEnabled = enabled;
    });
  }

  Future<void> _setBackupEncryptionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.backupEncryptionEnabled, enabled);
    if (!mounted) return;
    setState(() {
      _backupEncryptionEnabled = enabled;
      if (!enabled) _backupTwoFactorEnabled = false;
    });
    if (!enabled) {
      await prefs.setBool(PrefKeys.backupTwoFactorEnabled, false);
      await BackupService().clearStoredBackupEncryptionPassword();
    }
  }

  Future<void> _loadBackupTwoFactorEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(PrefKeys.backupTwoFactorEnabled) ?? false;

    // Backward-compat: older versions used backupTwoFactorEnabled as the only
    // switch (and implied encryption). If user has it enabled, ensure the new
    // encryption flag is also enabled.
    if (enabled &&
        !(prefs.getBool(PrefKeys.backupEncryptionEnabled) ?? false)) {
      await prefs.setBool(PrefKeys.backupEncryptionEnabled, true);
    }

    if (!mounted) return;
    setState(() {
      _backupTwoFactorEnabled = enabled;
      if (enabled) _backupEncryptionEnabled = true;
    });
  }

  Future<void> _setBackupTwoFactorEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.backupTwoFactorEnabled, enabled);
    if (!mounted) return;
    setState(() {
      _backupTwoFactorEnabled = enabled;
      if (enabled) _backupEncryptionEnabled = true;
    });
  }

  Future<void> _loadRegisteredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(PrefKeys.backupRegisteredEmail);
    if (!mounted) return;
    setState(() {
      _registeredEmail = value;
    });
  }

  Future<void> _showEmailRegistrationDialog() async {
    final controller = TextEditingController(text: _registeredEmail ?? '');
    try {
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('이메일 등록'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('이메일 주소를 저장합니다.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('삭제'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('저장'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (value == null) return;

      final prefs = await SharedPreferences.getInstance();
      if (value.isEmpty) {
        await prefs.remove(PrefKeys.backupRegisteredEmail);
      } else {
        await prefs.setString(PrefKeys.backupRegisteredEmail, value);
      }

      if (!mounted) return;
      setState(() {
        _registeredEmail = value.isEmpty ? null : value;
      });
      SnackbarUtils.showSuccess(context, '저장되었습니다');
    } finally {
      controller.dispose();
    }
  }

  Future<void> _loadBackupFiles() async {
    setState(() {
      _isLoading = true;
      _backupStatus = null;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();

      final downloadsDir = Directory(
        '/storage/emulated/0/Download/'
        '${AppConstants.backupDownloadsFolderName}',
      );

      final internalDir = Directory(appDir.path);
      final internalBackupFolder = Directory(
        '${appDir.path}/${AppConstants.backupDownloadsFolderName}',
      );

      List<_BackupFileInfo> readEntries(Directory dir) {
        if (!dir.existsSync()) return const <_BackupFileInfo>[];
        return dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .where((file) => file.path.contains(widget.accountName))
            .map((file) {
              final stat = file.statSync();
              return _BackupFileInfo(
                file: file,
                fileName: file.path.split(Platform.pathSeparator).last,
                modified: stat.modified,
                sizeInKb: (stat.size / 1024).toStringAsFixed(1),
              );
            })
            .toList();
      }

      final byPath = <String, _BackupFileInfo>{};
      for (final entry in [
        ...readEntries(downloadsDir),
        ...readEntries(internalDir),
        ...readEntries(internalBackupFolder),
      ]) {
        byPath[entry.file.path] = entry;
      }

      final entries = byPath.values.toList()
        ..sort((a, b) => b.modified.compareTo(a.modified));

      if (!mounted) return;
      setState(() {
        _backupDirectory = [
          downloadsDir.path,
          internalDir.path,
          internalBackupFolder.path,
        ].join('\n');
        _backupFiles = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '백업 파일 목록 로딩 실패: $e';
        _isLoading = false;
      });
    }
  }
}
