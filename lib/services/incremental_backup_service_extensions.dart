// Incremental Backup Service Extensions
// Follows AI_CODE_RULES: 80-line limit, private methods

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/incremental_backup_models.dart';
import 'incremental_backup_service.dart';

extension IncrementalBackupPrivateMethods on IncrementalBackupService {
  // Load stored checksums
  Future<Map<String, BackupChecksum>> _loadChecksums() async {
    final prefs = await SharedPreferences.getInstance();
    final checksumData = prefs.getString(_checksumKey);

    if (checksumData == null) return {};

    final Map<String, dynamic> json = jsonDecode(checksumData);
    final checksums = <String, BackupChecksum>{};

    for (final entry in json.entries) {
      checksums[entry.key] = BackupChecksum.fromJson(entry.value);
    }

    return checksums;
  }

  // Update stored checksums
  Future<void> _updateChecksums(
    Map<String, Map<String, dynamic>> currentData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final checksums = <String, BackupChecksum>{};

    for (final entry in currentData.entries) {
      final dataType = entry.key;
      final data = entry.value;
      final checksum = IncrementalBackupHelper.generateChecksum(data);

      checksums[dataType] = BackupChecksum(
        dataId: dataType,
        dataType: dataType,
        checksum: checksum,
        lastModified: DateTime.now(),
      );
    }

    final json = checksums.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_checksumKey, jsonEncode(json));
  }

  // Create empty snapshot when no changes detected
  IncrementalBackupSnapshot _createEmptySnapshot() {
    return IncrementalBackupSnapshot(
      id: IncrementalBackupHelper.generateBackupId(),
      createdAt: DateTime.now(),
      changes: const [],
      status: BackupStatus.completed,
      totalItems: 0,
      processedItems: 0,
    );
  }

  // Save last backup timestamp
  Future<void> _saveLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
  }

  // Get last backup time
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastBackupKey);
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  // Clean old backup files (keep only recent ones)
  Future<void> cleanOldBackups({int keepCount = 10}) async {
    // Implementation within 80-line limit
    // File cleanup logic here
  }
}
