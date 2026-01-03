/// 폼 필드 관련 유틸리티 함수 모음
///
/// 선택적 필드 처리, 기본값 설정, 유효성 검사 등을 제공합니다.
library;

/// 선택적 필드를 처리하여 기본값을 반환합니다.
///
/// ```dart
/// final description = getOptionalFieldValue(_descController.text, '(미입력)');
/// ```
String getOptionalFieldValue(String value, [String defaultValue = '(미입력)']) {
  final trimmed = value.trim();
  return trimmed.isNotEmpty ? trimmed : defaultValue;
}

/// 금액 필드가 유효한지 검사합니다 (필수 필드).
///
/// ```dart
/// final amount = double.tryParse(_amountController.text);
/// if (!isAmountValid(amount)) {
///   // 에러 처리
/// }
/// ```
bool isAmountValid(double? amount) {
  return amount != null && amount > 0;
}

/// 선택적 숫자 필드를 처리하여 기본값을 반환합니다.
///
/// ```dart
/// final quantity = getOptionalNumericValue(
///   int.tryParse(_qtyController.text),
///   1,
/// );
/// ```
T getOptionalNumericValue<T extends num>(T? value, T defaultValue) {
  return value ?? defaultValue;
}

/// 여러 선택적 텍스트를 결합하여 하나의 문자열로 만듭니다.
/// 비어있는 값은 제외됩니다.
///
/// ```dart
/// final description = combineOptionalTexts([bankName, productName], '(미입력)');
/// // 예: "시중은행 적금" 또는 "시중은행" 또는 "(미입력)"
/// ```
String combineOptionalTexts(
  List<String> values, [
  String defaultValue = '(미입력)',
]) {
  final nonEmpty = values
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toList();

  return nonEmpty.isEmpty ? defaultValue : nonEmpty.join(' ');
}

/// 조건에 따라 값을 처리합니다.
///
/// ```dart
/// final payment = conditionalValue(
///   isSavings,
///   _paymentController.text,
///   onTrue: '자동이체',
///   onFalse: '(미입력)',
/// );
/// ```
String conditionalValue(
  bool condition,
  String value, {
  String onTrue = '',
  String onFalse = '',
}) {
  if (value.trim().isNotEmpty) return value.trim();
  return condition ? onTrue : onFalse;
}

/// 필드 유효성 검사 결과를 담는 클래스
class FieldValidationResult {
  final bool isValid;
  final String? errorMessage;

  const FieldValidationResult({required this.isValid, this.errorMessage});

  factory FieldValidationResult.valid() {
    return const FieldValidationResult(isValid: true);
  }

  factory FieldValidationResult.invalid(String message) {
    return FieldValidationResult(isValid: false, errorMessage: message);
  }
}

/// 금액 필드를 검증합니다.
FieldValidationResult validateAmountField(
  String? value, [
  String errorMessage = '금액을 입력하세요.',
]) {
  if (value == null || value.trim().isEmpty) {
    return FieldValidationResult.invalid(errorMessage);
  }

  final amount = double.tryParse(value.trim().replaceAll(',', ''));
  if (amount == null || amount <= 0) {
    return FieldValidationResult.invalid(errorMessage);
  }

  return FieldValidationResult.valid();
}

/// 선택적 필드를 검증합니다 (항상 유효).
FieldValidationResult validateOptionalField(String? value) {
  return FieldValidationResult.valid();
}

/// 최소 길이 검증
FieldValidationResult validateMinLength(
  String? value,
  int minLength, [
  String? errorMessage,
]) {
  if (value == null || value.trim().length < minLength) {
    return FieldValidationResult.invalid(
      errorMessage ?? '$minLength자 이상 입력하세요.',
    );
  }
  return FieldValidationResult.valid();
}

/// 숫자 범위 검증
FieldValidationResult validateNumericRange<T extends num>(
  T? value,
  T min,
  T max, [
  String? errorMessage,
]) {
  if (value == null || value < min || value > max) {
    return FieldValidationResult.invalid(
      errorMessage ?? '$min ~ $max 범위로 입력하세요.',
    );
  }
  return FieldValidationResult.valid();
}
