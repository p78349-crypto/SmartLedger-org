import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/asset_pin_service.dart';
import '../services/asset_password_service.dart';
import '../utils/pref_keys.dart';
import '../utils/snackbar_utils.dart';

enum _AssetSecurityMode {
  pin,
  biometric,
  password,
}

extension _AssetSecurityModeX on _AssetSecurityMode {
  String get displayName {
    switch (this) {
      case _AssetSecurityMode.pin:
        return 'PIN';
      case _AssetSecurityMode.biometric:
        return '지문/생체인식';
      case _AssetSecurityMode.password:
        return '비밀번호';
    }
  }

  String get description {
    switch (this) {
      case _AssetSecurityMode.pin:
        return '숫자 PIN으로 보호합니다.';
      case _AssetSecurityMode.biometric:
        return '기기 지문 또는 얼굴인식으로 보호합니다.';
      case _AssetSecurityMode.password:
        return '영문/숫자 조합 비밀번호로 보호합니다.';
    }
  }

  IconData get icon {
    switch (this) {
      case _AssetSecurityMode.pin:
        return Icons.dialpad;
      case _AssetSecurityMode.biometric:
        return Icons.fingerprint;
      case _AssetSecurityMode.password:
        return Icons.password;
    }
  }
}

/// 자산 보안 설정 화면 (ROOT 보안 디자인 복제)
class AssetSecuritySettingsScreen extends StatefulWidget {
  const AssetSecuritySettingsScreen({super.key});

  @override
  State<AssetSecuritySettingsScreen> createState() =>
      _AssetSecuritySettingsScreenState();
}

class _AssetSecuritySettingsScreenState
    extends State<AssetSecuritySettingsScreen> {
  bool _isLoading = true;
  bool _biometricAvailable = false;
  final AuthService _authService = AuthService();

  // 보안 강도: 'single' (1개 인증) 또는 'dual' (2중 인증)
  String _securityLevel = 'single';

  // 각 방식의 활성화 상태
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _passwordEnabled = false;

  // 각 방식의 설정 완료 여부
  bool _pinConfigured = false;
  bool _passwordConfigured = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkBiometricAvailability();
    await _loadCurrentSettings();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _authService.canUseDeviceAuth();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
    });
  }

  Future<void> _loadCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final pinService = AssetPinService();
    final passwordService = AssetPasswordService();

    setState(() {
        _securityLevel =
          prefs.getString(PrefKeys.assetSecurityLevel) ?? 'single';
        _pinEnabled = prefs.getBool(PrefKeys.assetPinEnabled) ?? false;
        _biometricEnabled =
          prefs.getBool(PrefKeys.assetBiometricEnabled) ?? false;
        _passwordEnabled =
          prefs.getBool(PrefKeys.assetPasswordEnabled) ?? false;

      _pinConfigured = pinService.isPinConfigured(prefs);
      _passwordConfigured = passwordService.isPasswordConfigured(prefs);

      _isLoading = false;
    });
  }

  Future<void> _togglePin(bool value) async {
    if (value && !_pinConfigured) {
      await _setupPin();
    } else {
      setState(() {
        _pinEnabled = value;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final result = await _authService.authenticateDevice(
        reason: '자산 보안 생체인식을 활성화합니다',
      );
      if (!result.ok) {
        if (!mounted) return;
        SnackbarUtils.showError(context, '생체인식 테스트에 실패했습니다');
        return;
      }
    }

    setState(() {
      _biometricEnabled = value;
    });
  }

  Future<void> _togglePassword(bool value) async {
    if (value && !_passwordConfigured) {
      await _setupPassword();
    } else {
      setState(() {
        _passwordEnabled = value;
      });
    }
  }

  Future<void> _saveSettings() async {
    final enabledCount = (_pinEnabled ? 1 : 0) +
        (_biometricEnabled ? 1 : 0) +
        (_passwordEnabled ? 1 : 0);

    if (_securityLevel == 'single') {
      if (enabledCount == 0) {
        SnackbarUtils.showWarning(context, '최소 1개의 보안 방식을 선택해야 합니다');
        return;
      }
    } else {
      if (enabledCount != 2) {
        SnackbarUtils.showWarning(context, '2중 인증은 정확히 2개의 방식을 선택해야 합니다');
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.assetSecurityLevel, _securityLevel);
    await prefs.setBool(PrefKeys.assetPinEnabled, _pinEnabled);
    await prefs.setBool(PrefKeys.assetBiometricEnabled, _biometricEnabled);
    await prefs.setBool(PrefKeys.assetPasswordEnabled, _passwordEnabled);

    // 활성화된 방식이 1개면 그것을 기본값으로
    String defaultMode = '';
    if (_pinEnabled && !_biometricEnabled && !_passwordEnabled) {
      defaultMode = 'pin';
    } else if (_biometricEnabled && !_pinEnabled && !_passwordEnabled) {
      defaultMode = 'biometric';
    } else if (_passwordEnabled && !_pinEnabled && !_biometricEnabled) {
      defaultMode = 'password';
    } else {
      defaultMode = prefs.getString(PrefKeys.assetSecurityMode) ??
          (_pinEnabled
              ? 'pin'
              : (_biometricEnabled ? 'biometric' : 'password'));
    }

    await prefs.setString(PrefKeys.assetSecurityMode, defaultMode);
    await prefs.setBool(PrefKeys.assetAuthEnabled, true);
    await prefs.setBool(PrefKeys.biometricAuthEnabled, true);
    // 기존 assetAuthRequired도 동기화
    await prefs.setBool(PrefKeys.assetAuthRequired, true);

    if (!mounted) return;
    if (context.mounted) {
      SnackbarUtils.showSuccess(context, '자산 보안 설정이 저장되었습니다');
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _setupPin() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자산 PIN 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'PIN (숫자)',
                hintText: '4자리 이상',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'PIN 확인',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinController.text.trim();
              final confirm = confirmController.text.trim();

              if (pin.length < 4 || !RegExp(r'^\d+$').hasMatch(pin)) {
                SnackbarUtils.showWarning(context, 'PIN은 4자리 이상 숫자여야 합니다');
                return;
              }

              if (pin != confirm) {
                SnackbarUtils.showWarning(context, 'PIN이 일치하지 않습니다');
                return;
              }

              Navigator.of(context).pop(true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != true) {
      pinController.dispose();
      confirmController.dispose();
      return;
    }

    final pinValue = pinController.text.trim();
    pinController.dispose();
    confirmController.dispose();

    final prefs = await SharedPreferences.getInstance();
    final pinService = AssetPinService();
    await pinService.setPin(prefs, pin: pinValue);

    if (!mounted) return;
    setState(() {
      _pinConfigured = true;
      _pinEnabled = true;
    });
    if (context.mounted) {
      SnackbarUtils.showSuccess(context, '자산 PIN이 설정되었습니다');
    }
  }

  Future<void> _setupPassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자산 비밀번호 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                hintText: '최소 6자 이상',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: '비밀번호 확인',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text.trim();
              final confirm = confirmController.text.trim();

              if (password.length < 6) {
                SnackbarUtils.showWarning(
                    context, '비밀번호는 최소 6자 이상이어야 합니다');
                return;
              }

              if (password != confirm) {
                SnackbarUtils.showWarning(context, '비밀번호가 일치하지 않습니다');
                return;
              }

              Navigator.of(context).pop(true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != true) {
      passwordController.dispose();
      confirmController.dispose();
      return;
    }

    final passwordValue = passwordController.text.trim();
    passwordController.dispose();
    confirmController.dispose();

    final prefs = await SharedPreferences.getInstance();
    final passwordService = AssetPasswordService();
    await passwordService.setPassword(prefs, password: passwordValue);

    if (!mounted) return;
    setState(() {
      _passwordConfigured = true;
      _passwordEnabled = true;
    });
    if (context.mounted) {
      SnackbarUtils.showSuccess(context, '자산 비밀번호가 설정되었습니다');
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabledCount = (_pinEnabled ? 1 : 0) +
        (_biometricEnabled ? 1 : 0) +
        (_passwordEnabled ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('자산 보안 설정'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '설정한 보안은 자산 전용입니다',
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '자산 접근 보안 강도',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'single',
                            label: Text('단일 인증'),
                            icon: Icon(Icons.lock_outline),
                          ),
                          ButtonSegment<String>(
                            value: 'dual',
                            label: Text('2중 인증'),
                            icon: Icon(Icons.lock),
                          ),
                        ],
                        selected: {_securityLevel},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _securityLevel = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _securityLevel == 'single'
                            ? '여러 개 선택 가능. 로그인 시 1개만 통과하면 됩니다.'
                            : '정확히 2개 선택 필요. 로그인 시 2개 모두 통과해야 합니다.',
                        style: TextStyle(
                          color: _securityLevel == 'dual'
                              ? Colors.orange[700]
                              : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '자산 접근 보호 방식 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '선택된 방식: $enabledCount개',
                            style: TextStyle(
                              color: _securityLevel == 'dual' &&
                                      enabledCount != 2
                                  ? Colors.red
                                  : (_securityLevel == 'single' &&
                                          enabledCount == 0
                                      ? Colors.red
                                      : Colors.green),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_securityLevel == 'dual' && enabledCount != 2)
                            const Text(
                              ' (2개 필요)',
                              style: TextStyle(color: Colors.red),
                            ),
                          if (_securityLevel == 'single' && enabledCount == 0)
                            const Text(
                              ' (최소 1개 필요)',
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildModeCard(
                        mode: _AssetSecurityMode.pin,
                        enabled: _pinEnabled,
                        configured: _pinConfigured,
                        onChanged: _togglePin,
                      ),
                      const SizedBox(height: 12),
                      _buildModeCard(
                        mode: _AssetSecurityMode.biometric,
                        enabled: _biometricEnabled,
                        configured: true,
                        onChanged:
                            _biometricAvailable ? _toggleBiometric : null,
                        disabled: !_biometricAvailable,
                        disabledReason: '이 기기에서 사용할 수 없습니다',
                      ),
                      const SizedBox(height: 12),
                      _buildModeCard(
                        mode: _AssetSecurityMode.password,
                        enabled: _passwordEnabled,
                        configured: _passwordConfigured,
                        onChanged: _togglePassword,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildModeCard({
    required _AssetSecurityMode mode,
    required bool enabled,
    required bool configured,
    required void Function(bool)? onChanged,
    bool disabled = false,
    String? disabledReason,
  }) {
    final isActive = enabled && !disabled;

    return Card(
      elevation: isActive ? 4 : 2,
      color: disabled
          ? Colors.grey[200]
          : (isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerLow),
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                if (enabled) {
                  onChanged?.call(false);
                } else if (configured) {
                  onChanged?.call(true);
                } else {
                  if (mode == _AssetSecurityMode.pin) {
                    _setupPin();
                  } else if (mode == _AssetSecurityMode.password) {
                    _setupPassword();
                  } else {
                    onChanged?.call(true);
                  }
                }
              },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                mode.icon,
                size: 48,
                color: disabled
                    ? Colors.grey[400]
                    : (isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600]),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mode.displayName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: disabled ? Colors.grey[600] : null,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '사용중',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      disabled && disabledReason != null
                          ? disabledReason
                          : (!configured && !disabled
                              ? '${mode.description} (설정 필요)'
                              : mode.description),
                      style: TextStyle(
                        fontSize: 14,
                        color: disabled ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (disabled)
                Icon(
                  Icons.block,
                  color: Colors.grey[400],
                  size: 32,
                )
              else
                Checkbox(
                  value: enabled,
                  onChanged: onChanged == null
                      ? null
                      : (bool? value) => onChanged(value ?? false),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
