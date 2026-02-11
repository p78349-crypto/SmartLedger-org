part of 'backup_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension BackupScreenActions on _BackupScreenState {
  Future<void> _showBackupOptions() async {
    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업 방법 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('백업 파일을 어디에 저장하시겠습니까?'),
            const SizedBox(height: 16),
            _buildBackupOption(
              icon: Icons.phone_android,
              title: '앱 내부 저장',
              subtitle: '안전 (앱 삭제 시 삭제됨)',
              value: 'internal',
              recommended: true,
            ),
            const Divider(),
            _buildBackupOption(
              icon: Icons.folder,
              title: 'Downloads 폴더',
              subtitle: '⚠️ 다른 앱도 접근 가능',
              value: 'downloads',
            ),
            const Divider(),
            _buildBackupOption(
              icon: Icons.share,
              title: '공유/내보내기',
              subtitle: '클라우드 드라이브/포털 클라우드 등 앱 선택',
              value: 'share',
              recommended: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (!mounted || option == null) return;

    if (option == 'internal') {
      await _backupToInternal();
    } else if (option == 'downloads') {
      await _backupToDownloads();
    } else if (option == 'share') {
      await _shareExport();
    }
  }

  Widget _buildBackupOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    bool recommended = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: recommended ? Colors.green : null),
      title: Row(
        children: [
          Text(title),
          if (recommended) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '권장',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle),
      onTap: () => Navigator.pop(context, value),
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _backupToInternal() async {
    setState(() {
      _isProcessing = true;
      _backupStatus = '백업 중...';
    });
    try {
      final now = DateTime.now();
      final fileName = _buildBackupFileName(now);
      final pw = await _prepareBackupEncryptionPassword();
      await BackupService().saveBackupToFile(
        widget.accountName, fileName, encryptionPassword: pw,
      );
      if (!mounted) return;
      await _loadBackupFiles();
      if (!mounted) return;
      setState(() {
        _backupStatus = '✅ 백업 완료!\n앱 내부에 안전하게 저장되었습니다.';
        _isProcessing = false;
      });
      if (mounted) SnackbarUtils.showSuccess(context, '백업이 완료되었습니다');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '❌ 백업 실패: $e';
        _isProcessing = false;
      });
      SnackbarUtils.showError(context, '백업 실패: $e');
    }
  }

  Future<void> _backupToDownloads() async {
    final encryptionNotice = _backupEncryptionEnabled
        ? (_backupTwoFactorEnabled
              ? '✅ 암호화 저장됩니다.\n(복원 시 암호 + 기기 인증 필요)'
              : '✅ 암호화 저장됩니다.\n(복원 시 암호 필요)')
        : '암호화 없이 저장됩니다.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('보안 경고'),
          ],
        ),
        content: Text(
          'Downloads 폴더에 저장하시겠습니까?\n\n'
          '✅ 앱 삭제 후에도 파일 보존\n'
          '⚠️ 다른 앱에서 접근 가능\n'
          '⚠️ 금융 정보 포함됨\n\n'
          '$encryptionNotice',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('계속'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _backupStatus = '백업 중...';
    });
    try {
      final pw = await _prepareBackupEncryptionPassword();
      final filePath = await BackupService().saveBackupToDownloads(
        widget.accountName, encryptionPassword: pw,
      );
      final fileName = filePath.split(Platform.pathSeparator).last;
      final savedDir = File(filePath).parent.path;

      if (!mounted) return;
      setState(() {
        _backupStatus = '✅ 백업 완료!\n위치: $savedDir\n파일: $fileName';
        _isProcessing = false;
      });
      if (mounted) SnackbarUtils.showSuccess(context, '백업이 완료되었습니다');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '❌ 백업 실패: $e';
        _isProcessing = false;
      });
      SnackbarUtils.showError(context, '백업 실패: $e');
    }
  }

  Future<void> _shareExport() async {
    setState(() {
      _isProcessing = true;
      _backupStatus = '공유/내보내기 준비 중...';
    });
    try {
      final pw = await _prepareBackupEncryptionPassword();
      await BackupService().shareBackup(
        widget.accountName, encryptionPassword: pw,
      );
      if (!mounted) return;
      setState(() { _backupStatus = null; _isProcessing = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '❌ 공유 실패: $e';
        _isProcessing = false;
      });
      SnackbarUtils.showError(context, '공유 실패: $e');
    }
  }

  Future<void> _sendEmailBackup() async {
    setState(() {
      _isProcessing = true;
      _backupStatus = '이메일 준비 중...';
    });
    try {
      final pw = await _prepareBackupEncryptionPassword();
      await BackupService().composeEmailWithBackup(
        widget.accountName, encryptionPassword: pw,
      );
      if (!mounted) return;
      setState(() { _backupStatus = null; _isProcessing = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '❌ 이메일 열기 실패: $e';
        _isProcessing = false;
      });
      SnackbarUtils.showError(context, '이메일 열기 실패: $e');
    }
  }
}
