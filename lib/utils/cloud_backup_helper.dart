import 'dart:io';
import 'dart:math';
import '../models/cloud_backup_models.dart';

/// Cloud Backup Helper
/// Provides utilities for cloud storage operations and scheduling
class CloudBackupHelper {
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 30);

  /// Calculates next backup time based on frequency
  static DateTime calculateNextBackupTime(
    BackupFrequency frequency,
    DateTime? lastBackupTime,
  ) {
    final now = DateTime.now();
    final lastBackup = lastBackupTime ?? now;

    switch (frequency) {
      case BackupFrequency.hourly:
        return lastBackup.add(const Duration(hours: 1));
      case BackupFrequency.daily:
        return DateTime(lastBackup.year, lastBackup.month, lastBackup.day + 1, 2, 0);
      case BackupFrequency.weekly:
        return lastBackup.add(const Duration(days: 7));
      case BackupFrequency.monthly:
        return DateTime(lastBackup.year, lastBackup.month + 1, lastBackup.day, 2, 0);
    }
  }

  /// Validates backup file integrity
  static Future<bool> validateBackupIntegrity(File backupFile) async {
    try {
      if (!await backupFile.exists()) return false;
      
      final size = await backupFile.length();
      if (size < 100) return false; // Minimum viable backup size
      
      // Read first few bytes to validate format
      final bytes = await backupFile.openRead(0, 50).first;
      final header = String.fromCharCodes(bytes);
      
      return header.contains('"version"') || header.contains('smartledger');
    } catch (_) {
      return false;
    }
  }

  /// Calculates optimal chunk size for file upload
  static int calculateChunkSize(int fileSize) {
    if (fileSize < 1024 * 1024) return 64 * 1024; // 64KB for small files
    if (fileSize < 10 * 1024 * 1024) return 256 * 1024; // 256KB for medium files
    return 1024 * 1024; // 1MB for large files
  }

  /// Generates unique backup identifier
  static String generateBackupId({String? prefix}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return '${prefix ?? 'backup'}_${timestamp}_$random';
  }

  /// Estimates upload time based on file size and connection speed
  static Duration estimateUploadTime(int fileSizeBytes, double connectionSpeedMbps) {
    final fileSizeMb = fileSizeBytes / (1024 * 1024);
    final uploadTimeSeconds = (fileSizeMb * 8) / connectionSpeedMbps;
    return Duration(seconds: uploadTimeSeconds.ceil());
  }

  /// Checks if automatic backup should run
  static bool shouldRunAutomaticBackup(
    CloudBackupConfiguration config,
    DateTime? lastBackupTime,
    CloudBackupStatus? lastStatus,
  ) {
    if (!config.autoBackupEnabled) return false;
    
    // Don't backup if last backup failed recently (within last hour)
    if (lastStatus?.status == BackupStatusType.failed) {
      final failTime = lastStatus?.endTime;
      if (failTime != null && DateTime.now().difference(failTime).inHours < 1) {
        return false;
      }
    }
    
    final nextBackupTime = calculateNextBackupTime(config.backupFrequency, lastBackupTime);
    return DateTime.now().isAfter(nextBackupTime);
  }

  /// Calculates backup retention expiry date
  static DateTime calculateRetentionExpiry(int retentionDays) {
    return DateTime.now().add(Duration(days: retentionDays));
  }

  /// Formats file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Validates cloud provider configuration
  static Map<String, bool> validateConfiguration(CloudBackupConfiguration config) {
    return {
      'validProvider': _isValidProvider(config.providerId),
      'validAccount': config.accountId.isNotEmpty,
      'validRetention': config.retentionDays > 0 && config.retentionDays <= 365,
      'validSize': config.maxBackupSize > 0 && config.maxBackupSize <= 1000,
    };
  }

  static bool _isValidProvider(String providerId) {
    const supportedProviders = ['google_drive', 'dropbox', 'firebase_storage'];
    return supportedProviders.contains(providerId);
  }
}