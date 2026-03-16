class PasswordKeyBackupResponseParser {
  const PasswordKeyBackupResponseParser._();

  static const List<String> _directCandidates = <String>[
    'dbKey',
    'dbEncryptionKey',
    'dek',
    'dekBase64',
    'dataKey',
  ];

  static String? extractRestoredDbKey(Map<String, dynamic>? body) {
    if (body == null) return null;

    final direct = _extractFromMap(body);
    if (direct != null) return direct;

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final nested = _extractFromMap(data);
      if (nested != null) return nested;
    }

    return null;
  }

  static String? _extractFromMap(Map<String, dynamic> map) {
    for (final key in _directCandidates) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
