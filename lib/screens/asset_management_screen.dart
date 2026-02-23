import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';

/// 자산 관리 화면 (입력/편집/삭제) - 완전 독립형
/// 
/// 기능:
/// - 생체인증 (지문/PIN/비밀번호)
/// - 자산 간편 입력 (5초)
/// - 자산 상세 입력
/// - 자산 배분 분석
/// - 엑셀/CSV 내보내기
class AssetManagementScreen extends StatefulWidget {
  final String accountName;

  const AssetManagementScreen({
    super.key,
    required this.accountName,
  });

  @override
  State<AssetManagementScreen> createState() => _AssetManagementScreenState();
}

class _AssetManagementScreenState extends State<AssetManagementScreen> {
  bool _loading = true;
  bool _isAuthenticated = false;
  bool _biometricAuthEnabled = false;
  bool _isDeviceSupported = false;

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const Duration _autoLockIdleTimeout = Duration(minutes: 1);
  Timer? _autoLockTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkDeviceAuthSupport();
    await _loadBiometricSettings();
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _checkDeviceAuthSupport() async {
    try {
      final isDeviceSupported = await _localAuth.canCheckBiometrics;
      if (!mounted) return;
      setState(() => _isDeviceSupported = isDeviceSupported);
    } catch (e) {
      debugPrint('Device auth check failed: $e');
    }
  }

  Future<void> _loadBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final bioEnabled = prefs.getBool(
      PrefKeys.accountKey(
        widget.accountName,
        'asset_biometric_auth_enabled',
      ),
    ) ??
        false;
    if (!mounted) return;
    setState(() => _biometricAuthEnabled = bioEnabled);
  }

  Future<void> _authenticateIfNeeded() async {
    if (!_biometricAuthEnabled) {
      setState(() => _isAuthenticated = true);
      return;
    }
    if (_isAuthenticated) return;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: '자산 관리에 접근하려면 인증하세요',
      );

      if (!mounted) return;
      setState(() => _isAuthenticated = authenticated);
      if (!authenticated) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증에 실패했습니다')),
        );
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 오류: $e')),
      );
    }
  }

  void _resetAutoLockTimer() {
    _autoLockTimer?.cancel();
    if (_biometricAuthEnabled) {
      _autoLockTimer = Timer(_autoLockIdleTimeout, () {
        if (mounted) {
          setState(() => _isAuthenticated = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('자산 관리')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 인증 필요 화면
    if (_biometricAuthEnabled && !_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('자산 관리')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconCatalog.lockOutline,
                size: 64,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(height: 16),
              Text(
                '자산 관리 잠금',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '인증하여 자산 정보에 접근하세요',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _authenticateIfNeeded,
                icon: const Icon(IconCatalog.fingerprint),
                label: const Text('인증하기'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('자산 관리'),
        elevation: 0,
      ),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetAutoLockTimer(),
        onPointerMove: (_) => _resetAutoLockTimer(),
        onPointerUp: (_) => _resetAutoLockTimer(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 📌 보안 설정 토글
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _biometricAuthEnabled
                                  ? Icons.verified_user
                                  : Icons.lock_outline,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '보안 잠금',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        Switch(
                          value: _biometricAuthEnabled,
                          onChanged: _isDeviceSupported
                              ? (value) async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                    PrefKeys.accountKey(
                                      widget.accountName,
                                      'asset_biometric_auth_enabled',
                                    ),
                                    value,
                                  );
                                  if (!mounted) return;
                                  setState(
                                    () => _biometricAuthEnabled = value,
                                  );
                                  if (value && _isAuthenticated) {
                                    setState(() => _isAuthenticated = false);
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 📌 안내 문구 (기능들이 대시보드로 이동됨)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  '자산 관련 주요 기능(입력, 분석, 내보내기)은 이제 자산 페이지의 아이콘으로 바로 이용하실 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
