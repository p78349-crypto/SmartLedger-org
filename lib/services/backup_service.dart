import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/asset.dart';
import '../models/asset_move.dart';
import '../models/category_hint.dart';
import '../models/emergency_transaction.dart';
import '../models/fixed_cost.dart';
import '../models/savings_plan.dart';
import '../models/shopping_cart_history_entry.dart';
import '../models/shopping_cart_item.dart';
import '../models/shopping_template_item.dart';
import '../models/transaction.dart';
import '../models/trash_entry.dart';
import 'account_option_service.dart';
import 'account_service.dart';
import 'asset_move_service.dart';
import 'asset_service.dart';
import 'budget_service.dart';
import 'emergency_fund_service.dart';
import 'fixed_cost_service.dart';
import 'income_split_service.dart';
import 'recent_input_service.dart';
import 'savings_plan_service.dart';
import 'secure_storage_service.dart';
import 'transaction_service.dart';
import 'trash_service.dart';
import 'user_pref_service.dart';
import '../utils/backup_crypto.dart';
import '../utils/constants.dart';
import '../utils/pref_keys.dart';

part 'backup_service_parse.dart';
part 'backup_service_export.dart';
part 'backup_service_save.dart';
part 'backup_service_share.dart';
part 'backup_service_import.dart';
part 'backup_service_favorites.dart';

// Top-level constant for extension access.
const int _backupFormatVersion = 1;

enum AutoBackupResult { performed, notNeeded, skippedEncryptionEnabled }

class BackupPreview {
  const BackupPreview({
    required this.sourceAccountName,
    required this.exportedAt,
    required this.lastBackupDate,
    required this.transactionCount,
    required this.assetCount,
    required this.fixedCostCount,
    required this.shoppingCartItemCount,
    required this.savingsPlanCount,
  });

  final String? sourceAccountName;
  final DateTime? exportedAt;
  final DateTime? lastBackupDate;

  final int transactionCount;
  final int assetCount;
  final int fixedCostCount;
  final int shoppingCartItemCount;
  final int savingsPlanCount;
}

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static const String _secureKeyBackupEncryptionPassword =
      'vccode1_backup_encryption_password_v1';

  bool _autoBackupSkippedByEncryptionNoticeShown = false;
  bool _backupPasswordSetupNoticeShown = false;

  /// Returns true once per app session.
  ///
  /// Used by UI to avoid spamming a repeated message when auto-backup is
  /// skipped due to encryption being enabled.
  bool consumeAutoBackupSkippedByEncryptionNoticeToken() {
    if (_autoBackupSkippedByEncryptionNoticeShown) return false;
    _autoBackupSkippedByEncryptionNoticeShown = true;
    return true;
  }

  /// Returns true once per app session.
  ///
  /// Used by UI to avoid repeatedly prompting for setting a stored backup
  /// password when encryption is enabled.
  bool consumeBackupPasswordSetupNoticeToken() {
    if (_backupPasswordSetupNoticeShown) return false;
    _backupPasswordSetupNoticeShown = true;
    return true;
  }

  Future<String?> getStoredBackupEncryptionPassword() async {
    return SecureStorageService().readString(
      _secureKeyBackupEncryptionPassword,
    );
  }

  Future<void> setStoredBackupEncryptionPassword(String password) async {
    await SecureStorageService().writeString(
      _secureKeyBackupEncryptionPassword,
      password,
    );
  }

  Future<void> clearStoredBackupEncryptionPassword() async {
    await SecureStorageService().delete(_secureKeyBackupEncryptionPassword);
  }

  bool isEncryptedBackupText(String text) {
    return BackupCrypto.isEncryptedEnvelopeText(text);
  }
}
