part of 'cloud_backup_service.dart';

/// Cloud Backup Service Utils
/// Helper methods for configuration and data management
extension CloudBackupServiceUtils on CloudBackupService {
  /// Saves cloud backup configuration
  Future<void> _saveConfiguration(CloudBackupConfiguration config) async {
    final configJson = jsonEncode(config.toJson());
    await _userPrefService.setString('cloud_backup_config', configJson);
    
    // Store sensitive credentials in secure storage if needed
    if (config.accountId.isNotEmpty) {
      await _secureStorage.write('cloud_account_id', config.accountId);
    }
  }

  /// Gets current cloud backup configuration
  Future<CloudBackupConfiguration> _getConfiguration() async {
    final configStr = await _userPrefService.getString('cloud_backup_config');
    
    if (configStr == null) {
      // Return default configuration
      return const CloudBackupConfiguration(
        providerId: 'firebase_storage',
        accountId: '',
        encryptionEnabled: true,
        autoBackupEnabled: false,
        backupFrequency: BackupFrequency.daily,
        retentionDays: 30,
        maxBackupSize: 100,
      );
    }
    
    final configJson = jsonDecode(configStr) as Map<String, dynamic>;
    return CloudBackupConfiguration.fromJson(configJson);
  }

  /// Gets backup encryption key
  Future<String?> _getBackupEncryption() async {
    return await _backupService.getStoredBackupEncryptionPassword();
  }

  /// Records successful backup completion
  Future<void> _recordBackupSuccess(String backupId, int fileSize) async {
    final now = DateTime.now();
    
    await _userPrefService.setString('last_cloud_backup_time', now.toIso8601String());
    await _userPrefService.setString('last_cloud_backup_id', backupId);
    await _userPrefService.setInt('last_cloud_backup_size', fileSize);
    
    // Update backup history
    await _addToBackupHistory(backupId, fileSize, now);
  }

  /// Gets last backup time
  Future<DateTime?> _getLastBackupTime() async {
    final timeStr = await _userPrefService.getString('last_cloud_backup_time');
    return timeStr != null ? DateTime.tryParse(timeStr) : null;
  }

  /// Gets last backup status
  Future<CloudBackupStatus?> _getLastBackupStatus() async {
    final backupId = await _userPrefService.getString('last_cloud_backup_id');
    final fileSize = await _userPrefService.getInt('last_cloud_backup_size');
    final backupTime = await _getLastBackupTime();
    
    if (backupId == null || backupTime == null) return null;
    
    return CloudBackupStatus(
      backupId: backupId,
      status: BackupStatusType.completed,
      startTime: backupTime.subtract(const Duration(minutes: 5)),
      endTime: backupTime,
      fileSize: fileSize,
      errorMessage: null,
      progressPercentage: 100.0,
    );
  }

  /// Adds backup to history
  Future<void> _addToBackupHistory(String backupId, int fileSize, DateTime timestamp) async {
    final history = await _getBackupHistory();
    
    history.add({
      'backupId': backupId,
      'fileSize': fileSize,
      'timestamp': timestamp.toIso8601String(),
      'status': 'completed',
    });
    
    // Keep only last 50 backups
    if (history.length > 50) {
      history.removeRange(0, history.length - 50);
    }
    
    final historyJson = jsonEncode(history);
    await _userPrefService.setString('cloud_backup_history', historyJson);
  }

  /// Gets backup history
  Future<List<Map<String, dynamic>>> _getBackupHistory() async {
    final historyStr = await _userPrefService.getString('cloud_backup_history');
    
    if (historyStr == null) return [];
    
    try {
      final historyList = jsonDecode(historyStr) as List;
      return historyList.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}