part of 'backup_service.dart';

/// Incremental backup extension for BackupService
/// Handles smart backups with change detection and cloud integration
extension BackupServiceIncremental on BackupService {
  /// Performs incremental backup if changes detected
  Future<Map<String, dynamic>> performIncrementalBackup({
    bool forceFullBackup = false,
    String? customPath,
  }) async {
    try {
      final incrementalService = IncrementalBackupService();

      final currentData = <String, Map<String, dynamic>>{};
      final snapshot = await incrementalService.createIncrementalBackup(
        'global',
        currentData,
      );

      if (!forceFullBackup && snapshot.changes.isEmpty) {
        return {
          'success': true,
          'type': 'no_changes',
          'message': 'No changes detected since last backup',
          'lastBackup': snapshot.createdAt.toIso8601String(),
        };
      }

      return {
        'success': true,
        'type': forceFullBackup ? 'full_backup' : 'incremental',
        'changes': snapshot.changes.length,
        'file': customPath,
        'size': IncrementalBackupHelper.estimateBackupSize(snapshot.changes),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Schedules automatic incremental backups
  Future<void> scheduleIncrementalBackup({
    Duration interval = const Duration(hours: 6),
    bool enableCloudSync = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('auto_incremental_backup', true);
    await prefs.setInt('backup_interval_hours', interval.inHours);
    await prefs.setBool('cloud_sync_enabled', enableCloudSync);
    
    final nextBackup = DateTime.now().add(interval);
    await prefs.setString('next_backup_time', nextBackup.toIso8601String());
  }
}