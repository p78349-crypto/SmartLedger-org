enum KeyBackupServerPolicyMode {
  required,
  optional,
  disabled,
}

extension KeyBackupServerPolicyModeX on KeyBackupServerPolicyMode {
  String get value {
    switch (this) {
      case KeyBackupServerPolicyMode.required:
        return 'required';
      case KeyBackupServerPolicyMode.optional:
        return 'optional';
      case KeyBackupServerPolicyMode.disabled:
        return 'disabled';
    }
  }

  static KeyBackupServerPolicyMode fromString(String? raw) {
    switch (raw) {
      case 'required':
        return KeyBackupServerPolicyMode.required;
      case 'disabled':
        return KeyBackupServerPolicyMode.disabled;
      case 'optional':
      default:
        return KeyBackupServerPolicyMode.optional;
    }
  }
}

enum PasswordKeyBackupStatus {
  success,
  offline,
  disabled,
  failed,
}

class PasswordKeyBackupResult {
  const PasswordKeyBackupResult._(
    this.status, {
    this.message,
    this.recoveryKeyBase64,
    this.restoredDbKey,
  });

  final PasswordKeyBackupStatus status;
  final String? message;
  final String? recoveryKeyBase64;
  final String? restoredDbKey;

  bool get isSuccess => status == PasswordKeyBackupStatus.success;
  bool get isOffline => status == PasswordKeyBackupStatus.offline;
  bool get isDisabled => status == PasswordKeyBackupStatus.disabled;

  static PasswordKeyBackupResult success({
    String? recoveryKeyBase64,
    String? restoredDbKey,
  }) {
    return PasswordKeyBackupResult._(
      PasswordKeyBackupStatus.success,
      recoveryKeyBase64: recoveryKeyBase64,
      restoredDbKey: restoredDbKey,
    );
  }

  static PasswordKeyBackupResult offline([String? message]) {
    return PasswordKeyBackupResult._(
      PasswordKeyBackupStatus.offline,
      message: message,
    );
  }

  static PasswordKeyBackupResult disabled([String? message]) {
    return PasswordKeyBackupResult._(
      PasswordKeyBackupStatus.disabled,
      message: message,
    );
  }

  static PasswordKeyBackupResult failed([String? message]) {
    return PasswordKeyBackupResult._(
      PasswordKeyBackupStatus.failed,
      message: message,
    );
  }
}
