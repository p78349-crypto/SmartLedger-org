part of 'backup_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension BackupScreenRestore on _BackupScreenState {
  Future<void> _restoreAsNewAccount() async {
    final controller = TextEditingController();
    try {
      final newAccountName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('새 계정으로 복원'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('복원할 새 계정명을 입력하세요.\n기존 데이터는 보존됩니다.'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '새 계정명',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final locale = Localizations.localeOf(context);
                    final suffix = AccountNameLanguageTag.suffixForLocale(
                      locale,
                    );
                    final baseName = value.text.trim();
                    final finalName = AccountNameLanguageTag.applyForcedSuffix(
                      baseName,
                      locale,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final locale = Localizations.localeOf(context);
                final baseName = controller.text.trim();
                final finalName = AccountNameLanguageTag.applyForcedSuffix(
                  baseName,
                  locale,
                );
                Navigator.pop(context, finalName);
              },
              child: const Text('복원'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (newAccountName == null || newAccountName.isEmpty) return;
      setState(() {
        _isProcessing = true;
        _backupStatus = '복원 중...';
      });
      try {
        final picked = await BackupService().pickBackupFile();
        if (picked == null) {
          if (!mounted) return;
          setState(() {
            _backupStatus = '복원이 취소되었습니다';
            _isProcessing = false;
          });
          return;
        }

        final password = await _prepareRestorePasswordIfNeeded(picked);
        final jsonStr = await BackupService().readBackupFileAsJson(
          file: picked,
          password: password,
        );
        final preview = BackupService().parseBackupPreview(jsonStr);
        final exportedAtText =
            preview.exportedAt?.toLocal().toString() ?? '알 수 없음';
        final sourceAccountText =
            preview.sourceAccountName?.trim().isNotEmpty == true
            ? preview.sourceAccountName!
            : '알 수 없음';

        if (!mounted) return;
        final ok = await DialogUtils.showConfirmDialog(
          context,
          title: '복원 내용 확인',
          message:
              '이 백업을 "$newAccountName" 계정으로 복원합니다.\n\n'
              '백업 계정: $sourceAccountText\n'
              '내보낸 시각: $exportedAtText\n\n'
              '거래: ${preview.transactionCount}건\n'
              '자산: ${preview.assetCount}개\n'
              '고정비: ${preview.fixedCostCount}개\n'
              '저축계획: ${preview.savingsPlanCount}개\n'
              '장바구니: ${preview.shoppingCartItemCount}개\n\n'
              '계속하시겠습니까?',
          confirmText: '복원',
        );
        if (ok != true) {
          if (!mounted) return;
          setState(() {
            _backupStatus = '복원이 취소되었습니다';
            _isProcessing = false;
          });
          return;
        }
        await BackupService().importAccountDataAsNew(jsonStr, newAccountName);
        if (!mounted) return;
        setState(() {
          _backupStatus = '✅ 복원 완료!\n계정: $newAccountName';
          _isProcessing = false;
        });
        SnackbarUtils.showSuccess(
          context,
          '$newAccountName 계정으로 복원되었습니다\n(보안: 비밀번호는 새로 설정해주세요)',
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _backupStatus = '❌ 복원 실패: $e';
          _isProcessing = false;
        });
        SnackbarUtils.showError(context, '복원 실패: $e');
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _restoreFromFile(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    try {
      final password = await _prepareRestorePasswordIfNeeded(file);
      final jsonStr = await BackupService().readBackupFileAsJson(
        file: file,
        password: password,
      );
      final preview = BackupService().parseBackupPreview(jsonStr);
      final exportedAtText =
          preview.exportedAt?.toLocal().toString() ?? '알 수 없음';
      final sourceAccountText =
          preview.sourceAccountName?.trim().isNotEmpty == true
          ? preview.sourceAccountName!
          : '알 수 없음';

      if (!mounted) return;

      final controller = TextEditingController(
        text: preview.sourceAccountName?.trim().isNotEmpty == true
            ? preview.sourceAccountName!
            : '',
      );
      String? newAccountName;
      try {
        newAccountName = await showDialog<String>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('새 계정으로 복원'),
              content: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final locale = Localizations.localeOf(dialogContext);
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
                      Text(
                        '이 백업을 새 계정으로 복원합니다.\n기존 데이터는 보존됩니다.\n\n'
                        '파일: $fileName\n'
                        '백업 계정: $sourceAccountText\n'
                        '내보낸 시각: $exportedAtText\n\n'
                        '거래: ${preview.transactionCount}건\n'
                        '자산: ${preview.assetCount}개\n'
                        '고정비: ${preview.fixedCostCount}개\n'
                        '저축계획: ${preview.savingsPlanCount}개\n'
                        '장바구니: ${preview.shoppingCartItemCount}개',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: '새 계정명',
                          border: OutlineInputBorder(),
                        ),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final baseName = controller.text.trim();
                    if (baseName.isEmpty) return;
                    final locale = Localizations.localeOf(dialogContext);
                    final finalName = AccountNameLanguageTag.applyForcedSuffix(
                      baseName,
                      locale,
                    );
                    Navigator.pop(dialogContext, finalName);
                  },
                  child: const Text('복원'),
                ),
              ],
            );
          },
        );
      } finally {
        controller.dispose();
      }

      if (!mounted) return;
      if (newAccountName == null || newAccountName.trim().isEmpty) return;

      setState(() {
        _isProcessing = true;
        _backupStatus = '복원 중...';
      });

      await BackupService().importAccountDataAsNew(jsonStr, newAccountName);

      if (!mounted) return;
      setState(() {
        _backupStatus = '✅ 복원 완료!\n계정: $newAccountName';
        _isProcessing = false;
      });
      SnackbarUtils.showSuccess(
        context,
        '$newAccountName 계정으로 복원되었습니다\n(보안: 비밀번호는 새로 설정해주세요)',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '❌ 복원 실패: $error';
        _isProcessing = false;
      });
      SnackbarUtils.showError(context, '복원 실패: $error');
    }
  }

  Future<void> _deleteBackupFile(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final confirmed = await DialogUtils.showDeleteConfirmDialog(
      context,
      customMessage: '백업 파일을 삭제하시겠습니까?\n\n$fileName',
    );
    if (confirmed != true || !mounted) return;
    try {
      await file.delete();
      if (!mounted) return;
      await _loadBackupFiles();
      if (mounted) SnackbarUtils.showSuccess(context, '삭제되었습니다');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '❌ 삭제 실패: $e';
      });
      SnackbarUtils.showError(context, '삭제 실패: $e');
    }
  }
}
