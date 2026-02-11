import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
// intl not required here; use DateFormatter where needed
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '_verify_current_user_password_dialog.dart';
import '_verify_current_user_pin_dialog.dart';
import 'asset_allocation_screen.dart';
import 'asset_dashboard_screen.dart';
import 'asset_input_screen.dart';
import 'asset_simple_input_screen.dart';
import '../services/asset_service.dart';
import '../services/auth_service.dart';
import '../services/root_pin_service.dart';
import '../services/user_password_service.dart';
import '../services/user_pin_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';
import '../utils/utils.dart';
import '../widgets/smart_input_field.dart';

part 'asset_tab_screen_auth.dart';
part 'asset_tab_screen_auth_dialogs.dart';
part 'asset_tab_screen_logic.dart';
part 'asset_tab_screen_build.dart';
part 'asset_tab_screen_build_widgets.dart';

enum _AssetSubview { none, expenses, savings }

enum _AssetAuthChoice { biometric, pin, password, exit }

class _AssetAuthChoiceDialog extends StatelessWidget {
  const _AssetAuthChoiceDialog({
    required this.canPin,
    required this.canPassword,
    required this.canBiometric,
  });

  final bool canPin;
  final bool canPassword;
  final bool canBiometric;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('자산 보호 인증'),
      content: const Text('사용할 인증 방법을 선택하세요.'),
      actions: [
        if (canBiometric)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_AssetAuthChoice.biometric),
            icon: const Icon(IconCatalog.fingerprint),
            label: const Text('지문'),
          ),
        if (canPin)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_AssetAuthChoice.pin),
            icon: const Icon(IconCatalog.lockOutline),
            label: const Text('PIN'),
          ),
        if (canPassword)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_AssetAuthChoice.password),
            icon: const Icon(IconCatalog.passwordOutlined),
            label: const Text('비번'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_AssetAuthChoice.exit),
          child: const Text('취소'),
        ),
      ],
    );
  }
}

class AssetTabScreen extends StatefulWidget {
  final String accountName;
  final bool showAccountHeading;
  const AssetTabScreen({
    super.key,
    required this.accountName,
    this.showAccountHeading = true,
  });

  @override
  State<AssetTabScreen> createState() => _AssetTabScreenState();
}

class _AssetTabScreenState extends State<AssetTabScreen> {
  bool _loading = true;
  List<Asset> _assets = const [];
  _AssetSubview _activeSubview = _AssetSubview.none;

  // 생체 인증 관련
  bool _isAuthenticated = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isDeviceSupported = false;
  bool _biometricAuthEnabled = false;

  final AuthService _authService = AuthService();
  final UserPinService _userPinService = UserPinService();
  final UserPasswordService _userPasswordService = UserPasswordService();

  bool _rootAuthEnabled = true;
  String _rootAuthMode = 'integrated';

  bool _rootPinEnabled = false;
  bool _rootPinConfigured = false;
  final RootPinService _rootPinService = RootPinService();

  static const Duration _autoLockIdleTimeout = Duration(minutes: 1);
  Timer? _autoLockTimer;

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _checkDeviceAuthSupport();
    _loadBiometricSettings();
    _loadRootAuthEnabled();
    _loadRootAuthMode();
    _loadRootPinState();
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}

String _formatExportStamp(DateTime date) {
  return DateFormatter.fileNameDateTime.format(date);
}
