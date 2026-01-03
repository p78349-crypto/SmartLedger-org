import 'dart:convert';

enum TrashEntityType { transaction, asset, account }

class TrashEntry {
  final String id;
  final String entityId;
  final String accountName;
  final TrashEntityType entityType;
  final Map<String, dynamic> payload;
  final DateTime deletedAt;
  final int sizeBytes;

  TrashEntry({
    required this.id,
    required this.entityId,
    required this.accountName,
    required this.entityType,
    required this.payload,
    required this.deletedAt,
    required this.sizeBytes,
  });

  TrashEntry copyWith({Map<String, dynamic>? payload, DateTime? deletedAt}) {
    return TrashEntry(
      id: id,
      entityId: entityId,
      accountName: accountName,
      entityType: entityType,
      payload: payload ?? this.payload,
      deletedAt: deletedAt ?? this.deletedAt,
      sizeBytes: _calculateSizeBytes(payload ?? this.payload),
    );
  }

  factory TrashEntry.forPayload({
    required String id,
    required String entityId,
    required String accountName,
    required TrashEntityType entityType,
    required Map<String, dynamic> payload,
    DateTime? deletedAt,
  }) {
    return TrashEntry(
      id: id,
      entityId: entityId,
      accountName: accountName,
      entityType: entityType,
      payload: payload,
      deletedAt: deletedAt ?? DateTime.now(),
      sizeBytes: _calculateSizeBytes(payload),
    );
  }

  factory TrashEntry.fromJson(Map<String, dynamic> json) {
    final payload = (json['payload'] as Map<String, dynamic>).map(MapEntry.new);
    return TrashEntry(
      id: json['id'] as String,
      entityId: json['entityId'] as String,
      accountName: json['accountName'] as String,
      entityType: TrashEntityType.values.firstWhere(
        (e) => e.name == json['entityType'],
      ),
      payload: payload,
      deletedAt: DateTime.parse(json['deletedAt'] as String),
      sizeBytes: (json['sizeBytes'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityId': entityId,
      'accountName': accountName,
      'entityType': entityType.name,
      'payload': payload,
      'deletedAt': deletedAt.toIso8601String(),
      'sizeBytes': sizeBytes,
    };
  }

  static int _calculateSizeBytes(Map<String, dynamic> payload) {
    final encoded = jsonEncode(payload);
    return utf8.encode(encoded).length;
  }
}

