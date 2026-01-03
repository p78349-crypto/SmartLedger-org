/// 입력 검증 관련 유틸리티 클래스
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// 빈 문자열 검증
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "이 항목"}을(를) 입력해주세요';
    }
    return null;
  }

  /// 숫자 검증 (양수)
  static String? positiveNumber(String? value, {String? fieldName}) {
    final requiredError = required(value, fieldName: fieldName);
    if (requiredError != null) return requiredError;

    final number = double.tryParse(value!.replaceAll(',', ''));
    if (number == null) {
      return '올바른 숫자를 입력해주세요';
    }
    if (number <= 0) {
      return '0보다 큰 숫자를 입력해주세요';
    }
    return null;
  }

  /// 숫자 검증 (0 이상)
  static String? nonNegativeNumber(String? value, {String? fieldName}) {
    final requiredError = required(value, fieldName: fieldName);
    if (requiredError != null) return requiredError;

    final number = double.tryParse(value!.replaceAll(',', ''));
    if (number == null) {
      return '올바른 숫자를 입력해주세요';
    }
    if (number < 0) {
      return '0 이상의 숫자를 입력해주세요';
    }
    return null;
  }

  /// 정수 검증
  static String? integer(String? value, {String? fieldName}) {
    final requiredError = required(value, fieldName: fieldName);
    if (requiredError != null) return requiredError;

    final number = int.tryParse(value!.replaceAll(',', ''));
    if (number == null) {
      return '올바른 정수를 입력해주세요';
    }
    return null;
  }

  /// 양의 정수 검증
  static String? positiveInteger(String? value, {String? fieldName}) {
    final intError = integer(value, fieldName: fieldName);
    if (intError != null) return intError;

    final number = int.parse(value!.replaceAll(',', ''));
    if (number <= 0) {
      return '0보다 큰 정수를 입력해주세요';
    }
    return null;
  }

  /// 계정명 검증
  static String? accountName(String? value) {
    final requiredError = required(value, fieldName: '계정명');
    if (requiredError != null) return requiredError;

    final trimmed = value!.trim();
    if (trimmed.length < 2) {
      return '계정명은 2자 이상이어야 합니다';
    }
    if (trimmed.length > 20) {
      return '계정명은 20자 이하여야 합니다';
    }

    // 특수문자 제한 (기본 한글, 영문, 숫자, 공백, 일부 특수문자만 허용)
    final validPattern = RegExp(r'^[가-힣a-zA-Z0-9\s\-_]+$');
    if (!validPattern.hasMatch(trimmed)) {
      return '계정명에는 한글, 영문, 숫자, 공백, -, _만 사용할 수 있습니다';
    }

    return null;
  }

  /// 날짜 형식 검증 (yyyy-MM-dd)
  static String? dateFormat(String? value, {String? fieldName}) {
    final requiredError = required(value, fieldName: fieldName);
    if (requiredError != null) return requiredError;

    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!datePattern.hasMatch(value!)) {
      return '올바른 날짜 형식(yyyy-MM-dd)을 입력해주세요';
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return '유효한 날짜를 입력해주세요';
    }
  }

  /// 범위 검증 (최소값, 최대값)
  static String? range(num value, {num? min, num? max, String? fieldName}) {
    if (min != null && value < min) {
      return '${fieldName ?? "값"}은(는) $min 이상이어야 합니다';
    }
    if (max != null && value > max) {
      return '${fieldName ?? "값"}은(는) $max 이하여야 합니다';
    }
    return null;
  }

  /// 문자열 길이 검증
  static String? length(
    String? value, {
    int? min,
    int? max,
    String? fieldName,
  }) {
    if (value == null) {
      return required(value, fieldName: fieldName);
    }

    final length = value.trim().length;
    if (min != null && length < min) {
      return '${fieldName ?? "이 항목"}은(는) 최소 $min자 이상이어야 합니다';
    }
    if (max != null && length > max) {
      return '${fieldName ?? "이 항목"}은(는) 최대 $max자 이하여야 합니다';
    }
    return null;
  }

  /// 이메일 형식 검증
  static String? email(String? value, {String? fieldName}) {
    final requiredError = required(value, fieldName: fieldName ?? '이메일');
    if (requiredError != null) return requiredError;

    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailPattern.hasMatch(value!)) {
      return '올바른 이메일 형식을 입력해주세요';
    }
    return null;
  }

  /// 전화번호 형식 검증 (한국)
  static String? phoneNumber(String? value, {String? fieldName}) {
    final requiredError = required(value, fieldName: fieldName ?? '전화번호');
    if (requiredError != null) return requiredError;

    // 하이픈 제거
    final cleaned = value!.replaceAll(RegExp(r'[-\s]'), '');

    // 010-1234-5678 또는 02-1234-5678 형식
    final phonePattern = RegExp(r'^(01[0-9]|02|0[3-9][0-9])\d{3,4}\d{4}$');
    if (!phonePattern.hasMatch(cleaned)) {
      return '올바른 전화번호 형식을 입력해주세요';
    }
    return null;
  }

  /// 여러 검증 함수를 조합
  static String? compose(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}
