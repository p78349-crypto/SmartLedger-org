import 'package:shared_preferences/shared_preferences.dart';

import '../database/db_encryption_key_manager.dart';
import '../services/server_config_service.dart';
import 'ledger_health_client.dart';
import 'password_key_backup_api_client.dart';
import 'password_key_backup_coordinator.dart';
import 'password_key_backup_models.dart';
import 'password_key_backup_service.dart';
import 'pref_keys.dart';

class OnlinePasswordKeyBackupFacade {
  OnlinePasswordKeyBackupFacade({
    String? ledgerBaseUrl,
    String? adminKey,
    PasswordKeyBackupCoordinator? coordinator,
    LedgerHealthClient? healthClient,
    ServerConfigService? serverConfigService,
  }) : _ledgerBaseUrl = ledgerBaseUrl,
       _adminKey = adminKey,
       _coordinator =
           coordinator ??
           PasswordKeyBackupCoordinator(
             cryptoService: PasswordKeyBackupService(),
           ),
       _healthClient = healthClient ?? LedgerHealthClient(),
       _serverConfigService = serverConfigService ?? ServerConfigService();

  final String? _ledgerBaseUrl;
  final String? _adminKey;
  final PasswordKeyBackupCoordinator _coordinator;
  final LedgerHealthClient _healthClient;
  final ServerConfigService _serverConfigService;

  static Future<KeyBackupServerPolicyMode> loadPolicyMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.ledgerKeyBackupPolicyMode);
    return KeyBackupServerPolicyModeX.fromString(raw);
  }

  static Future<void> savePolicyMode(KeyBackupServerPolicyMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.ledgerKeyBackupPolicyMode, mode.value);
  }

  Future<PasswordKeyBackupResult> bootstrapAccount({
    required String accountId,
    required String password,
  }) async {
    final context = await _resolveContext();
    if (context.result != null) return context.result!;

    return _coordinator.bootstrap(
      apiClient: context.apiClient!,
      accountId: accountId,
      password: password,
    );
  }

  Future<PasswordKeyBackupResult> restoreWithPassword({
    required String accountId,
    required String password,
  }) async {
    final context = await _resolveContext();
    if (context.result != null) return context.result!;

    final result = await _coordinator.restoreWithPassword(
      apiClient: context.apiClient!,
      accountId: accountId,
      password: password,
    );

    return _applyRestoredDbKeyIfPresent(result);
  }

  Future<PasswordKeyBackupResult> restoreWithRecoveryKey({
    required String accountId,
    required String recoveryKeyBase64,
  }) async {
    final context = await _resolveContext();
    if (context.result != null) return context.result!;

    final result = await _coordinator.restoreWithRecoveryKey(
      apiClient: context.apiClient!,
      accountId: accountId,
      recoveryKeyBase64: recoveryKeyBase64,
    );

    return _applyRestoredDbKeyIfPresent(result);
  }

  Future<PasswordKeyBackupResult> rotatePassword({
    required String accountId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final context = await _resolveContext();
    if (context.result != null) return context.result!;

    return _coordinator.rotatePassword(
      apiClient: context.apiClient!,
      accountId: accountId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<_ResolvedContext> _resolveContext() async {
    final mode = await loadPolicyMode();
    if (mode == KeyBackupServerPolicyMode.disabled) {
      return _ResolvedContext(
        result: PasswordKeyBackupResult.disabled('서버 연동이 비활성화되어 로컬 모드로 진행합니다.'),
      );
    }

    final address = _ledgerBaseUrl?.trim().isNotEmpty == true
        ? _ledgerBaseUrl!.trim()
        : (await _serverConfigService.getServerAddress())?.trim();
    final key = _adminKey?.trim().isNotEmpty == true
        ? _adminKey!.trim()
        : (await _serverConfigService.getAdminKey())?.trim();

    if (address == null || address.isEmpty || key == null || key.isEmpty) {
      if (mode == KeyBackupServerPolicyMode.required) {
        return _ResolvedContext(
          result: PasswordKeyBackupResult.offline(
            '서버 설정이 필요합니다. (required 모드)',
          ),
        );
      }
      return _ResolvedContext(
        result: PasswordKeyBackupResult.disabled('서버 설정이 없어 로컬 모드로 진행합니다.'),
      );
    }

    final ledgerBaseUrl = _normalizeLedgerBaseUrl(address);
    final healthy = await _healthClient.check(
      ledgerBaseUrl: ledgerBaseUrl,
      adminKey: key,
    );

    if (!healthy) {
      if (mode == KeyBackupServerPolicyMode.required) {
        return _ResolvedContext(
          result: PasswordKeyBackupResult.offline(
            '서버 연결이 필요합니다. (required 모드)',
          ),
        );
      }
      return _ResolvedContext(
        result: PasswordKeyBackupResult.disabled('서버 오프라인으로 로컬 모드로 진행합니다.'),
      );
    }

    return _ResolvedContext(
      apiClient: PasswordKeyBackupApiClient(
        ledgerBaseUrl: ledgerBaseUrl,
        adminKey: key,
      ),
    );
  }

  String _normalizeLedgerBaseUrl(String address) {
    final trimmed = address.trim().replaceAll(RegExp(r'/$'), '');
    if (trimmed.endsWith('/api/ledger')) return trimmed;
    return '$trimmed/api/ledger';
  }

  Future<PasswordKeyBackupResult> _applyRestoredDbKeyIfPresent(
    PasswordKeyBackupResult result,
  ) async {
    if (!result.isSuccess) return result;

    final key = result.restoredDbKey;
    if (key == null || key.isEmpty) return result;

    final applied = await DbEncryptionKeyManager.restoreKeyFromAnyBase64(key);
    if (applied) return result;

    return PasswordKeyBackupResult.failed('복구 키를 받았지만 로컬 DB 키 적용에 실패했습니다.');
  }
}

class _ResolvedContext {
  const _ResolvedContext({this.apiClient, this.result});

  final PasswordKeyBackupApiClient? apiClient;
  final PasswordKeyBackupResult? result;
}
