import 'password_key_backup_api_client.dart';
import 'password_key_backup_models.dart';
import 'password_key_backup_response_parser.dart';
import 'password_key_backup_service.dart';

class PasswordKeyBackupCoordinator {
  PasswordKeyBackupCoordinator({
    required PasswordKeyBackupService cryptoService,
  }) : _cryptoService = cryptoService;

  final PasswordKeyBackupService _cryptoService;

  Future<PasswordKeyBackupResult> bootstrap({
    required PasswordKeyBackupApiClient apiClient,
    required String accountId,
    required String password,
  }) async {
    try {
      final bootstrapData = await _cryptoService.createBootstrapData(
        accountId: accountId,
        password: password,
      );
      final response = await apiClient.bootstrap(
        bootstrapData.toPayload(accountId: accountId),
      );
      if (response.offline) {
        return PasswordKeyBackupResult.offline('서버에 연결할 수 없습니다.');
      }
      if (!response.isOk) {
        return PasswordKeyBackupResult.failed(
          _extractMessage(response) ?? '키 백업 초기화에 실패했습니다.',
        );
      }
      return PasswordKeyBackupResult.success(
        recoveryKeyBase64: bootstrapData.recoveryKeyBase64,
      );
    } catch (_) {
      return PasswordKeyBackupResult.failed('키 백업 초기화 중 오류가 발생했습니다.');
    }
  }

  Future<PasswordKeyBackupResult> restoreWithPassword({
    required PasswordKeyBackupApiClient apiClient,
    required String accountId,
    required String password,
  }) async {
    try {
      final payload = await _cryptoService.buildRecoverPayloadWithPassword(
        accountId: accountId,
        password: password,
      );
      final response = await apiClient.recover(payload);
      if (response.offline) {
        return PasswordKeyBackupResult.offline('서버에 연결할 수 없습니다.');
      }
      if (!response.isOk) {
        return PasswordKeyBackupResult.failed(
          _extractMessage(response) ?? '비밀번호 복구에 실패했습니다.',
        );
      }
      return PasswordKeyBackupResult.success(
        restoredDbKey: _extractRestoredDbKey(response),
      );
    } catch (_) {
      return PasswordKeyBackupResult.failed('비밀번호 복구 중 오류가 발생했습니다.');
    }
  }

  Future<PasswordKeyBackupResult> restoreWithRecoveryKey({
    required PasswordKeyBackupApiClient apiClient,
    required String accountId,
    required String recoveryKeyBase64,
  }) async {
    try {
      final payload = await _cryptoService.buildRecoverPayloadWithRecoveryKey(
        accountId: accountId,
        recoveryKeyBase64: recoveryKeyBase64,
      );
      final response = await apiClient.recover(payload);
      if (response.offline) {
        return PasswordKeyBackupResult.offline('서버에 연결할 수 없습니다.');
      }
      if (!response.isOk) {
        return PasswordKeyBackupResult.failed(
          _extractMessage(response) ?? '복구키 복구에 실패했습니다.',
        );
      }
      return PasswordKeyBackupResult.success(
        restoredDbKey: _extractRestoredDbKey(response),
      );
    } catch (_) {
      return PasswordKeyBackupResult.failed('복구키 복구 중 오류가 발생했습니다.');
    }
  }

  Future<PasswordKeyBackupResult> rotatePassword({
    required PasswordKeyBackupApiClient apiClient,
    required String accountId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final payload = await _cryptoService.buildRotatePayload(
        accountId: accountId,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      final response = await apiClient.rotate(payload);
      if (response.offline) {
        return PasswordKeyBackupResult.offline('서버에 연결할 수 없습니다.');
      }
      if (!response.isOk) {
        return PasswordKeyBackupResult.failed(
          _extractMessage(response) ?? '비밀번호 변경 동기화에 실패했습니다.',
        );
      }
      return PasswordKeyBackupResult.success();
    } catch (_) {
      return PasswordKeyBackupResult.failed('비밀번호 변경 동기화 중 오류가 발생했습니다.');
    }
  }

  String? _extractMessage(PasswordKeyBackupApiResponse response) {
    final body = response.jsonBody;
    if (body == null) return null;

    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();

    final error = body['error'];
    if (error is String && error.trim().isNotEmpty) return error.trim();

    return null;
  }

  String? _extractRestoredDbKey(PasswordKeyBackupApiResponse response) {
    return PasswordKeyBackupResponseParser.extractRestoredDbKey(
      response.jsonBody,
    );
  }
}
