import 'package:flutter/foundation.dart';
import 'app_routes.dart';

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
    AppRoutes.foodExpiry: [
      // 식재료명
      RouteParamSpec(
        name: 'name',
        type: ParamType.string,
        maxLength: 50,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\(\)]+$'),
      ),
      RouteParamSpec(
        name: 'item',
        type: ParamType.string,
        maxLength: 50,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\(\)]+$'),
      ),
      RouteParamSpec(
        name: 'product',
        type: ParamType.string,
        maxLength: 50,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\(\)]+$'),
      ),
      // 수량
      const RouteParamSpec(
        name: 'quantity',
        type: ParamType.double_,
        maxLength: 10,
      ),
      const RouteParamSpec(name: 'qty', type: ParamType.double_, maxLength: 10),
      // 단위
      RouteParamSpec(
        name: 'unit',
        type: ParamType.string,
        maxLength: 10,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z]+$'),
      ),
      // 유통기한 (상대일수)
      const RouteParamSpec(
        name: 'expiryDays',
        type: ParamType.integer,
        maxLength: 10,
      ),
      const RouteParamSpec(
        name: 'days',
        type: ParamType.integer,
        maxLength: 10,
      ),
      // 유통기한 (절대날짜)
      const RouteParamSpec(
        name: 'expiryDate',
        type: ParamType.date,
        maxLength: 30,
      ),
      const RouteParamSpec(name: 'expiry', type: ParamType.date, maxLength: 30),
      // 보관 위치
      const RouteParamSpec(
        name: 'location',
        type: ParamType.enum_,
        maxLength: 20,
        allowedValues: {
          '냉장',
          '냉동',
          '실온',
          '기타',
          'fridge',
          'freezer',
          'room',
          'other',
        },
      ),
      // 카테고리
      RouteParamSpec(
        name: 'category',
        type: ParamType.string,
        maxLength: 30,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z\s]+$'),
      ),
      // 구매처
      RouteParamSpec(
        name: 'supplier',
        type: ParamType.string,
        maxLength: 50,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.]+$'),
      ),
      RouteParamSpec(
        name: 'purchasePlace',
        type: ParamType.string,
        maxLength: 50,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.]+$'),
      ),
      RouteParamSpec(
        name: 'place',
        type: ParamType.string,
        maxLength: 50,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.]+$'),
      ),
      RouteParamSpec(
        name: 'store',
        type: ParamType.string,
        maxLength: 50,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.]+$'),
      ),
      // 메모
      RouteParamSpec(
        name: 'memo',
        type: ParamType.string,
        maxLength: 100,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.\,\!\?]+$'),
      ),
      RouteParamSpec(
        name: 'note',
        type: ParamType.string,
        maxLength: 100,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.\,\!\?]+$'),
      ),
      RouteParamSpec(
        name: 'desc',
        type: ParamType.string,
        maxLength: 100,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.\,\!\?]+$'),
      ),
      // 가격
      const RouteParamSpec(
        name: 'price',
        type: ParamType.double_,
        maxLength: 15,
      ),
      // 건강 태그
      RouteParamSpec(
        name: 'healthTags',
        type: ParamType.string,
        maxLength: 100,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z\s\,\|]+$'),
      ),
      RouteParamSpec(
        name: 'tags',
        type: ParamType.string,
        maxLength: 100,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z\s\,\|]+$'),
      ),
      // 구매일
      RouteParamSpec(
        name: 'purchaseDate',
        type: ParamType.string,
        maxLength: 30,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-]+$'),
      ),
    ],

    AppRoutes.transactionAdd: [
      // 타입
      const RouteParamSpec(
        name: 'type',
        type: ParamType.enum_,
        maxLength: 20,
        allowedValues: {'expense', 'income', 'savings', 'refund'},
      ),
      // 금액
      const RouteParamSpec(
        name: 'amount',
        type: ParamType.double_,
        maxLength: 20,
      ),
      // 수량
      const RouteParamSpec(
        name: 'quantity',
        type: ParamType.double_,
        maxLength: 10,
      ),
      // 단가
      const RouteParamSpec(
        name: 'unitPrice',
        type: ParamType.double_,
        maxLength: 20,
      ),
      // 단위
      RouteParamSpec(
        name: 'unit',
        type: ParamType.string,
        maxLength: 10,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z]+$'),
      ),
      // 설명
      RouteParamSpec(
        name: 'description',
        type: ParamType.string,
        maxLength: 100,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.\,\!\?]+$'),
      ),
      // 카테고리
      RouteParamSpec(
        name: 'category',
        type: ParamType.string,
        maxLength: 30,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z\s]+$'),
      ),
      // 결제수단
      RouteParamSpec(
        name: 'paymentMethod',
        type: ParamType.string,
        maxLength: 30,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s]+$'),
      ),
      RouteParamSpec(
        name: 'payment',
        type: ParamType.string,
        maxLength: 30,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s]+$'),
      ),
      // 상점
      RouteParamSpec(
        name: 'store',
        type: ParamType.string,
        maxLength: 50,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.]+$'),
      ),
      // 메모
      RouteParamSpec(
        name: 'memo',
        type: ParamType.string,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.\,\!\?]+$'),
      ),
      // 저축 배분
      const RouteParamSpec(
        name: 'savingsAllocation',
        type: ParamType.enum_,
        maxLength: 50,
        allowedValues: {
          'assetincrease',
          'asset_increase',
          'asset',
          'assetincreaseoption',
          'expense',
        },
      ),
      // 통화
      const RouteParamSpec(
        name: 'currency',
        type: ParamType.enum_,
        maxLength: 10,
        allowedValues: {'KRW', 'USD', 'JPY', 'CNY', 'EUR'},
      ),

      // 자동 저장 (확인 플로우는 DeepLinkHandler에서 별도 안전 게이트)
      const RouteParamSpec(
        name: 'autoSubmit',
        type: ParamType.boolean,
        maxLength: 10,
      ),
      const RouteParamSpec(
        name: 'confirmed',
        type: ParamType.boolean,
        maxLength: 10,
      ),

      // 책스캔앱 OCR 연계 등: 항목/출처
      RouteParamSpec(
        name: 'items',
        type: ParamType.string,
        maxLength: 300,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\,\-\(\)\.]+$'),
      ),
      const RouteParamSpec(
        name: 'source',
        type: ParamType.enum_,
        maxLength: 20,
        allowedValues: {'ocr', 'voice'},
      ),
    ],

    AppRoutes.transactionAddIncome: [
      // 타입
      const RouteParamSpec(
        name: 'type',
        type: ParamType.enum_,
        maxLength: 20,
        allowedValues: {'expense', 'income', 'savings', 'refund'},
      ),
      // 금액
      const RouteParamSpec(
        name: 'amount',
        type: ParamType.double_,
        maxLength: 20,
      ),
      // 수량
      const RouteParamSpec(
        name: 'quantity',
        type: ParamType.double_,
        maxLength: 10,
      ),
      // 단가
      const RouteParamSpec(
        name: 'unitPrice',
        type: ParamType.double_,
        maxLength: 20,
      ),
      // 단위
      RouteParamSpec(
        name: 'unit',
        type: ParamType.string,
        maxLength: 10,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z]+$'),
      ),
      // 설명
      RouteParamSpec(
        name: 'description',
        type: ParamType.string,
        maxLength: 100,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.\,\!\?]+$'),
      ),
      // 카테고리
      RouteParamSpec(
        name: 'category',
        type: ParamType.string,
        maxLength: 30,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z\s]+$'),
      ),
      // 결제수단
      RouteParamSpec(
        name: 'paymentMethod',
        type: ParamType.string,
        maxLength: 30,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s]+$'),
      ),
      RouteParamSpec(
        name: 'payment',
        type: ParamType.string,
        maxLength: 30,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s]+$'),
      ),
      // 상점
      RouteParamSpec(
        name: 'store',
        type: ParamType.string,
        maxLength: 50,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.]+$'),
      ),
      // 메모
      RouteParamSpec(
        name: 'memo',
        type: ParamType.string,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\-\.\,\!\?]+$'),
      ),
      // 저축 배분
      const RouteParamSpec(
        name: 'savingsAllocation',
        type: ParamType.enum_,
        maxLength: 50,
        allowedValues: {
          'assetincrease',
          'asset_increase',
          'asset',
          'assetincreaseoption',
          'expense',
        },
      ),
      // 통화
      const RouteParamSpec(
        name: 'currency',
        type: ParamType.enum_,
        maxLength: 10,
        allowedValues: {'KRW', 'USD', 'JPY', 'CNY', 'EUR'},
      ),

      // 자동 저장 (확인 플로우는 DeepLinkHandler에서 별도 안전 게이트)
      const RouteParamSpec(
        name: 'autoSubmit',
        type: ParamType.boolean,
        maxLength: 10,
      ),
      const RouteParamSpec(
        name: 'confirmed',
        type: ParamType.boolean,
        maxLength: 10,
      ),

      // 책스캔앱 OCR 연계 등: 항목/출처
      RouteParamSpec(
        name: 'items',
        type: ParamType.string,
        maxLength: 300,
        allowedPattern: RegExp(r'^[가-힣a-zA-Z0-9\s\,\-\(\)\.]+$'),
      ),
      const RouteParamSpec(
        name: 'source',
        type: ParamType.enum_,
        maxLength: 20,
        allowedValues: {'ocr', 'voice'},
      ),
    ],
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
