import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/root_pin_service.dart';
import '../utils/pref_keys.dart';
import '../utils/snackbar_utils.dart';

enum RootSecurityMode {
  pin,
  biometric,
  password,
}

extension RootSecurityModeX on RootSecurityMode {
  String get displayName {
    switch (this) {
      case RootSecurityMode.pin:
        return 'PIN';
      case RootSecurityMode.biometric:
        return '지문/생체인식';
      case RootSecurityMode.password:
        return '비밀번호';
    }
  }

  String get description {
    switch (this) {
      case RootSecurityMode.pin:
        return '6자리 숫자 PIN으로 보호합니다.';
      case RootSecurityMode.biometric:
        return '기기 지문 또는 얼굴인식으로 보호합니다.';
      case RootSecurityMode.password:
        return '영문/숫자 조합 비밀번호로 보호합니다.';
    }
  }

  IconData get icon {
    switch (this) {
      case RootSecurityMode.pin:
        return Icons.dialpad;
      case RootSecurityMode.biometric:
        return Icons.fingerprint;
      case RootSecurityMode.password:
        return Icons.password;
    }
  }
}

/// ROOT 보안 방식 초기 설정 화면
class RootSecuritySetupScreen extends StatefulWidget {
  const RootSecuritySetupScreen({super.key});

  @override
  State<RootSecuritySetupScreen> createState() =>
      _RootSecuritySetupScreenState();
}

class _RootSecuritySetupScreenState extends State<RootSecuritySetupScreen> {
  RootSecurityMode? _selectedMode;
  bool _isCheckingBiometric = true;
  bool _biometricAvailable = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _authService.canUseDeviceAuth();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _isCheckingBiometric = false;
    });
  }

  Future<void> _proceedWithSetup() async {
    if (_selectedMode == null) {
      SnackbarUtils.showWarning(context, '보안 방식을 선택하세요');
      return;
    }

    switch (_selectedMode!) {
      case RootSecurityMode.pin:
        await _setupPin();
        break;
      case RootSecurityMode.biometric:
        await _setupBiometric();
        break;
      case RootSecurityMode.password:
        await _setupPassword();
        break;
    }
  }

  Future<void> _setupPin() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ROOT PIN 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'PIN (6자리 숫자)',
                hintText: '000000',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'PIN 확인',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
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

              if (pin.length != 6) {
                SnackbarUtils.showWarning(context, 'PIN은 6자리 숫자여야 합니다');
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
    final pinService = RootPinService();
    await pinService.setPin(prefs, pin: pinValue);
    await prefs.setBool(PrefKeys.rootPinEnabled, true);
    await prefs.setString(PrefKeys.rootSecurityMode, 'pin');
    await prefs.setBool(PrefKeys.rootAuthEnabled, true);

    if (!mounted) return;
    SnackbarUtils.showSuccess(context, 'ROOT PIN이 설정되었습니다');
    Navigator.of(context).pop(true);
  }

  Future<void> _setupBiometric() async {
    final result = await _authService.authenticateDevice(
      reason: 'ROOT 보안을 생체인식으로 설정합니다',
    );

    if (!result.ok) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '생체인식 테스트에 실패했습니다');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.rootBiometricEnabled, true);
    await prefs.setString(PrefKeys.rootSecurityMode, 'biometric');
    await prefs.setBool(PrefKeys.rootAuthEnabled, true);

    if (!mounted) return;
    SnackbarUtils.showSuccess(context, 'ROOT 생체인식이 설정되었습니다');
    Navigator.of(context).pop(true);
  }

  Future<void> _setupPassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ROOT 비밀번호 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                hintText: '영문, 숫자 조합 (최소 8자)',
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

              if (password.length < 8) {
                SnackbarUtils.showWarning(context, '비밀번호는 최소 8자 이상이어야 합니다');
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

    // 비밀번호는 ROOT PIN Service를 사용하되, 더 긴 문자열 허용
    final passwordValue = passwordController.text.trim();
    passwordController.dispose();
    confirmController.dispose();

    final prefs = await SharedPreferences.getInstance();
    final pinService = RootPinService();
    await pinService.setPin(prefs, pin: passwordValue);
    await prefs.setBool(PrefKeys.rootPasswordEnabled, true);
    await prefs.setString(PrefKeys.rootSecurityMode, 'password');
    await prefs.setBool(PrefKeys.rootAuthEnabled, true);

    if (!mounted) return;
    SnackbarUtils.showSuccess(context, 'ROOT 비밀번호가 설정되었습니다');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ROOT 보안 설정'),
      ),
      body: _isCheckingBiometric
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ROOT 접근 보호 방식을 선택하세요',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '설정한 보안 방식은 모든 계정에 동일하게 적용됩니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildModeCard(RootSecurityMode.pin),
                        const SizedBox(height: 12),
                        if (_biometricAvailable)
                          _buildModeCard(RootSecurityMode.biometric)
                        else
                          _buildDisabledModeCard(
                            RootSecurityMode.biometric,
                            '이 기기에서 사용할 수 없습니다',
                          ),
                        const SizedBox(height: 12),
                        _buildModeCard(RootSecurityMode.password),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _selectedMode == null ? null : _proceedWithSetup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '설정하기',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildModeCard(RootSecurityMode mode) {
    final selected = _selectedMode == mode;
    return Card(
      elevation: selected ? 4 : 1,
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMode = mode;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                mode.icon,
                size: 40,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledModeCard(RootSecurityMode mode, String reason) {
    return Card(
      color: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              mode.icon,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
