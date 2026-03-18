export '../models/tenant.dart';
export '../widgets/tenant_widgets.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tenant.dart';

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
      _tenants.addAll(
        list.map((e) => Tenant.fromJson(e as Map<String, dynamic>)),
      );
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
