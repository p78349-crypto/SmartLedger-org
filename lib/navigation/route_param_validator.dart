import 'package:flutter/foundation.dart';
import 'app_routes.dart';

part 'route_param_validator_food_specs.dart';
part 'route_param_validator_transaction_specs.dart';

/// 딥링크 파라미터 타입 정의
enum ParamType { string, integer, double_, date, boolean, enum_ }

/// 개별 파라미터 검증 스펙
@immutable
class RouteParamSpec {
  final String name;
  final ParamType type;
  final int maxLength;
  final Pattern? allowedPattern;
  final Set<String>? allowedValues;

  const RouteParamSpec({
    required this.name,
    required this.type,
    this.maxLength = 200,
    this.allowedPattern,
    this.allowedValues,
  });
}

/// 검증 결과
class ValidationResult {
  final Map<String, String> validated;
  final List<String> rejected;

  const ValidationResult({required this.validated, required this.rejected});

  bool get isValid => rejected.isEmpty;
}

/// 딥링크 파라미터 검증 서비스
///
/// 음성 어시스턴트(Bixby, Siri, Google)로부터 전달된 파라미터를
/// 화이트리스트 기반으로 검증하여 보안 위험을 방지합니다.
class RouteParamValidator {
  RouteParamValidator._();

  /// Route별 허용 파라미터 명세
  static final Map<String, List<RouteParamSpec>> routeSpecs = {
    AppRoutes.foodExpiry: _buildFoodExpirySpecs(),
    AppRoutes.transactionAdd: _buildTransactionAddSpecs(),
    AppRoutes.transactionAddIncome: _buildTransactionAddIncomeSpecs(),
  };

  /// 파라미터 검증
  ///
  /// [route] - 대상 라우트
  /// [params] - 검증할 파라미터
  ///
  /// Returns: ValidationResult (validated, rejected)
  static ValidationResult validate(String route, Map<String, String> params) {
    final specs = routeSpecs[route];
    if (specs == null) {
      return ValidationResult(
        validated: const {},
        rejected: params.keys.toList(),
      );
    }

    final validated = <String, String>{};
    final rejected = <String>[];
    final specsByName = {for (final spec in specs) spec.name: spec};

    for (final entry in params.entries) {
      final spec = specsByName[entry.key];
      if (spec == null) {
        rejected.add(entry.key);
        continue;
      }

      final value = entry.value;

      // 길이 검증
      if (value.length > spec.maxLength) {
        debugPrint(
          'RouteParamValidator: Rejected ${entry.key} - '
          'too long (${value.length} > ${spec.maxLength})',
        );
        rejected.add(entry.key);
        continue;
      }

      // 빈 값 허용 안함
      if (value.trim().isEmpty) {
        rejected.add(entry.key);
        continue;
      }

      // 타입별 검증
      bool isValid = false;
      switch (spec.type) {
        case ParamType.integer:
          isValid = int.tryParse(value) != null;
          if (!isValid) {
            debugPrint(
              'RouteParamValidator: Rejected ${entry.key} - not an integer',
            );
          }

        case ParamType.double_:
          isValid = double.tryParse(value) != null;
          if (!isValid) {
            debugPrint(
              'RouteParamValidator: Rejected ${entry.key} - not a number',
            );
          }

        case ParamType.date:
          // ISO-8601 또는 기본 날짜 형식
          isValid =
              DateTime.tryParse(value) != null ||
              RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);
          if (!isValid) {
            debugPrint(
              'RouteParamValidator: Rejected ${entry.key} - invalid date',
            );
          }

        case ParamType.boolean:
          isValid = value == 'true' || value == 'false';
          if (!isValid) {
            debugPrint(
              'RouteParamValidator: Rejected ${entry.key} - not a boolean',
            );
          }

        case ParamType.enum_:
          isValid = spec.allowedValues!.contains(value);
          if (!isValid) {
            debugPrint(
              'RouteParamValidator: Rejected ${entry.key} - '
              'not in allowed values: $value',
            );
          }

        case ParamType.string:
          // 패턴 검증
          if (spec.allowedPattern != null) {
            final pattern = spec.allowedPattern;
            isValid = pattern is RegExp && pattern.hasMatch(value);
            if (!isValid) {
              debugPrint(
                'RouteParamValidator: Rejected ${entry.key} - '
                'pattern mismatch',
              );
            }
          } else {
            isValid = true;
          }

          // 추가 보안 검증 (SQL Injection, XSS)
          if (isValid) {
            if (_containsSqlKeywords(value)) {
              debugPrint(
                'RouteParamValidator: Rejected ${entry.key} - '
                'SQL injection attempt',
              );
              isValid = false;
            } else if (_containsHtmlTags(value)) {
              debugPrint(
                'RouteParamValidator: Rejected ${entry.key} - XSS attempt',
              );
              isValid = false;
            }
          }
      }

      if (isValid) {
        validated[entry.key] = value;
      } else {
        rejected.add(entry.key);
      }
    }

    return ValidationResult(validated: validated, rejected: rejected);
  }

  /// SQL 키워드 포함 여부 검사
  static bool _containsSqlKeywords(String value) {
    final lower = value.toLowerCase();
    final sqlKeywords = [
      'drop',
      'delete',
      'insert',
      'update',
      'select',
      'union',
      'alter',
      'create',
      'exec',
      'execute',
      '--',
      ';',
      '/*',
      '*/',
    ];
    return sqlKeywords.any(lower.contains);
  }

  /// HTML 태그 포함 여부 검사
  static bool _containsHtmlTags(String value) {
    return value.contains(RegExp(r'<[^>]*>'));
  }
}
