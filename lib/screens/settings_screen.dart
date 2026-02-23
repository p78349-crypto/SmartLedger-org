import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'application_settings_screen.dart';
import 'voice_shortcuts_screen.dart';
import '_verify_current_user_password_dialog.dart';
import '_verify_current_user_pin_dialog.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/home_server_sync_service.dart';
import '../services/account_service.dart';
import '../services/user_password_service.dart';
import '../services/user_pin_service.dart';
import '../services/user_pref_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';
import '../widgets/background_widget.dart';
import '../database/db_encryption_key_manager.dart';
import '../services/server_config_service.dart';
import 'launch_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

part 'settings_screen_password.dart';
part 'settings_screen_pin.dart';
part 'settings_screen_cards.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _backupEncryptionEnabled = false;
  bool _backupTwoFactorEnabled = false;
  bool _userPinEnabled = false;
  bool _userPinConfigured = false;
  bool _userPasswordEnabled = false;
  bool _userPasswordConfigured = false;
  bool _userBiometricEnabled = false;

  bool _zeroQuickButtonsEnabled = false;
  final UserPinService _userPinService = UserPinService();
  final UserPasswordService _userPasswordService = UserPasswordService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final backupEncryptionEnabled =
        prefs.getBool(PrefKeys.backupEncryptionEnabled) ?? false;
    final backupTwoFactorEnabled =
        prefs.getBool(PrefKeys.backupTwoFactorEnabled) ?? false;

    final userPinEnabled = prefs.getBool(PrefKeys.userPinEnabled) ?? false;
    final userPinConfigured = _userPinService.isPinConfigured(prefs);

    final userPasswordEnabled =
        prefs.getBool(PrefKeys.userPasswordEnabled) ?? false;
    final userPasswordConfigured = _userPasswordService.isPasswordConfigured(
      prefs,
    );

    final userBiometricEnabled =
        prefs.getBool(PrefKeys.userBiometricEnabled) ?? false;
    final zeroQuickButtonsEnabled =
        prefs.getBool(PrefKeys.zeroQuickButtonsEnabled) ?? false;

    if (userPinEnabled && !userPinConfigured) {
      await prefs.setBool(PrefKeys.userPinEnabled, false);
    }
    if (userPasswordEnabled && !userPasswordConfigured) {
      await prefs.setBool(PrefKeys.userPasswordEnabled, false);
    }
    if (!mounted) return;
    setState(() {
      _backupEncryptionEnabled = backupEncryptionEnabled;
      _backupTwoFactorEnabled = backupTwoFactorEnabled;
      _userPinEnabled = userPinEnabled && userPinConfigured;
      _userPinConfigured = userPinConfigured;
      _userPasswordEnabled = userPasswordEnabled && userPasswordConfigured;
      _userPasswordConfigured = userPasswordConfigured;
      _userBiometricEnabled = userBiometricEnabled;
      _zeroQuickButtonsEnabled = zeroQuickButtonsEnabled;
      _isLoading = false;
    });
  }

  Future<void> _showServerConfigDialog() async {
    final serverConfigService = ServerConfigService();
    final currentAddress = await serverConfigService.getServerAddress() ?? '';
    final currentKey = await serverConfigService.getAdminKey() ?? '';

    final addressController = TextEditingController(text: currentAddress);
    final keyController = TextEditingController(text: currentKey);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('서버 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: '서버 주소',
                  hintText: '예: http://10.14.0.1:8787',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: '관리자 키',
                  hintText: 'X-Admin-Key',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                await serverConfigService.saveServerConfig(
                  addressController.text.trim(),
                  keyController.text.trim(),
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('서버 설정이 저장되었습니다.')),
                );
                
                // 만약 설정 화면이 유일한 화면이라면 (LaunchScreen에서 넘어온 경우)
                // 다시 LaunchScreen으로 이동하여 서버 연결을 재시도합니다.
                if (!Navigator.of(context).canPop()) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LaunchScreen()),
                  );
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _resolveSyncAccountName() async {
    final last = await UserPrefService.getLastAccountName();
    if (last != null && last.isNotEmpty && last != 'ROOT') {
      return last;
    }
    final accounts = AccountService().accounts;
    for (final account in accounts) {
      if (account.name != 'ROOT') {
        return account.name;
      }
    }
    return null;
  }

  Future<void> _runManualSync() async {
    final accountName = await _resolveSyncAccountName();
    if (accountName == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('동기화할 일반 계정이 없습니다.')),
      );
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await HomeServerSyncService().syncAllForAccount(accountName);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? null : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        BackgroundHelper.colorNotifier,
        BackgroundHelper.typeNotifier,
        BackgroundHelper.imagePathNotifier,
        BackgroundHelper.blurNotifier,
      ]),
      builder: (context, _) {
        final bgColor = BackgroundHelper.colorNotifier.value;
        final bgType = BackgroundHelper.typeNotifier.value;
        final bgImagePath = BackgroundHelper.imagePathNotifier.value;
        final bgBlur = BackgroundHelper.blurNotifier.value;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text('설정'),
            backgroundColor: bgType == 'image' ? Colors.transparent : null,
            elevation: 0,
          ),
          extendBodyBehindAppBar: bgType == 'image',
          body: Stack(
            children: [
              if (bgType == 'image' && bgImagePath != null) ...[
                Positioned.fill(
                  child: Image.file(
                    File(bgImagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        ColoredBox(color: bgColor),
                  ),
                ),
                if (bgBlur > 0)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),
                Positioned.fill(
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
                ),
              ],
              ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  buildSectionHeader(context, '애플리케이션'),
                  buildSettingsCard(
                    context,
                    icon: Icons.cloud_sync_outlined,
                    title: '서버 설정',
                    subtitle: '데이터 동기화를 위한 서버 주소 및 관리자 키 설정',
                    onTap: _showServerConfigDialog,
                  ),
                  const SizedBox(height: 12),
                  buildSettingsCard(
                    context,
                    icon: Icons.sync,
                    title: '지금 동기화',
                    subtitle: '현재 계정 데이터를 서버와 즉시 동기화합니다.',
                    onTap: _runManualSync,
                  ),
                  const SizedBox(height: 12),
                  buildSettingsCard(
                    context,
                    icon: Icons.tune_outlined,
                    title: '애플리케이션 설정',
                    subtitle: '테마와 배경을 앱 안에서 바로 조정합니다.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ApplicationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  buildSettingsCard(
                    context,
                    icon: Icons.mic_outlined,
                    title: '음성 단축어',
                    subtitle: 'Bixby, Siri, Google Assistant 단축어 설정',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VoiceShortcutsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  buildSectionHeader(context, '보안 및 백업'),
                  buildSettingsCard(
                    context,
                    icon: Icons.key_outlined,
                    title: '데이터베이스 암호화 키 백업',
                    subtitle: '기기 분실 시 데이터 복구를 위한 키 내보내기',
                    onTap: _isLoading ? null : exportDbEncryptionKey,
                  ),
                  const SizedBox(height: 12),
                  buildSettingsCard(
                    context,
                    icon: Icons.lock_open_outlined,
                    title: '백업 암호화 해지',
                    subtitle:
                        (_backupEncryptionEnabled || _backupTwoFactorEnabled)
                        ? '상태: 사용 중'
                        : '상태: 미사용',
                    enabled:
                        !_isLoading &&
                        (_backupEncryptionEnabled || _backupTwoFactorEnabled),
                    onTap: disableBackupEncryption,
                  ),
                  const SizedBox(height: 12),
                  buildSwitchCard(
                    context,
                    icon: Icons.password_outlined,
                    title: '비밀번호 사용',
                    subtitle: _userPasswordConfigured
                        ? (_userPasswordEnabled ? '상태: 사용 중' : '상태: 미사용')
                        : '상태: 미설정',
                    value: _userPasswordEnabled,
                    onChanged: _isLoading ? null : setUserPasswordEnabled,
                  ),
                  if (_userPasswordEnabled) ...[
                    const SizedBox(height: 12),
                    buildSettingsCard(
                      context,
                      icon: Icons.lock_reset_outlined,
                      title: '비밀번호 변경',
                      subtitle: '기존 비밀번호 확인 후 변경',
                      onTap: _isLoading ? null : changeUserPassword,
                    ),
                  ],
                  const SizedBox(height: 12),
                  buildSwitchCard(
                    context,
                    icon: Icons.lock_outline,
                    title: '사용자 계정 PIN 사용',
                    subtitle: _userPinConfigured
                        ? (_userPinEnabled ? '상태: 사용 중' : '상태: 미사용')
                        : '상태: 미설정',
                    value: _userPinEnabled,
                    onChanged: _isLoading ? null : setUserPinEnabled,
                  ),
                  if (_userPinEnabled) ...[
                    const SizedBox(height: 12),
                    buildSettingsCard(
                      context,
                      icon: Icons.pin_outlined,
                      title: 'PIN 변경',
                      subtitle: '기존 PIN 확인 후 변경',
                      onTap: _isLoading ? null : changeUserPin,
                    ),
                  ],
                  const SizedBox(height: 12),
                  buildSwitchCard(
                    context,
                    icon: Icons.fingerprint,
                    title: '기기 인증 사용',
                    subtitle: '지문/잠금화면 등 기기 인증을 사용합니다.',
                    value: _userBiometricEnabled,
                    onChanged: _isLoading ? null : setUserBiometricEnabled,
                  ),
                  const SizedBox(height: 24),
                  buildSectionHeader(context, '입력 편의'),
                  buildSwitchCard(
                    context,
                    icon: IconCatalog.keyboardAltOutlined,
                    title: '숫자 입력 보조',
                    subtitle: '숫자 입력 시 0/00/000 버튼을 표시합니다.',
                    value: _zeroQuickButtonsEnabled,
                    onChanged: _isLoading ? null : setZeroQuickButtonsEnabled,
                  ),
                  const SizedBox(height: 24),
                  buildSectionHeader(context, '정보'),
                  buildSettingsCard(
                    context,
                    icon: Icons.description_outlined,
                    title: '오픈소스 라이선스',
                    subtitle: 'SmartLedger 라이선스 정보 확인',
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'SmartLedger',
                        applicationLegalese: 'Copyright (c) 2025 SmartLedger',
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
