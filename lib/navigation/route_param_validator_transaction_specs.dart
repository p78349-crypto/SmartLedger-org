part of 'route_param_validator.dart';

/// 거래 추가 라우트 파라미터 스펙
List<RouteParamSpec> _buildTransactionAddSpecs() => [
  // 타입
  const RouteParamSpec(
    name: 'type',
    type: ParamType.enum_,
    maxLength: 20,
    allowedValues: {'expense', 'income', 'savings', 'refund'},
  ),
  // 금액
  const RouteParamSpec(name: 'amount', type: ParamType.double_, maxLength: 20),
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
];

/// 수입 거래 추가 라우트 파라미터 스펙
List<RouteParamSpec> _buildTransactionAddIncomeSpecs() => [
  // 타입
  const RouteParamSpec(
    name: 'type',
    type: ParamType.enum_,
    maxLength: 20,
    allowedValues: {'expense', 'income', 'savings', 'refund'},
  ),
  // 금액
  const RouteParamSpec(name: 'amount', type: ParamType.double_, maxLength: 20),
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
];
