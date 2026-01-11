import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/backup_crypto.dart';

void main() {
  group('BackupCrypto', () {
    test('isEncryptedEnvelopeText returns false for non-JSON', () {
      expect(BackupCrypto.isEncryptedEnvelopeText('not json'), false);
    });

    test('isEncryptedEnvelopeText returns false for JSON without format', () {
      expect(BackupCrypto.isEncryptedEnvelopeText(jsonEncode({'v': 1})), false);
    });

    test('encryptJsonPayload produces an envelope JSON with format', () async {
      final encrypted = await BackupCrypto.encryptJsonPayload(
        plainJson: '{"hello":"world"}',
        password: 'pw1234',
      );

      expect(BackupCrypto.isEncryptedEnvelopeText(encrypted), true);

      final decoded = jsonDecode(encrypted);
      expect(decoded, isA<Map>());
      expect(decoded['format'], BackupCrypto.envelopeFormat);
      expect(decoded['v'], BackupCrypto.envelopeVersion);
      expect(decoded['cipher'], 'aes-256-gcm');
      expect(decoded['salt'], isA<String>());
      expect(decoded['nonce'], isA<String>());
      expect(decoded['ct'], isA<String>());
      expect(decoded['mac'], isA<String>());
    });

    test('encrypt/decrypt roundtrip returns original JSON', () async {
      const plainJson = '{"a":1,"b":"text"}';
      const password = 'pw!@#123';

      final encrypted = await BackupCrypto.encryptJsonPayload(
        plainJson: plainJson,
        password: password,
      );

      final decrypted = await BackupCrypto.decryptJsonEnvelope(
        encryptedEnvelopeJson: encrypted,
        password: password,
      );

      expect(decrypted, plainJson);
    });

    test('encryptJsonPayload throws when password is empty', () async {
      expect(
        () => BackupCrypto.encryptJsonPayload(
          plainJson: '{"a":1}',
          password: '   ',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('백업 암호가 비어있습니다'),
          ),
        ),
      );
    });

    test('decryptJsonEnvelope throws when password is empty', () async {
      expect(
        () => BackupCrypto.decryptJsonEnvelope(
          encryptedEnvelopeJson: jsonEncode({'format': BackupCrypto.envelopeFormat}),
          password: '',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('백업 암호가 비어있습니다'),
          ),
        ),
      );
    });

    test('decryptJsonEnvelope throws when not a map JSON', () async {
      expect(
        () => BackupCrypto.decryptJsonEnvelope(
          encryptedEnvelopeJson: jsonEncode(['not', 'a', 'map']),
          password: 'pw',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('암호화 백업 형식이 올바르지 않습니다'),
          ),
        ),
      );
    });

    test('decryptJsonEnvelope throws when format is incorrect', () async {
      expect(
        () => BackupCrypto.decryptJsonEnvelope(
          encryptedEnvelopeJson: jsonEncode({'format': 'NOPE'}),
          password: 'pw',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('암호화 백업이 아닙니다'),
          ),
        ),
      );
    });

    test('decryptJsonEnvelope throws when envelope fields are missing', () async {
      final broken = jsonEncode({
        'format': BackupCrypto.envelopeFormat,
        'v': BackupCrypto.envelopeVersion,
        'salt': 'abc',
        // nonce/ct/mac missing
      });

      expect(
        () => BackupCrypto.decryptJsonEnvelope(
          encryptedEnvelopeJson: broken,
          password: 'pw',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('암호화 백업 데이터가 손상되었습니다'),
          ),
        ),
      );
    });

    test('decryptJsonEnvelope throws with wrong password', () async {
      const plainJson = '{"secret":true}';
      final encrypted = await BackupCrypto.encryptJsonPayload(
        plainJson: plainJson,
        password: 'correct',
      );

      expect(
        () => BackupCrypto.decryptJsonEnvelope(
          encryptedEnvelopeJson: encrypted,
          password: 'wrong',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('암호가 올바르지 않거나'),
          ),
        ),
      );
    });
  });
}
