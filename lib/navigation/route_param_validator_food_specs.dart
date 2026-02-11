part of 'route_param_validator.dart';

/// 식재료 유통기한 관리 라우트 파라미터 스펙
List<RouteParamSpec> _buildFoodExpirySpecs() => [
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
    ];
