import 'package:flutter/material.dart';

enum TenantPlan {
  basic('기본', 1, 500, Colors.grey),
  standard('표준', 5, 2000, Colors.blue),
  professional('전문가', 20, 10000, Colors.orange),
  enterprise('엔터프라이즈', 100, 50000, Colors.purple);

  final String label;
  final int maxMembers;
  final int quotaMb;
  final Color color;
  const TenantPlan(this.label, this.maxMembers, this.quotaMb, this.color);
}

/// 테넌트
class Tenant {
  final String id;
  final String name;
  final String organizationName;
  final TenantPlan plan;
  final DateTime createdAt;
  final bool isActive;
  final TenantSettings settings;
  final int memberCount;
  final int dataQuotaMb;
  final double usedStorageMb;

  const Tenant({
    required this.id,
    required this.name,
    required this.organizationName,
    required this.plan,
    required this.createdAt,
    required this.isActive,
    required this.settings,
    required this.memberCount,
    required this.dataQuotaMb,
    required this.usedStorageMb,
  });

  Tenant copyWith({
    String? name,
    String? organizationName,
    TenantPlan? plan,
    bool? isActive,
    TenantSettings? settings,
    int? memberCount,
    int? dataQuotaMb,
    double? usedStorageMb,
  }) {
    return Tenant(
      id: id,
      name: name ?? this.name,
      organizationName: organizationName ?? this.organizationName,
      plan: plan ?? this.plan,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
      memberCount: memberCount ?? this.memberCount,
      dataQuotaMb: dataQuotaMb ?? this.dataQuotaMb,
      usedStorageMb: usedStorageMb ?? this.usedStorageMb,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'org': organizationName,
    'plan': plan.name,
    'created': createdAt.toIso8601String(),
    'active': isActive,
    'settings': settings.toMap(),
    'members': memberCount,
    'quota_mb': dataQuotaMb,
    'used_mb': usedStorageMb,
  };

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    organizationName: json['org'] ?? '',
    plan: TenantPlan.values.firstWhere(
      (p) => p.name == json['plan'],
      orElse: () => TenantPlan.basic,
    ),
    createdAt: json['created'] != null
        ? DateTime.parse(json['created'])
        : DateTime.now(),
    isActive: json['active'] ?? true,
    settings: TenantSettings.fromMap(json['settings'] ?? {}),
    memberCount: json['members'] ?? 1,
    dataQuotaMb: json['quota_mb'] ?? 500,
    usedStorageMb: (json['used_mb'] ?? 0).toDouble(),
  );
}

/// 테넌트 설정
class TenantSettings {
  final DataIsolationLevel isolationLevel;
  final bool allowCrossTenantRead;
  final bool encryptionEnabled;
  final bool auditLogEnabled;
  final String defaultLanguage;
  final String defaultCurrency;
  final Map<String, bool> featureFlags;

  const TenantSettings({
    required this.isolationLevel,
    required this.allowCrossTenantRead,
    required this.encryptionEnabled,
    required this.auditLogEnabled,
    required this.defaultLanguage,
    required this.defaultCurrency,
    required this.featureFlags,
  });

  factory TenantSettings.defaults() => const TenantSettings(
    isolationLevel: DataIsolationLevel.strict,
    allowCrossTenantRead: false,
    encryptionEnabled: true,
    auditLogEnabled: true,
    defaultLanguage: 'ko',
    defaultCurrency: 'KRW',
    featureFlags: {},
  );

  factory TenantSettings.fromMap(Map<String, dynamic> map) => TenantSettings(
    isolationLevel: DataIsolationLevel.values.firstWhere(
      (l) => l.name == (map['isolation'] ?? 'strict'),
      orElse: () => DataIsolationLevel.strict,
    ),
    allowCrossTenantRead: map['cross_read'] ?? false,
    encryptionEnabled: map['encryption'] ?? true,
    auditLogEnabled: map['audit'] ?? true,
    defaultLanguage: map['language'] ?? 'ko',
    defaultCurrency: map['currency'] ?? 'KRW',
    featureFlags: Map<String, bool>.from(map['features'] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'isolation': isolationLevel.name,
    'cross_read': allowCrossTenantRead,
    'encryption': encryptionEnabled,
    'audit': auditLogEnabled,
    'language': defaultLanguage,
    'currency': defaultCurrency,
    'features': featureFlags,
  };
}

/// 데이터 격리 수준
enum DataIsolationLevel {
  shared('공유', '기본 분리, 일부 데이터 공유 가능', Colors.yellow),
  standard('표준', '테넌트별 데이터 분리', Colors.blue),
  strict('엄격', '완전 격리, 교차 접근 불가', Colors.red);

  final String label;
  final String description;
  final Color color;
  const DataIsolationLevel(this.label, this.description, this.color);
}

/// 테넌트 멤버
class TenantMember {
  final String userId;
  final String displayName;
  final TenantMemberRole role;
  final DateTime joinedAt;

  const TenantMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });
}

/// 멤버 역할
enum TenantMemberRole {
  viewer('뷰어', Icons.visibility),
  member('멤버', Icons.person),
  admin('관리자', Icons.admin_panel_settings),
  owner('소유자', Icons.star);

  final String label;
  final IconData icon;
  const TenantMemberRole(this.label, this.icon);
}

/// 데이터 범위
class DataScope {
  final String tenantId;
  final String organizationName;
  final DataIsolationLevel isolationLevel;
  final bool allowCrossTenantRead;
  final bool encryptionEnabled;

  const DataScope({
    required this.tenantId,
    required this.organizationName,
    required this.isolationLevel,
    required this.allowCrossTenantRead,
    required this.encryptionEnabled,
  });
}

/// 테넌트 사용량 통계
class TenantUsageStats {
  final String tenantId;
  final int memberCount;
  final int maxMembers;
  final double usedStorageMb;
  final int quotaMb;
  final double storageUsagePercent;
  final TenantPlan plan;
  final bool isOverQuota;

  const TenantUsageStats({
    required this.tenantId,
    required this.memberCount,
    required this.maxMembers,
    required this.usedStorageMb,
    required this.quotaMb,
    required this.storageUsagePercent,
    required this.plan,
    required this.isOverQuota,
  });
}

/// 테넌트 예외
class TenantException implements Exception {
  final String message;
  const TenantException(this.message);

  @override
  String toString() => 'TenantException: $message';
}

// ════════════════════ UI 위젯 ════════════════════

/// 테넌트 전환 드롭다운
