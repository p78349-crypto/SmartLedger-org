part of 'backup_service.dart';

extension BackupServiceShare on BackupService {
  Future<File?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    return File(result.files.single.path!);
  }

  Future<String> readBackupFileAsJson({
    required File file,
    String? password,
  }) async {
    // ignore: avoid_slow_async_io
    final text = await file.readAsString();
    if (!BackupCrypto.isEncryptedEnvelopeText(text)) {
      return text;
    }
    if (password == null || password.trim().isEmpty) {
      throw Exception('암호화 백업입니다. 백업 암호가 필요합니다.');
    }
    return BackupCrypto.decryptJsonEnvelope(
      encryptedEnvelopeJson: text,
      password: password,
    );
  }

  /// 이메일로 백업 공유
  Future<void> shareBackupViaEmail(
    String accountName, {
    String? encryptionPassword,
  }) async {
    final filePath = await saveBackupToDownloads(
      accountName,
      encryptionPassword: encryptionPassword,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: '$accountName 백업 파일',
        text: 'SmartLedger 백업 파일입니다.',
      ),
    );
  }

  /// 외부 스토리지로 백업 공유 (Google Drive 등)
  Future<void> shareBackupToCloud(
    String accountName, {
    String? encryptionPassword,
  }) async {
    final filePath = await saveBackupToDownloads(
      accountName,
      encryptionPassword: encryptionPassword,
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(filePath)], subject: '$accountName 백업 파일'),
    );
  }

  /// 범용 공유/내보내기
  Future<void> shareBackup(
    String accountName, {
    String? encryptionPassword,
  }) async {
    final filePath = await saveBackupToDownloads(
      accountName,
      encryptionPassword: encryptionPassword,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: '$accountName 백업 파일',
        text: 'SmartLedger 백업 파일입니다.',
      ),
    );
  }

  /// 이메일 작성 화면을 직접 열어 전송(수신자 자동 입력 가능)
  Future<void> composeEmailWithBackup(
    String accountName, {
    String? encryptionPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final to = prefs.getString(PrefKeys.backupRegisteredEmail);
    // Keep a local backup file as well (timestamped) for safety.
    final filePath = await saveBackupToDownloads(
      accountName,
      encryptionPassword: encryptionPassword,
    );

    final email = Email(
      subject: '$accountName 백업 파일',
      body: 'SmartLedger 백업 파일입니다.',
      recipients: (to == null || to.trim().isEmpty) ? [] : [to.trim()],
      attachmentPaths: [filePath],
    );

    await FlutterEmailSender.send(email);
  }

  /// 파일 선택하여 복원 (새 계정 생성)
  Future<String?> restoreFromFile(String newAccountName) async {
    try {
      final file = await pickBackupFile();
      if (file == null) return null;

      // This path is kept for backward compatibility with older callers.
      // Encrypted backups require a password prompt in UI, so they must be
      // handled by BackupScreen.
      // ignore: avoid_slow_async_io
      final jsonStr = await file.readAsString();

      await importAccountDataAsNew(jsonStr, newAccountName);
      return newAccountName;
    } catch (e) {
      throw Exception('복원 실패: $e');
    }
  }
}
