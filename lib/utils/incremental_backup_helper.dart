// Incremental Backup Helper - Change Detection
// Follows AI_CODE_RULES: 80-line limit, helper functions

import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/incremental_backup_models.dart';

class IncrementalBackupHelper {
  // Generate checksum for data integrity
  static String generateChecksum(Map<String, dynamic> data) {
    final jsonString = json.encode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Compare data to detect changes
  static ChangeType detectChangeType(
    String? previousChecksum,
    String currentChecksum,
  ) {
    if (previousChecksum == null) return ChangeType.added;
    if (previousChecksum != currentChecksum) return ChangeType.modified;
    return ChangeType.added; // Default case
  }

  // Create backup change record
  static BackupChange createChange({
    required String id,
    required String dataType,
    required Map<String, dynamic> data,
    String? previousChecksum,
  }) {
    final currentChecksum = generateChecksum(data);
    final changeType = detectChangeType(previousChecksum, currentChecksum);

    return BackupChange(
      id: id,
      dataType: dataType,
      type: changeType,
      timestamp: DateTime.now(),
      data: data,
      previousChecksum: previousChecksum,
      currentChecksum: currentChecksum,
    );
  }

  // Validate backup data integrity
  static bool validateChecksum(Map<String, dynamic> data, String checksum) {
    return generateChecksum(data) == checksum;
  }

  // Generate unique backup ID
  static String generateBackupId() {
    final now = DateTime.now();
    return 'inc_backup_${now.millisecondsSinceEpoch}';
  }

  // Calculate backup size estimation
  static int estimateBackupSize(List<BackupChange> changes) {
    return changes.fold(
      0,
      (sum, change) => sum + json.encode(change.data).length,
    );
  }

  // Filter changes by data type
  static List<BackupChange> filterByDataType(
    List<BackupChange> changes,
    String dataType,
  ) {
    return changes.where((c) => c.dataType == dataType).toList();
  }

  // Group changes by type for processing
  static Map<ChangeType, List<BackupChange>> groupChangesByType(
    List<BackupChange> changes,
  ) {
    final grouped = <ChangeType, List<BackupChange>>{};
    for (final change in changes) {
      grouped.putIfAbsent(change.type, () => []).add(change);
    }
    return grouped;
  }

  // Check if incremental backup is needed
  static bool isBackupNeeded(List<BackupChange> changes) {
    return changes.isNotEmpty;
  }

  // Create backup file name with timestamp
  static String createBackupFileName(String prefix) {
    final now = DateTime.now();
    final timestamp = now.toIso8601String().replaceAll(':', '-');
    return '${prefix}_incremental_$timestamp.json';
  }
}
