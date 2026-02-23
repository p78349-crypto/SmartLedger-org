import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 3: 멀티 테넌트 관리 시스템
/// 조직별 분리 환경, 테넌트 격리, 데이터 범위 제어
class MultiTenantService {
  static const String _prefsKey = 'multi_tenant_config';

  // 싱글톤
  static final MultiTenantService _instance = MultiTenantService._();
  factory MultiTenantService() => _instance;
  MultiTenantService._();

  // 현재 활성 테넌트
  Tenant? _currentTenant;
  final List<Tenant> _tenants = [];
  final ValueNotifier<Tenant?> tenantNotifier = ValueNotifier(null);

  /// 초기화 - 저장된 테넌트 정보 로드
  Future<void> initialize() async {
    await _loadTenants();
    final prefs = await SharedPreferences.getInstance();
    final lastTenantId = prefs.getString('${_prefsKey}_current');
    if (lastTenantId != null) {
      _currentTenant = _tenants.firstWhere(
        (t) => t.id == lastTenantId,
        orElse: _getDefaultTenant,
      );
    } else {
      _currentTenant = _getDefaultTenant();
    }
    tenantNotifier.value = _currentTenant;
  }

  /// 현재 테넌트
  Tenant get currentTenant => _currentTenant ?? _getDefaultTenant();

  /// 등록된 모든 테넌트
  List<Tenant> get tenants => List.unmodifiable(_tenants);

  /// 테넌트 전환
  Future<void> switchTenant(String tenantId) async {
    final tenant = _tenants.firstWhere(
      (t) => t.id == tenantId,
      orElse: () => throw TenantException('테넌트를 찾을 수 없습니다: $tenantId'),
    );

    if (!tenant.isActive) {
      throw TenantException('비활성 테넌트입니다: ${tenant.name}');
    }

    _currentTenant = tenant;
    tenantNotifier.value = tenant;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefsKey}_current', tenantId);
  }

  /// 새 테넌트 생성
  Future<Tenant> createTenant({
    required String name,
    required String organizationName,
    TenantPlan plan = TenantPlan.basic,
    Map<String, dynamic>? settings,
  }) async {
    final id = 'tenant_${DateTime.now().millisecondsSinceEpoch}';
    final tenant = Tenant(
      id: id,
      name: name,
      organizationName: organizationName,
      plan: plan,
      createdAt: DateTime.now(),
      isActive: true,
      settings: TenantSettings.fromMap(settings ?? {}),
      memberCount: 1,
      dataQuotaMb: plan.quotaMb,
      usedStorageMb: 0,
    );

    _tenants.add(tenant);
    await _saveTenants();
    return tenant;
  }

  /// 테넌트 설정 업데이트
  Future<void> updateTenantSettings(
    String tenantId,
    TenantSettings newSettings,
  ) async {
    final index = _tenants.indexWhere((t) => t.id == tenantId);
    if (index == -1) throw const TenantException('테넌트를 찾을 수 없습니다');

    _tenants[index] = _tenants[index].copyWith(settings: newSettings);
    await _saveTenants();

    if (_currentTenant?.id == tenantId) {
      _currentTenant = _tenants[index];
      tenantNotifier.value = _currentTenant;
    }
  }

  /// 테넌트 비활성화
  Future<void> deactivateTenant(String tenantId) async {
    final index = _tenants.indexWhere((t) => t.id == tenantId);
    if (index == -1) throw const TenantException('테넌트를 찾을 수 없습니다');
    if (_tenants[index].id == 'default') {
      throw const TenantException('기본 테넌트는 비활성화할 수 없습니다');
    }

    _tenants[index] = _tenants[index].copyWith(isActive: false);
    await _saveTenants();

    if (_currentTenant?.id == tenantId) {
      await switchTenant('default');
    }
  }

  /// 테넌트 멤버 추가
  Future<void> addMember(String tenantId, TenantMember member) async {
    final index = _tenants.indexWhere((t) => t.id == tenantId);
    if (index == -1) throw const TenantException('테넌트를 찾을 수 없습니다');

    final tenant = _tenants[index];
    if (tenant.memberCount >= tenant.plan.maxMembers) {
      throw TenantException(
        '멤버 수 초과: ${tenant.plan.label} 플랜은 최대 ${tenant.plan.maxMembers}명',
      );
    }

    _tenants[index] = tenant.copyWith(memberCount: tenant.memberCount + 1);
    await _saveTenants();
  }

  /// 데이터 격리 범위 확인
  DataScope getDataScope() {
    final tenant = currentTenant;
    return DataScope(
      tenantId: tenant.id,
      organizationName: tenant.organizationName,
      isolationLevel: tenant.settings.isolationLevel,
      allowCrossTenantRead: tenant.settings.allowCrossTenantRead,
      encryptionEnabled: tenant.settings.encryptionEnabled,
    );
  }

  /// 테넌트 사용량 통계
  TenantUsageStats getUsageStats(String tenantId) {
    final tenant = _tenants.firstWhere(
      (t) => t.id == tenantId,
      orElse: () => throw const TenantException('테넌트를 찾을 수 없습니다'),
    );

    return TenantUsageStats(
      tenantId: tenant.id,
      memberCount: tenant.memberCount,
      maxMembers: tenant.plan.maxMembers,
      usedStorageMb: tenant.usedStorageMb,
      quotaMb: tenant.dataQuotaMb,
      storageUsagePercent: tenant.dataQuotaMb > 0
          ? (tenant.usedStorageMb / tenant.dataQuotaMb * 100)
          : 0,
      plan: tenant.plan,
      isOverQuota: tenant.usedStorageMb > tenant.dataQuotaMb,
    );
  }

  // ────────── 내부 메서드 ──────────

  Tenant _getDefaultTenant() {
    return _tenants.firstWhere(
      (t) => t.id == 'default',
      orElse: () {
        final defaultTenant = Tenant(
          id: 'default',
          name: '기본 환경',
          organizationName: '개인',
          plan: TenantPlan.basic,
          createdAt: DateTime.now(),
          isActive: true,
          settings: TenantSettings.defaults(),
          memberCount: 1,
          dataQuotaMb: TenantPlan.basic.quotaMb,
          usedStorageMb: 0,
        );
        _tenants.add(defaultTenant);
        return defaultTenant;
      },
    );
  }

  Future<void> _loadTenants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;

      final list = jsonDecode(raw) as List;
      _tenants.clear();
      _tenants.addAll(list.map((e) => Tenant.fromJson(e as Map<String, dynamic>)));
    } catch (_) {}
  }

  Future<void> _saveTenants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_tenants.map((t) => t.toJson()).toList()),
      );
    } catch (_) {}
  }
}

// ════════════════════ 데이터 모델 ════════════════════

/// 테넌트 플랜
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
class TenantSwitcher extends StatelessWidget {
  final VoidCallback? onManage;

  const TenantSwitcher({super.key, this.onManage});

  @override
  Widget build(BuildContext context) {
    final service = MultiTenantService();
    return ValueListenableBuilder<Tenant?>(
      valueListenable: service.tenantNotifier,
      builder: (context, currentTenant, _) {
        if (currentTenant == null) return const SizedBox.shrink();

        return PopupMenuButton<String>(
          tooltip: '테넌트 전환',
          onSelected: (id) {
            if (id == '_manage') {
              onManage?.call();
            } else {
              service.switchTenant(id);
            }
          },
          itemBuilder: (_) => [
            ...service.tenants.where((t) => t.isActive).map(
              (t) => PopupMenuItem(
                value: t.id,
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 18,
                      color: t.id == currentTenant.id
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.name,
                            style: TextStyle(
                              fontWeight: t.id == currentTenant.id
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            t.organizationName,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    if (t.id == currentTenant.id)
                      Icon(
                        Icons.check,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: '_manage',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 18),
                  SizedBox(width: 8),
                  Text('테넌트 관리'),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: currentTenant.plan.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: currentTenant.plan.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business,
                  size: 16,
                  color: currentTenant.plan.color,
                ),
                const SizedBox(width: 4),
                Text(
                  currentTenant.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: currentTenant.plan.color,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: currentTenant.plan.color,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 테넌트 사용량 대시보드
class TenantUsageDashboard extends StatelessWidget {
  final TenantUsageStats stats;

  const TenantUsageDashboard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '테넌트 사용량',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: stats.plan.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stats.plan.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: stats.plan.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 멤버 수
            _buildUsageRow(
              context,
              icon: Icons.people,
              label: '멤버',
              current: stats.memberCount,
              max: stats.maxMembers,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            // 저장소
            _buildUsageRow(
              context,
              icon: Icons.cloud,
              label: '저장소 (MB)',
              current: stats.usedStorageMb.round(),
              max: stats.quotaMb,
              color: stats.isOverQuota ? Colors.red : Colors.green,
            ),
            if (stats.isOverQuota) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '저장소 용량을 초과했습니다. 플랜 업그레이드를 권장합니다.',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int current,
    required int max,
    required Color color,
  }) {
    final progress = max > 0 ? current / max : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text(
              '$current / $max',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// 테넌트 관리 다이얼로그
class TenantManageDialog extends StatelessWidget {
  const TenantManageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MultiTenantService();
    final tenants = service.tenants;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.business_center, color: Colors.blue),
          SizedBox(width: 8),
          Text('테넌트 관리'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...tenants.map((t) => ListTile(
              leading: CircleAvatar(
                backgroundColor: t.plan.color.withValues(alpha: 0.2),
                child: Icon(Icons.business, color: t.plan.color, size: 20),
              ),
              title: Text(t.name),
              subtitle: Text('${t.organizationName} • ${t.plan.label}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (t.isActive)
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (t.id != 'default')
                    IconButton(
                      icon: const Icon(Icons.settings, size: 18),
                      onPressed: () {},
                    ),
                ],
              ),
              onTap: () {
                if (t.isActive) {
                  service.switchTenant(t.id);
                  Navigator.pop(context);
                }
              },
            )),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.add, color: Colors.white, size: 20),
              ),
              title: const Text('새 테넌트 추가'),
              subtitle: const Text('새로운 조직 환경 생성'),
              onTap: () {
                _showCreateDialog(context);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final orgController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('새 테넌트 생성'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '테넌트 이름',
                hintText: '예: 개발팀 환경',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orgController,
              decoration: const InputDecoration(
                labelText: '조직명',
                hintText: '예: (주)스마트레저',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  orgController.text.isNotEmpty) {
                await MultiTenantService().createTenant(
                  name: nameController.text,
                  organizationName: orgController.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('생성'),
          ),
        ],
      ),
    );
  }
}
