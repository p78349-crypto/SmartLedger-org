import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '_verify_current_user_password_dialog.dart';
import '_verify_current_user_pin_dialog.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/user_password_service.dart';
import '../services/user_pin_service.dart';
import '../utils/account_name_language_tag.dart';
import '../utils/constants.dart';
import '../utils/date_formats.dart';
import '../utils/dialog_utils.dart';
import '../utils/pref_keys.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/state_placeholders.dart';

part 'backup_screen_auth.dart';
part 'backup_screen_settings.dart';
part 'backup_screen_actions.dart';
part 'backup_screen_restore.dart';
part 'backup_screen_build.dart';

class BackupScreen extends StatefulWidget {
  final String accountName;
  const BackupScreen({super.key, required this.accountName});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupFileInfo {
  const _BackupFileInfo({
    required this.file,
    required this.fileName,
    required this.modified,
    required this.sizeInKb,
  });

  final File file;
  final String fileName;
  final DateTime modified;
  final String sizeInKb;
}

enum _BackupAuthChoice { biometric, pin, password, exit }

enum _BackupType { full, transactionsOnly, assetsOnly, wmsOnly }

class _BackupAuthChoiceDialog extends StatelessWidget {
  const _BackupAuthChoiceDialog({
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
      title: const Text('백업 보호 인증'),
      content: const Text('사용할 인증 방법을 선택하세요.'),
      actions: [
        if (canBiometric)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_BackupAuthChoice.biometric),
            icon: const Icon(Icons.fingerprint),
            label: const Text('지문'),
          ),
        if (canPin)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_BackupAuthChoice.pin),
            icon: const Icon(Icons.lock_outline),
            label: const Text('PIN'),
          ),
        if (canPassword)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_BackupAuthChoice.password),
            icon: const Icon(Icons.password_outlined),
            label: const Text('비번'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_BackupAuthChoice.exit),
          child: const Text('취소'),
        ),
      ],
    );
  }
}

class _BackupScreenState extends State<BackupScreen> {
  final AuthService _authService = AuthService();
  final UserPinService _userPinService = UserPinService();
  final UserPasswordService _userPasswordService = UserPasswordService();

  String? _backupStatus;
  bool _isProcessing = false;
  List<_BackupFileInfo> _backupFiles = [];
  String? _backupDirectory;
  bool _isLoading = true;
  String? _registeredEmail;
  bool _backupEncryptionEnabled = false;
  bool _backupTwoFactorEnabled = false;
  _BackupType _selectedBackupType = _BackupType.full;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
    _loadRegisteredEmail();
    _loadBackupEncryptionEnabled();
    _loadBackupTwoFactorEnabled();
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}
