import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../models/cloud_backup_models.dart';
import '../utils/cloud_backup_helper.dart';
import 'backup_service.dart';
import 'user_pref_service.dart';
import 'secure_storage_service.dart';

part 'cloud_backup_service_extensions.dart';
part 'cloud_backup_service_utils.dart';

/// Cloud Backup Service
/// Handles automated cloud backups and restoration functionality
class CloudBackupService {
  static final CloudBackupService _instance = CloudBackupService._internal();
  factory CloudBackupService() => _instance;
  CloudBackupService._internal();

  final BackupService _backupService = BackupService();
  final UserPrefService _userPrefService = UserPrefService();
  final SecureStorageService _secureStorage = SecureStorageService();

  Timer? _autoBackupTimer;
  StreamController<CloudBackupStatus>? _statusController;

  /// Initializes cloud backup with configuration
  Future<void> initialize(CloudBackupConfiguration config) async {
    try {
      await _saveConfiguration(config);
      
      if (config.autoBackupEnabled) {
        await _scheduleAutomaticBackups(config);
      }
      
      _statusController = StreamController<CloudBackupStatus>.broadcast();
      
    } catch (e) {
      throw Exception('Failed to initialize cloud backup: $e');
    }
  }

  /// Performs backup to cloud storage
  Future<CloudBackupStatus> performCloudBackup({
    bool isManualBackup = false,
    String? customFileName,
  }) async {
    final backupId = CloudBackupHelper.generateBackupId(prefix: 'cloud');
    
    try {
      final status = CloudBackupStatus(
        backupId: backupId,
        status: BackupStatusType.pending,
        startTime: DateTime.now(),
        endTime: null,
        fileSize: null,
        errorMessage: null,
        progressPercentage: 0.0,
      );
      
      _broadcastStatus(status);
      
      // Create local backup first
      final localBackupResult = await _backupService.exportBackup(
        includeShoppingList: true,
        includeTrash: false,
        encryptionPassword: await _getBackupEncryption(),
      );
      
      if (!localBackupResult['success']) {
        return _createFailedStatus(backupId, 'Local backup failed: ${localBackupResult['error']}');
      }
      
      // Upload to cloud
      final uploadResult = await _uploadToCloud(
        localBackupResult['filePath'],
        customFileName ?? 'smartledger_${DateTime.now().millisecondsSinceEpoch}.slb',
        backupId,
      );
      
      return uploadResult;
      
    } catch (e) {
      return _createFailedStatus(backupId, e.toString());
    }
  }

  /// Schedules automatic cloud backups
  Future<void> _scheduleAutomaticBackups(CloudBackupConfiguration config) async {
    _autoBackupTimer?.cancel();
    
    final Duration interval = _getIntervalFromFrequency(config.backupFrequency);
    
    _autoBackupTimer = Timer.periodic(interval, (_) async {
      final lastBackup = await _getLastBackupTime();
      final lastStatus = await _getLastBackupStatus();
      
      if (CloudBackupHelper.shouldRunAutomaticBackup(config, lastBackup, lastStatus)) {
        await performCloudBackup(isManualBackup: false);
      }
    });
  }

  /// Restores data from cloud backup
  Future<Map<String, dynamic>> restoreFromCloud(CloudRestoreRequest request) async {
    try {
      // Download backup from cloud
      final downloadResult = await _downloadFromCloud(request.backupId);
      
      if (!downloadResult['success']) {
        return downloadResult;
      }
      
      // Restore using backup service
      final restoreResult = await _backupService.importBackup(
        downloadResult['filePath'],
        encryptionPassword: await _getBackupEncryption(),
      );
      
      return {
        'success': restoreResult['success'],
        'restored_items': restoreResult['imported_items'] ?? 0,
        'restore_type': request.restoreType.name,
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': 'Restore failed: $e',
      };
    }
  }

  /// Gets backup status stream
  Stream<CloudBackupStatus>? get backupStatusStream => _statusController?.stream;

  /// Disposes resources
  void dispose() {
    _autoBackupTimer?.cancel();
    _statusController?.close();
  }
}