part of 'server_sync_settings_screen.dart';

extension ServerSyncSettingsLogic on _ServerSyncSettingsScreenState {
  Future<void> _showRecoveryKeyRestoreDialog() async {
    final accountController = TextEditingController(
      text: (await UserPrefService.getLastAccountName()) ?? '',
    );
    final recoveryKeyController = TextEditingController();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('복구키로 키복구'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: accountController,
                decoration: const InputDecoration(
                  labelText: '계정 ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: recoveryKeyController,
                decoration: const InputDecoration(
                  labelText: 'Recovery Key (Base64)',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                final accountId = accountController.text.trim();
                final recoveryKey = recoveryKeyController.text.trim();
                if (accountId.isEmpty || recoveryKey.isEmpty) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('계정 ID와 복구키를 입력하세요.')),
                  );
                  return;
                }

                final result = await OnlinePasswordKeyBackupFacade()
                    .restoreWithRecoveryKey(
                      accountId: accountId,
                      recoveryKeyBase64: recoveryKey,
                    );

                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!mounted) return;

                if (result.isSuccess) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('복구키 기반 복구가 완료되었습니다.')),
                  );

                  // 복구 성공 후 비밀번호 재설정 강제
                  if (!mounted) return;
                  final confirmReset = await showDialog<bool>(
                    context: context,
                    builder: (resetContext) => AlertDialog(
                      title: const Text('비밀번호 재설정'),
                      content: const Text(
                        '복구가 완료되었습니다.\n'
                        '보안을 위해 새로운 비밀번호를 설정해주세요.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(resetContext).pop(false),
                          child: const Text('나중에'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(resetContext).pop(true),
                          child: const Text('비밀번호 재설정'),
                        ),
                      ],
                    ),
                  );

                  if (confirmReset == true && mounted) {
                    // 비밀번호 변경 화면으로 이동 (자동으로 rotate 호출됨)
                    if (!mounted) return;
                    Navigator.of(context).pushNamed(
                      '/security_settings',
                      arguments: {'resetPassword': true},
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message ?? '복구키 기반 복구에 실패했습니다.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('복구 실행'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showServerConfigDialog() async {
    final serverConfigService = ServerConfigService();
    final currentAddress = await serverConfigService.getServerAddress() ?? '';
    final currentKey = await serverConfigService.getAdminKey() ?? '';
    final currentMode = await OnlinePasswordKeyBackupFacade.loadPolicyMode();
    final currentServerType = await serverConfigService.getServerType();
    final currentAllowSelfSigned = await serverConfigService
        .getAllowSelfSignedCert();

    final addressController = TextEditingController(text: currentAddress);
    final keyController = TextEditingController(text: currentKey);
    var selectedMode = currentMode;
    var isSelfHosted = currentServerType == 'self_hosted';
    var allowSelfSignedCert = currentAllowSelfSigned;
    var isTestingConnection = false;
    String? testResult;
    var isTestSuccess = false;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('서버 설정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 서버 유형 선택 ──
                    const Text(
                      '서버 유형',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('공용 서버'),
                          icon: Icon(Icons.cloud_outlined),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('자체 호스팅'),
                          icon: Icon(Icons.dns_outlined),
                        ),
                      ],
                      selected: {isSelfHosted},
                      onSelectionChanged: (selected) {
                        setDialogState(() {
                          isSelfHosted = selected.first;
                          if (!isSelfHosted) {
                            // 공용 서버 선택 시 기본 주소로 전환
                            addressController.text =
                                'https://api.smartledger.com';
                            allowSelfSignedCert = false;
                          } else if (addressController.text ==
                              'https://api.smartledger.com') {
                            addressController.text = '';
                          }
                          testResult = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── 서버 주소 ──
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: '서버 주소',
                        hintText: isSelfHosted
                            ? '예: http://192.168.1.100:5000'
                            : 'https://api.smartledger.com',
                        helperText: isSelfHosted
                            ? '로컬 네트워크 또는 원격 서버 주소를 입력하세요'
                            : 'HTTP 또는 HTTPS URL을 입력하세요',
                        prefixIcon: Icon(
                          isSelfHosted ? Icons.lan_outlined : Icons.public,
                        ),
                      ),
                      enabled: isSelfHosted,
                    ),
                    const SizedBox(height: 12),

                    // ── Self-signed cert 토글 (자체 호스팅 모드만) ──
                    if (isSelfHosted) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          '자체 서명 인증서 허용',
                          style: TextStyle(fontSize: 13),
                        ),
                        subtitle: const Text(
                          '로컬 서버에서 HTTPS 사용 시 활성화',
                          style: TextStyle(fontSize: 11),
                        ),
                        secondary: Icon(
                          allowSelfSignedCert
                              ? Icons.verified_user
                              : Icons.gpp_maybe_outlined,
                          color: allowSelfSignedCert
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        value: allowSelfSignedCert,
                        onChanged: (value) {
                          setDialogState(() => allowSelfSignedCert = value);
                        },
                      ),
                      if (allowSelfSignedCert)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                size: 16,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '보안 경고: 신뢰할 수 있는 로컬 서버에서만 사용하세요.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                    ],

                    // ── 연결 테스트 ──
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isTestingConnection
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isTestingConnection = true;
                                      testResult = null;
                                    });

                                    final address = addressController.text
                                        .trim();
                                    final key = keyController.text.trim();

                                    // URI 포맷 검증
                                    if (address.isEmpty) {
                                      setDialogState(() {
                                        testResult = '서버 주소를 입력하세요';
                                        isTestingConnection = false;
                                        isTestSuccess = false;
                                      });
                                      return;
                                    }

                                    final uri = Uri.tryParse(address);
                                    if (uri == null ||
                                        (uri.scheme != 'http' &&
                                            uri.scheme != 'https')) {
                                      setDialogState(() {
                                        testResult =
                                            '올바른 HTTP/HTTPS URL을 입력하세요\n(예: http://192.168.1.100:5000)';
                                        isTestingConnection = false;
                                        isTestSuccess = false;
                                      });
                                      return;
                                    }

                                    if (key.isEmpty) {
                                      setDialogState(() {
                                        testResult = '관리자 키를 입력하세요';
                                        isTestingConnection = false;
                                        isTestSuccess = false;
                                      });
                                      return;
                                    }

                                    // Self-signed cert 설정 임시 적용 후 테스트
                                    await serverConfigService
                                        .setAllowSelfSignedCert(
                                          allowSelfSignedCert,
                                        );
                                    await serverConfigService.saveServerConfig(
                                      address,
                                      key,
                                    );
                                    try {
                                      final isHealthy =
                                          await serverConfigService
                                              .checkHealth();

                                      if (!dialogContext.mounted) return;
                                      setDialogState(() {
                                        if (isHealthy) {
                                          testResult = '✅ 서버 연결 성공!\n응답 상태: 정상';
                                          isTestSuccess = true;
                                        } else {
                                          testResult =
                                              '❌ 서버에 연결할 수 없습니다.\n'
                                              '• 서버가 실행 중인지 확인하세요\n'
                                              '• 서버 주소와 포트를 확인하세요\n'
                                              '• 방화벽 설정을 확인하세요';
                                          isTestSuccess = false;
                                        }
                                        isTestingConnection = false;
                                      });
                                    } catch (e) {
                                      if (!dialogContext.mounted) return;
                                      setDialogState(() {
                                        testResult =
                                            '❌ 연결 오류\n${e.toString().split('\n').first}';
                                        isTestSuccess = false;
                                        isTestingConnection = false;
                                      });
                                    }
                                  },
                            icon: isTestingConnection
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cloud_done),
                            label: const Text('연결 테스트'),
                          ),
                        ),
                      ],
                    ),
                    if (testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isTestSuccess
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          border: Border.all(
                            color: isTestSuccess ? Colors.green : Colors.orange,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          testResult!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isTestSuccess
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: keyController,
                      decoration: const InputDecoration(
                        labelText: '관리자 키',
                        hintText: 'X-Admin-Key',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<KeyBackupServerPolicyMode>(
                      initialValue: selectedMode,
                      decoration: const InputDecoration(
                        labelText: '키백업 서버 정책',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: KeyBackupServerPolicyMode.required,
                          child: Text('required (서버 필수)'),
                        ),
                        DropdownMenuItem(
                          value: KeyBackupServerPolicyMode.optional,
                          child: Text('optional (기본값, 서버 선택)'),
                        ),
                        DropdownMenuItem(
                          value: KeyBackupServerPolicyMode.disabled,
                          child: Text('disabled (서버 미사용)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedMode = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    final address = addressController.text.trim();
                    final key = keyController.text.trim();

                    // 최종 검증
                    if (address.isEmpty || key.isEmpty) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('서버 주소와 관리자 키를 입력하세요')),
                      );
                      return;
                    }

                    final uri = Uri.tryParse(address);
                    if (uri == null ||
                        (uri.scheme != 'http' && uri.scheme != 'https')) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('올바른 HTTP/HTTPS URL을 입력하세요'),
                        ),
                      );
                      return;
                    }

                    await serverConfigService.saveServerConfig(address, key);
                    await serverConfigService.setServerType(
                      isSelfHosted ? 'self_hosted' : 'cloud',
                    );
                    await serverConfigService.setAllowSelfSignedCert(
                      allowSelfSignedCert,
                    );
                    await OnlinePasswordKeyBackupFacade.savePolicyMode(
                      selectedMode,
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '서버 설정이 저장되었습니다. '
                          '유형: ${isSelfHosted ? "자체 호스팅" : "공용"}, '
                          '정책: ${selectedMode.value}',
                        ),
                      ),
                    );
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _resolveSyncAccountName() async {
    final last = await UserPrefService.getLastAccountName();
    if (last != null && last.isNotEmpty && last != 'ROOT') {
      return last;
    }

    final accounts = AccountService().accounts;
    for (final account in accounts) {
      if (account.name != 'ROOT') {
        return account.name;
      }
    }
    return null;
  }

  Future<void> _runManualSync() async {
    final accountName = await _resolveSyncAccountName();
    if (accountName == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('동기화할 일반 계정이 없습니다.')));
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await HomeServerSyncService().syncAllForAccount(accountName);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess ? '동기화가 완료되었습니다.' : '동기화 실패: ${result.message}',
        ),
      ),
    );
  }
}
