/// Cloud Backup Models
/// Handles cloud storage integration and automated backup scheduling
class CloudBackupConfiguration {
  const CloudBackupConfiguration({
    required this.providerId,
    required this.accountId,
    required this.encryptionEnabled,
    required this.autoBackupEnabled,
    required this.backupFrequency,
    required this.retentionDays,
    required this.maxBackupSize,
  });

  final String providerId; // 'google_drive', 'dropbox', 'firebase_storage'
  final String accountId;
  final bool encryptionEnabled;
  final bool autoBackupEnabled;
  final BackupFrequency backupFrequency;
  final int retentionDays;
  final int maxBackupSize; // In MB

  Map<String, dynamic> toJson() => {
    'providerId': providerId,
    'accountId': accountId,
    'encryptionEnabled': encryptionEnabled,
    'autoBackupEnabled': autoBackupEnabled,
    'backupFrequency': backupFrequency.name,
    'retentionDays': retentionDays,
    'maxBackupSize': maxBackupSize,
  };

  factory CloudBackupConfiguration.fromJson(Map<String, dynamic> json) =>
      CloudBackupConfiguration(
        providerId: json['providerId'],
        accountId: json['accountId'],
        encryptionEnabled: json['encryptionEnabled'],
        autoBackupEnabled: json['autoBackupEnabled'],
        backupFrequency: BackupFrequency.values.byName(json['backupFrequency']),
        retentionDays: json['retentionDays'],
        maxBackupSize: json['maxBackupSize'],
      );
}

enum BackupFrequency { hourly, daily, weekly, monthly }

class CloudBackupStatus {
  const CloudBackupStatus({
    required this.backupId,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.fileSize,
    required this.errorMessage,
    required this.progressPercentage,
  });

  final String backupId;
  final BackupStatusType status;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? fileSize; // In bytes
  final String? errorMessage;
  final double progressPercentage; // 0.0 to 100.0

  Map<String, dynamic> toJson() => {
    'backupId': backupId,
    'status': status.name,
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'fileSize': fileSize,
    'errorMessage': errorMessage,
    'progressPercentage': progressPercentage,
  };
}

enum BackupStatusType { pending, inProgress, completed, failed, cancelled }

class CloudRestoreRequest {
  const CloudRestoreRequest({
    required this.backupId,
    required this.targetLocation,
    required this.restoreType,
    required this.selectedComponents,
  });

  final String backupId;
  final String targetLocation;
  final RestoreType restoreType;
  final List<String> selectedComponents;

  Map<String, dynamic> toJson() => {
    'backupId': backupId,
    'targetLocation': targetLocation,
    'restoreType': restoreType.name,
    'selectedComponents': selectedComponents,
  };
}

enum RestoreType { full, selective, merge }
