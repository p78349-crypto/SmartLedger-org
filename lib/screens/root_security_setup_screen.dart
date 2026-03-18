import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/root_pin_service.dart';
import '../utils/pref_keys.dart';
import '../utils/snackbar_utils.dart';

part 'root_security_setup_screen_logic.dart';
part 'root_security_setup_screen_ui.dart';

enum RootSecurityMode { pin, biometric, password }

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
  bool _isLoading = true;
  bool _biometricAvailable = false;
  final AuthService _authService = AuthService();

  // 보안 강도: 'single' (1개 인증) 또는 'dual' (2중 인증)
  String _securityLevel = 'single';

  // 각 방식의 활성화 상태
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _passwordEnabled = false;

  // 각 방식의 설정 완료 여부 (비밀번호가 저장되어 있는지)
  bool _pinConfigured = false;
  bool _passwordConfigured = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    final enabledCount =
        (_pinEnabled ? 1 : 0) +
        (_biometricEnabled ? 1 : 0) +
        (_passwordEnabled ? 1 : 0);

    return Scaffold(
      appBar: AppBar(title: const Text('ROOT 보안 설정')),
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
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '설정한 보안은 ROOT 전용입니다',
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
                        'ROOT 접근 보안 강도',
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
                        'ROOT 접근 보호 방식 선택',
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
                              color:
                                  _securityLevel == 'dual' && enabledCount != 2
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
                        mode: RootSecurityMode.pin,
                        enabled: _pinEnabled,
                        configured: _pinConfigured,
                        onChanged: _togglePin,
                      ),
                      const SizedBox(height: 12),
                      _buildModeCard(
                        mode: RootSecurityMode.biometric,
                        enabled: _biometricEnabled,
                        configured: true, // 생체인식은 기기에 의존
                        onChanged: _biometricAvailable
                            ? _toggleBiometric
                            : null,
                        disabled: !_biometricAvailable,
                        disabledReason: '이 기기에서 사용할 수 없습니다',
                      ),
                      const SizedBox(height: 12),
                      _buildModeCard(
                        mode: RootSecurityMode.password,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
