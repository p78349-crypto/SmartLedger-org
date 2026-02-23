part of 'backup_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension BackupScreenActions on _BackupScreenState {
  /// 백업 타입 선택 다이얼로그 (지출만, 자산만, 전체)
  Future<void> _showBackupTypeSelection() async {
    final backupType = await showDialog<_BackupType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 백업 데이터 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('백업에 포함할 데이터를 선택하세요'),
            const SizedBox(height: 16),
            _buildDataTypeOption(
              icon: Icons.receipt_long,
              title: '📝 지출 내역만',
              subtitle: '거래 내역, 메모, 결제수단만 백업',
              type: _BackupType.transactionsOnly,
            ),
            const Divider(),
            _buildDataTypeOption(
              icon: Icons.account_balance,
              title: '💰 자산만',
              subtitle: '자산 목록, 자산 이동 기록만 백업',
              type: _BackupType.assetsOnly,
            ),
            const Divider(),
            _buildDataTypeOption(
              icon: Icons.inventory_2,
              title: '📦 생활용품 재고만',
              subtitle: '생활용품 목록, 보관 위치만 백업',
              type: _BackupType.wmsOnly,
            ),
            const Divider(),
            _buildDataTypeOption(
              icon: Icons.backup,
              title: '✅ 전체 데이터',
              subtitle: '모든 데이터 포함 (권장)',
              type: _BackupType.full,
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

    if (!mounted || backupType == null) return;

    setState(() => _selectedBackupType = backupType);
    
    if (mounted) {
      await _showBackupOptions();
    }
  }

  Widget _buildDataTypeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required _BackupType type,
    bool recommended = false,
  }) {
    return ListTile(
      leading: Icon(icon, size: 28),
      title: Row(
        children: [
          Text(title),
          if (recommended) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
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
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: () => Navigator.pop(context, type),
      contentPadding: EdgeInsets.zero,
    );
  }

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
      final fileName = _buildBackupFileName(now, backupType: _selectedBackupType);
      final pw = await _prepareBackupEncryptionPassword();
      String? hint;
      if (pw != null && pw.isNotEmpty && mounted) {
        hint = await _promptPasswordHint(pw);
      }
      
      final backupTypeStr = _selectedBackupType == _BackupType.transactionsOnly
          ? 'transactions_only'
          : _selectedBackupType == _BackupType.assetsOnly
              ? 'assets_only'
              : _selectedBackupType == _BackupType.wmsOnly
                  ? 'wms_only'
                  : 'full';
      
      await BackupService().saveBackupToFile(
        widget.accountName, fileName, 
        encryptionPassword: pw,
        passwordHint: hint,
        backupType: backupTypeStr,
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
      String? hint;
      if (pw != null && pw.isNotEmpty && mounted) {
        hint = await _promptPasswordHint(pw);
      }
      
      final backupTypeStr = _selectedBackupType == _BackupType.transactionsOnly
          ? 'transactions_only'
          : _selectedBackupType == _BackupType.assetsOnly
              ? 'assets_only'
              : _selectedBackupType == _BackupType.wmsOnly
                  ? 'wms_only'
                  : 'full';
      
      final filePath = await BackupService().saveBackupToDownloads(
        widget.accountName, 
        encryptionPassword: pw,
        passwordHint: hint,
        backupType: backupTypeStr,
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
      String? hint;

      if (pw != null && pw.isNotEmpty && mounted) {
        hint = await _promptPasswordHint(pw);
      }
      
      final backupTypeStr = _selectedBackupType == _BackupType.transactionsOnly
          ? 'transactions_only'
          : _selectedBackupType == _BackupType.assetsOnly
              ? 'assets_only'
              : _selectedBackupType == _BackupType.wmsOnly
                  ? 'wms_only'
                  : 'full';
      
      await BackupService().shareBackup(
        widget.accountName, 
        encryptionPassword: pw,
        passwordHint: hint,
        backupType: backupTypeStr,
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
      String? hint;

      if (pw != null && pw.isNotEmpty && mounted) {
        hint = await _promptPasswordHint(pw);
      }

      final backupTypeStr = _selectedBackupType == _BackupType.transactionsOnly
          ? 'transactions_only'
          : _selectedBackupType == _BackupType.assetsOnly
              ? 'assets_only'
              : _selectedBackupType == _BackupType.wmsOnly
                  ? 'wms_only'
                  : 'full';
      
      await BackupService().composeEmailWithBackup(
        widget.accountName, 
        encryptionPassword: pw,
        passwordHint: hint,
        backupType: backupTypeStr,
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

  Future<String?> _promptPasswordHint(String password) async {
    final autoMaskedHint = BackupService().generateMaskedPasswordHint(password);
    final hintController = TextEditingController(text: autoMaskedHint);
    
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('암호 힌트 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '앱 재설치 시 암호를 기억하기 위한 유일한 수단입니다.\n'
                '마스킹된 힌트만으로 암호를 유추할 수 있는지 다시 한번 확인하십시오.\n\n'
                '※ 암호 분실로 인한 데이터 손실은 본인 책임이며 복구가 절대 불가능합니다.',
                style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '자동 생성된 마스킹 힌트:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: hintController,
                decoration: const InputDecoration(
                  labelText: '암호 힌트 (수정 가능)',
                  border: OutlineInputBorder(),
                  helperText: '예: 12****89 (마스킹 힌트)',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ 주의: 힌트가 너무 노골적이면 보안이 취약해질 수 있으나, 너무 어려우면 복구가 불가합니다.',
                style: TextStyle(fontSize: 11, color: Colors.orange),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 암호가 설정된 경우 힌트 없이 진행 시 재확인
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('힌트 미설정 주의'),
                    content: const Text(
                      '암호 힌트 없이 진행하면 나중에 암호를 잊었을 때 절대로 복구할 수 없습니다.\n정말 힌트 없이 진행할까요?'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('아니오 (힌트 입력)'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx); // 경고창 닫기
                          Navigator.pop(context, ''); // 빈 힌트로 진행
                        },
                        child: const Text('예 (위험 감수)'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('힌트 없이 진행'),
            ),
            FilledButton(
              onPressed: () {
                final hint = hintController.text.trim();
                if (hint.isEmpty) {
                  SnackbarUtils.showError(context, '힌트를 입력하거나 취소 버튼을 눌러주세요.');
                  return;
                }
                Navigator.pop(context, hint);
              },
              child: const Text('이 힌트로 저장'),
            ),
          ],
        ),
      );
    } finally {
      hintController.dispose();
    }
  }
}
