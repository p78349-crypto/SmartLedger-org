import 'dart:math';

/// [실험적 기능: 출시 후 배포 여부 결정]
/// 복구 코드를 통한 데이터 복구 기능을 담당하는 서비스입니다.
/// 현재는 메인 로직과 분리되어 있으며, 사용자의 요청 시 활성화될 수 있습니다.
class RecoveryCodeService {
  static final RecoveryCodeService _instance = RecoveryCodeService._internal();
  factory RecoveryCodeService() => _instance;
  RecoveryCodeService._internal();

  /// 24자리의 하이픈으로 구분된 복구 코드를 생성합니다.
  /// 예: ABCD-1234-EFGH-5678-IJKL-9012
  String generateRecoveryCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 헷갈리는 O, 0, I, 1 제외

    String part() =>
        List.generate(4, (index) => chars[random.nextInt(chars.length)]).join();

    return '${part()}-${part()}-${part()}-${part()}-${part()}-${part()}';
  }

  /// 복구 코드가 유효한 형식인지 확인합니다.
  bool isValidFormat(String code) {
    final regExp = RegExp(r'^([A-Z2-9]{4}-){5}[A-Z2-9]{4}$');
    return regExp.hasMatch(code.toUpperCase());
  }
}
