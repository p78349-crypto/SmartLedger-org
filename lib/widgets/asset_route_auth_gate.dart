import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/_verify_current_asset_password_dialog.dart';
import '../screens/_verify_current_asset_pin_dialog.dart';
import '../services/auth_service.dart';
import '../services/asset_password_service.dart';
import '../services/asset_pin_service.dart';
import '../services/subscription_access_service.dart';
import '../utils/dev_overrides.dart';
import '../utils/pref_keys.dart';
import '../utils/snackbar_utils.dart';

/// 자산 관련 라우트용 보안 게이트 (ROOT 보안 디자인 복제 – 단일/2중 인증 + 세션)
///
/// - [PrefKeys.assetAuthEnabled] 또는 [PrefKeys.biometricAuthEnabled]로 활성화.
/// - 자산 전용 인증 방식(PIN/비밀번호/지문)을 사용.
/// - 세션 마커 [PrefKeys.assetAuthSessionUntilMs]로 재인증 면제.
class AssetRouteAuthGate extends StatefulWidget {
  const AssetRouteAuthGate({
    super.key,
    required this.child,
    this.reason = '자산 정보에 접근하려면 인증이 필요합니다',
    this.requiresSubscription = false,
    this.subscriptionUserId,
    this.allowSubscriptionGrace = true,
    this.subscriptionDeniedMessage = '구독이 활성화된 계정만 접근할 수 있습니다.',
    this.subscriptionActionLabel = '구독 관리',
    this.onSubscriptionAction,
  });

  final Widget child;
  final String reason;
  final bool requiresSubscription;
  final String? subscriptionUserId;
  final bool allowSubscriptionGrace;
  final String subscriptionDeniedMessage;
  final String subscriptionActionLabel;
  final VoidCallback? onSubscriptionAction;

  @override
  State<AssetRouteAuthGate> createState() => _AssetRouteAuthGateState();
}

class _AssetRouteAuthGateState extends State<AssetRouteAuthGate> {
  final AuthService _authService = AuthService();
  final AssetPinService _assetPinService = AssetPinService();
  final AssetPasswordService _assetPasswordService = AssetPasswordService();

  bool _checking = true;
  bool _enabled = false;
  bool _authorized = false;
  bool _subscriptionAllowed = true;
  String _securityLevel = 'single'; // 'single' or 'dual'

  // 활성화된 보안 방식들
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _passwordEnabled = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (widget.requiresSubscription) {
      final userId = widget.subscriptionUserId;
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _subscriptionAllowed = false;
          _enabled = false;
          _checking = false;
          _authorized = false;
        });
        return;
      }

      final hasAccess = await SubscriptionAccessService.hasPremiumAccessForUser(
        userId,
        allowGrace: widget.allowSubscriptionGrace,
      );
      if (!hasAccess) {
        if (!mounted) return;
        setState(() {
          _subscriptionAllowed = false;
          _enabled = false;
          _checking = false;
          _authorized = false;
        });
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();

    // Dev bypass: compile-time flag
    if (kDevBypassSecurity) {
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _checking = false;
        _authorized = true;
      });
      return;
    }

    // Developer/testing bypass (debug only)
    if (!kReleaseMode &&
        prefs.getBool(PrefKeys.bypassSecurityForTesting) == true) {
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _checking = false;
        _authorized = true;
      });
      return;
    }

    // 새 키 우선, 레거시 키 폴백
    final assetAuthEnabled = prefs.getBool(PrefKeys.assetAuthEnabled) ?? false;
    final legacyEnabled = prefs.getBool(PrefKeys.biometricAuthEnabled) ?? false;
    final enabled = assetAuthEnabled || legacyEnabled;

    // 세션 체크
    final sessionActive = _authService.isSessionActive(
      prefs.getInt(PrefKeys.assetAuthSessionUntilMs),
    );

    final securityLevel =
        prefs.getString(PrefKeys.assetSecurityLevel) ?? 'single';

    final pinEnabled = prefs.getBool(PrefKeys.assetPinEnabled) ?? false;
    final biometricEnabled =
        prefs.getBool(PrefKeys.assetBiometricEnabled) ?? false;
    final passwordEnabled =
        prefs.getBool(PrefKeys.assetPasswordEnabled) ?? false;

    final pinConfigured = _assetPinService.isPinConfigured(prefs);
    final passwordConfigured = _assetPasswordService.isPasswordConfigured(
      prefs,
    );

    final effectivePinEnabled = pinEnabled && pinConfigured;
    final effectivePasswordEnabled = passwordEnabled && passwordConfigured;
    final effectiveBiometricEnabled = biometricEnabled;

    final anyMethodEnabled =
        effectivePinEnabled ||
        effectivePasswordEnabled ||
        effectiveBiometricEnabled;

    if (!mounted) return;
    setState(() {
      _subscriptionAllowed = true;
      _enabled = enabled && anyMethodEnabled;
      _securityLevel = securityLevel;
      _pinEnabled = effectivePinEnabled;
      _biometricEnabled = effectiveBiometricEnabled;
      _passwordEnabled = effectivePasswordEnabled;
      _checking = false;
      _authorized = !(enabled && anyMethodEnabled) || sessionActive;
    });

    if (_enabled && !_authorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptAuthentication(prefs);
      });
    }
  }

  // ──── 인증 흐름 (ROOT 패턴 복제) ────

  Future<void> _promptAuthentication(SharedPreferences prefs) async {
    if (!mounted || _authorized) return;

    final isDualAuth = _securityLevel == 'dual';

    try {
      if (isDualAuth) {
        await _authenticateDual(prefs);
      } else {
        await _authenticateSingle(prefs);
      }
    } catch (_) {
      // 인증 취소 – 잠금 화면 유지
    }
  }

  Future<void> _authenticateSingle(SharedPreferences prefs) async {
    final methods = _enabledMethods();

    if (methods.isEmpty) {
      // 레거시: 기기 인증 폴백
      final result = await _authService.authenticateDevice(
        reason: widget.reason,
      );
      if (result.status == AuthStatus.unavailable) {
        await _writeSession(prefs);
        _setAuthorized();
        return;
      }
      if (!result.ok) throw Exception('인증 취소');
      await _writeSession(prefs);
      _setAuthorized();
      return;
    }

    if (methods.length == 1) {
      final ok = await _runAuth(methods.first, prefs);
      if (!ok) throw Exception('인증 실패');
      await _writeSession(prefs);
      _setAuthorized();
      return;
    }

    // 여러 개 중 선택
    final selected = await _showMethodSelectionDialog(methods);
    if (selected == null) throw Exception('인증 취소');
    final ok = await _runAuth(selected, prefs);
    if (!ok) throw Exception('인증 실패');
    await _writeSession(prefs);
    _setAuthorized();
  }

  Future<void> _authenticateDual(SharedPreferences prefs) async {
    final methods = _enabledMethods();

    if (methods.length != 2) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '2중 인증 설정이 올바르지 않습니다');
      throw Exception('2중 인증 설정 오류');
    }

    // 1차 인증
    final firstOk = await _runAuth(methods[0], prefs);
    if (!firstOk) throw Exception('1차 인증 실패');

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('1차 인증 통과'),
        content: Text('2차 인증 (${_methodLabel(methods[1])})을 진행합니다.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('계속'),
          ),
        ],
      ),
    );

    // 2차 인증
    final secondOk = await _runAuth(methods[1], prefs);
    if (!secondOk) throw Exception('2차 인증 실패');

    await _writeSession(prefs);
    _setAuthorized();
    if (mounted) SnackbarUtils.showSuccess(context, '2중 인증 완료');
  }

  Future<String?> _showMethodSelectionDialog(List<String> methods) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('인증 방식 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: methods.map((method) {
            final String label;
            final IconData icon;
            switch (method) {
              case 'pin':
                label = 'PIN';
                icon = Icons.dialpad;
              case 'biometric':
                label = '지문/생체인식';
                icon = Icons.fingerprint;
              case 'password':
                label = '비밀번호';
                icon = Icons.password;
              default:
                label = method;
                icon = Icons.lock;
            }

            return Card(
              child: ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.of(context).pop(method),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  // ──── 유틸 ────

  List<String> _enabledMethods() {
    final methods = <String>[];
    if (_pinEnabled) methods.add('pin');
    if (_biometricEnabled) methods.add('biometric');
    if (_passwordEnabled) methods.add('password');
    return methods;
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'pin':
        return 'PIN';
      case 'biometric':
        return '지문/생체인식';
      case 'password':
        return '비밀번호';
      default:
        return method;
    }
  }

  void _setAuthorized() {
    if (!mounted) return;
    setState(() => _authorized = true);
  }

  Future<void> _writeSession(SharedPreferences prefs) async {
    await prefs.setInt(
      PrefKeys.assetAuthSessionUntilMs,
      DateTime.now()
          .add(AuthService.assetSessionTimeout)
          .millisecondsSinceEpoch,
    );
  }

  // ──── 개별 인증 실행기 ────

  Future<bool> _authenticatePinWithResult(SharedPreferences prefs) async {
    if (!mounted) return false;
    return (await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return VerifyCurrentAssetPinDialog(
              prefs: prefs,
              service: _assetPinService,
            );
          },
        )) ==
        true;
  }

  Future<bool> _authenticateBiometricWithResult(SharedPreferences prefs) async {
    final result = await _authService.authenticateDevice(reason: widget.reason);

    if (result.ok) return true;

    if (result.status == AuthStatus.unavailable) {
      // 생체인식 불가 시 대체 방식
      if (_passwordEnabled) return _authenticatePasswordWithResult(prefs);
      if (_pinEnabled) return _authenticatePinWithResult(prefs);
      // 아무 방식도 없으면 세션 부여 (레거시 호환)
      await _writeSession(prefs);
      return true;
    }

    if (!mounted) return false;
    SnackbarUtils.showError(context, '생체인식 실패');
    return false;
  }

  Future<bool> _authenticatePasswordWithResult(SharedPreferences prefs) async {
    if (!mounted) return false;
    return (await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return VerifyCurrentAssetPasswordDialog(
              prefs: prefs,
              service: _assetPasswordService,
            );
          },
        )) ==
        true;
  }

  // ──── 통합 인증 실행기 ────

  Future<bool> _runAuth(String method, SharedPreferences prefs) async {
    switch (method) {
      case 'pin':
        return _authenticatePinWithResult(prefs);
      case 'biometric':
        return _authenticateBiometricWithResult(prefs);
      case 'password':
        return _authenticatePasswordWithResult(prefs);
      default:
        return _authenticatePasswordWithResult(prefs);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_subscriptionAllowed) {
      final theme = Theme.of(context);
      return Scaffold(
        appBar: AppBar(
          title: const Text('구독 필요'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  size: 64,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                Text(
                  '구독 인증 필요',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.subscriptionDeniedMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.onSubscriptionAction != null) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: widget.onSubscriptionAction,
                    icon: const Icon(Icons.workspace_premium),
                    label: Text(widget.subscriptionActionLabel),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('닫기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_enabled || _authorized) {
      return widget.child;
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('자산 보안 잠금'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: 24),
              Text(
                '자산 정보 보호',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '이 항목에 접근하려면 인증이 필요합니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await _promptAuthentication(prefs);
                },
                icon: const Icon(Icons.lock_open),
                label: const Text('인증하기'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
