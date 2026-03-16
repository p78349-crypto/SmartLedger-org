import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/password_key_backup_response_parser.dart';

void main() {
  group('PasswordKeyBackupResponseParser.extractRestoredDbKey', () {
    test('returns null for null body', () {
      expect(PasswordKeyBackupResponseParser.extractRestoredDbKey(null), isNull);
    });

    test('extracts dbKey from top-level body', () {
      final body = <String, dynamic>{
        'dbKey': 'top-level-db-key',
      };

      final key = PasswordKeyBackupResponseParser.extractRestoredDbKey(body);
      expect(key, 'top-level-db-key');
    });

    test('extracts dekBase64 from nested data body', () {
      final body = <String, dynamic>{
        'data': <String, dynamic>{
          'dekBase64': 'nested-dek-key',
        },
      };

      final key = PasswordKeyBackupResponseParser.extractRestoredDbKey(body);
      expect(key, 'nested-dek-key');
    });

    test('prefers top-level candidate when both exist', () {
      final body = <String, dynamic>{
        'dbEncryptionKey': 'top-level',
        'data': <String, dynamic>{
          'dbKey': 'nested',
        },
      };

      final key = PasswordKeyBackupResponseParser.extractRestoredDbKey(body);
      expect(key, 'top-level');
    });

    test('returns null when no candidate exists', () {
      final body = <String, dynamic>{
        'status': 'ok',
        'data': <String, dynamic>{
          'message': 'no key',
        },
      };

      final key = PasswordKeyBackupResponseParser.extractRestoredDbKey(body);
      expect(key, isNull);
    });
  });
}
