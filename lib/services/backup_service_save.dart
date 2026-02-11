part of 'backup_service.dart';

extension BackupServiceSave on BackupService {
  Future<void> _writeFileAtomically(File destination, String content) async {
    await destination.parent.create(recursive: true);
    final tmp = File(
      '${destination.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );

    // ignore: avoid_slow_async_io
    await tmp.writeAsString(content, flush: true);

    // ignore: avoid_slow_async_io
    if (await destination.exists()) {
      // ignore: avoid_slow_async_io
      await destination.delete();
    }

    // ignore: avoid_slow_async_io
    await tmp.rename(destination.path);
  }

  /// Downloads 폴더에 백업 저장
  Future<String> saveBackupToDownloads(
    String accountName, {
    String? encryptionPassword,
  }) async {
    // Android 버전별 권한 요청
    bool hasPermission = false;

    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();

      if (androidInfo >= 33) {
        // Android 13+ (API 33+): 특정 권한 불필요, 직접 접근 가능
        hasPermission = true;
      } else if (androidInfo >= 30) {
        // Android 11-12 (API 30-32): MANAGE_EXTERNAL_STORAGE 또는 일반 저장소 권한
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        hasPermission = status.isGranted;
      } else {
        // Android 10 이하: 일반 저장소 권한
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        hasPermission = status.isGranted;
      }
    } else {
      hasPermission = true; // iOS는 권한 불필요
    }

    var json = await exportAccountData(accountName);
    if (encryptionPassword != null && encryptionPassword.trim().isNotEmpty) {
      json = await BackupCrypto.encryptJsonPayload(
        plainJson: json,
        password: encryptionPassword,
      );
    }
    final now = DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final fileName = '${accountName}_$y$m${d}_$hh$mm$ss.json';

    // Attempt Downloads first on Android when permission is available.
    // Fallback: app documents folder (always works, but removed on uninstall).
    // ignore: avoid_slow_async_io
    final appDir = await getApplicationDocumentsDirectory();
    final safeDir = Directory(
      '${appDir.path}/${AppConstants.backupDownloadsFolderName}',
    );

    Directory? primaryDir;
    if (Platform.isAndroid && hasPermission) {
      primaryDir = Directory(
        '/storage/emulated/0/Download/'
        '${AppConstants.backupDownloadsFolderName}',
      );
    }

    Future<String> writeTo(Directory dir) async {
      final file = File('${dir.path}/$fileName');
      await _writeFileAtomically(file, json);
      await setLastBackupDate(accountName, DateTime.now());
      return file.path;
    }

    if (primaryDir != null) {
      try {
        return await writeTo(primaryDir);
      } catch (_) {
        // Fall through to safe dir.
      }
    }

    return writeTo(safeDir);
  }

  /// 긴급용: Downloads 폴더에 "최신 1개"로 덮어쓰는 백업 저장
  Future<String> saveEmergencyBackupToDownloads(
    String accountName, {
    String? encryptionPassword,
  }) async {
    // 권한/저장 위치 정책은 일반 Downloads 저장과 동일하게 유지
    bool hasPermission = false;

    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();

      if (androidInfo >= 33) {
        hasPermission = true;
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        hasPermission = status.isGranted;
      }
    } else {
      hasPermission = true;
    }

    var json = await exportAccountData(accountName);
    if (encryptionPassword != null && encryptionPassword.trim().isNotEmpty) {
      json = await BackupCrypto.encryptJsonPayload(
        plainJson: json,
        password: encryptionPassword,
      );
    }
    const suffix = '_latest.json';
    final fileName = '$accountName$suffix';

    // ignore: avoid_slow_async_io
    final appDir = await getApplicationDocumentsDirectory();
    final safeDir = Directory(
      '${appDir.path}/${AppConstants.backupDownloadsFolderName}',
    );

    Directory? primaryDir;
    if (Platform.isAndroid && hasPermission) {
      primaryDir = Directory(
        '/storage/emulated/0/Download/'
        '${AppConstants.backupDownloadsFolderName}',
      );
    }

    Future<String> writeTo(Directory dir) async {
      final file = File('${dir.path}/$fileName');
      await _writeFileAtomically(file, json);
      await setLastBackupDate(accountName, DateTime.now());
      return file.path;
    }

    if (primaryDir != null) {
      try {
        return await writeTo(primaryDir);
      } catch (_) {
        // Fall through to safe dir.
      }
    }

    return writeTo(safeDir);
  }

  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      // Android SDK 버전 확인 (간단한 방법)
      final androidInfo = await Permission.storage.status;
      // Android 13+에서는 storage 권한이 deprecated되어 denied 상태
      if (androidInfo.isDenied || androidInfo.isPermanentlyDenied) {
        return 33; // Android 13+로 가정
      }
      return 30; // Android 11-12로 가정
    } catch (e) {
      return 33; // 오류 시 최신 버전으로 가정
    }
  }

  Future<String> saveBackupToFile(
    String accountName,
    String fileNameOrPath, {
    String? encryptionPassword,
  }) async {
    var json = await exportAccountData(accountName);
    if (encryptionPassword != null && encryptionPassword.trim().isNotEmpty) {
      json = await BackupCrypto.encryptJsonPayload(
        plainJson: json,
        password: encryptionPassword,
      );
    }
    final file = await _resolveBackupFile(fileNameOrPath);
    await _writeFileAtomically(file, json);
    await setLastBackupDate(accountName, DateTime.now());
    return file.path;
  }

  Future<File> _resolveBackupFile(String fileNameOrPath) async {
    final candidate = File(fileNameOrPath);
    if (candidate.isAbsolute) {
      return candidate;
    }
    // Rationale: Locating application documents directory requires platform
    // access and is async; we perform it async to avoid main thread blocking.
    // ignore: avoid_slow_async_io
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$fileNameOrPath');
  }
}
