// Incremental Backup Models
// Follows AI_CODE_RULES: 80-line limit, modular design

enum BackupStatus { pending, inProgress, completed, failed }

enum ChangeType { added, modified, deleted }

class BackupChange {
  final String id;
  final String dataType; // 'transaction', 'asset', 'recipe', etc.
  final ChangeType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String? previousChecksum;
  final String currentChecksum;

  const BackupChange({
    required this.id,
    required this.dataType,
    required this.type,
    required this.timestamp,
    required this.data,
    this.previousChecksum,
    required this.currentChecksum,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dataType': dataType,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
    'previousChecksum': previousChecksum,
    'currentChecksum': currentChecksum,
  };

  factory BackupChange.fromJson(Map<String, dynamic> json) => BackupChange(
    id: json['id'] as String,
    dataType: json['dataType'] as String,
    type: ChangeType.values.byName(json['type'] as String),
    timestamp: DateTime.parse(json['timestamp'] as String),
    data: json['data'] as Map<String, dynamic>,
    previousChecksum: json['previousChecksum'] as String?,
    currentChecksum: json['currentChecksum'] as String,
  );
}

class IncrementalBackupSnapshot {
  final String id;
  final DateTime createdAt;
  final List<BackupChange> changes;
  final BackupStatus status;
  final String? errorMessage;
  final int totalItems;
  final int processedItems;

  const IncrementalBackupSnapshot({
    required this.id,
    required this.createdAt,
    required this.changes,
    required this.status,
    this.errorMessage,
    required this.totalItems,
    required this.processedItems,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'changes': changes.map((c) => c.toJson()).toList(),
    'status': status.name,
    'errorMessage': errorMessage,
    'totalItems': totalItems,
    'processedItems': processedItems,
  };

  double get progressPercentage => 
    totalItems > 0 ? (processedItems / totalItems) * 100 : 0;

  IncrementalBackupSnapshot copyWith({
    String? id,
    DateTime? createdAt,
    List<BackupChange>? changes,
    BackupStatus? status,
    String? errorMessage,
    int? totalItems,
    int? processedItems,
  }) {
    return IncrementalBackupSnapshot(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      changes: changes ?? this.changes,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
    );
  }
}

class BackupChecksum {
  final String dataId;
  final String dataType;
  final String checksum;
  final DateTime lastModified;

  const BackupChecksum({
    required this.dataId,
    required this.dataType,
    required this.checksum,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() => {
    'dataId': dataId,
    'dataType': dataType,
    'checksum': checksum,
    'lastModified': lastModified.toIso8601String(),
  };

  factory BackupChecksum.fromJson(Map<String, dynamic> json) {
    return BackupChecksum(
      dataId: json['dataId'] as String,
      dataType: json['dataType'] as String,
      checksum: json['checksum'] as String,
      lastModified: DateTime.parse(json['lastModified'] as String),
    );
  }
}