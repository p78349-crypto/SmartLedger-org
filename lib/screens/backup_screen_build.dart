part of 'backup_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension BackupScreenBuild on _BackupScreenState {
  Widget _buildMain(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.accountName} - 백업/복원'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '목록 새로고침',
            onPressed: _isProcessing ? null : _loadBackupFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderButtons(theme),
          _buildFileList(theme),
          if (_backupDirectory != null) _buildFooterPath(theme),
        ],
      ),
    );
  }

  Widget _buildHeaderButtons(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.primaryContainer,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('백업 암호화 (암호 필요)'),
            subtitle: const Text(
              '켜면 백업 파일이 암호화됩니다.\n'
              '※ 암호를 잊으면 복원 불가 / 자동백업은 실행되지 않습니다.',
            ),
            value: _backupEncryptionEnabled,
            onChanged: _isProcessing
                ? null
                : (value) async {
                    if (value) {
                      final ok = await DialogUtils.showConfirmDialog(
                        context,
                        title: '백업 암호화 사용',
                        message:
                            '이 옵션을 켜면:\n'
                            '- 백업 파일은 암호화됩니다\n'
                            '- 복원 시 암호가 필요합니다\n'
                            '- 암호를 잊으면 복원이 불가능합니다\n'
                            '- 자동백업은 실행되지 않습니다\n\n'
                            '계속하시겠습니까?',
                        confirmText: '사용',
                      );
                      if (ok != true) return;
                    }
                    await _setBackupEncryptionEnabled(value);
                  },
          ),
          if (_backupEncryptionEnabled) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('2단계 보호 (기기 인증 추가)'),
              subtitle: const Text(
                '켜면 암호 입력 전 기기 인증을 요구합니다.\n'
                '※ 암호화 백업에만 적용됩니다.',
              ),
              value: _backupTwoFactorEnabled,
              onChanged: _isProcessing
                  ? null
                  : (value) async {
                      if (value) {
                        final ok = await DialogUtils.showConfirmDialog(
                          context,
                          title: '2단계 보호 사용',
                          message:
                              '이 옵션을 켜면:\n'
                              '- 백업 생성 시 기기 인증 + 암호 입력\n'
                              '- 복원 시 기기 인증 + 암호 입력\n\n'
                              '계속하시겠습니까?',
                          confirmText: '사용',
                        );
                        if (ok != true) return;
                      }
                      await _setBackupTwoFactorEnabled(value);
                    },
            ),
          ],
          if (_backupEncryptionEnabled || _backupTwoFactorEnabled) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _disableBackupEncryption,
              icon: const Icon(Icons.lock_open_outlined, size: 18),
              label: const Text('백업 암호화 해지'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _showBackupTypeSelection,
            icon: const Icon(Icons.backup),
            label: const Text('새 백업 만들기'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _restoreAsNewAccount,
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('파일에서 복원 (새 계정)'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _showEmailRegistrationDialog,
            icon: const Icon(Icons.alternate_email, size: 18),
            label: Text(
              _registeredEmail == null || _registeredEmail!.isEmpty
                  ? '이메일 등록'
                  : '이메일 등록: $_registeredEmail',
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _sendEmailBackup,
            icon: const Icon(Icons.email, size: 18),
            label: const Text('이메일로 보내기'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _shareExport,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('공유/내보내기'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
          if (_backupStatus != null) ...[
            const SizedBox(height: 12),
            Text(
              _backupStatus!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileList(ThemeData theme) {
    return Expanded(
      child: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingCardListSkeleton(itemCount: 6, height: 76),
            );
          }
          if (_backupStatus != null && _backupFiles.isEmpty) {
            return ErrorState(
              message: _backupStatus,
              onRetry: _loadBackupFiles,
            );
          }
          if (_backupFiles.isEmpty) {
            return const EmptyState(
              title: '백업 파일이 없습니다',
              message: '"새 백업 만들기" 버튼으로 생성하거나 외부 백업을 가져오세요.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _backupFiles.length,
            itemBuilder: (context, index) {
              final entry = _backupFiles[index];
              return _buildFileCard(entry, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildFileCard(_BackupFileInfo entry, ThemeData theme) {
    final modifiedDate = DateFormats.yMdHms.format(entry.modified);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file, size: 40),
        title: Text(entry.fileName, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          '$modifiedDate\n크기: ${entry.sizeInKb} KB',
          style: theme.textTheme.bodySmall,
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'restore') {
              await _restoreFromFile(entry.file);
            } else if (value == 'delete') {
              await _deleteBackupFile(entry.file);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('복원'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('삭제'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterPath(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Text(
        '백업 경로: $_backupDirectory',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
