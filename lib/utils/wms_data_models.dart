/// WMS 데이터 모델
///
/// WmsInventoryInput, WmsExpiryInput, WmsValidationResult,
/// WmsOperationResult, WmsOperationType, WmsInputSource
library;

/// 재고 아이템 입력 인터페이스
class WmsInventoryInput {
  final String name;
  final String? barcode;
  final double currentStock;
  final String unit;
  final double threshold;
  final double bundleSize;
  final String category;
  final String? detailCategory;
  final String location;

  const WmsInventoryInput({
    required this.name,
    this.barcode,
    this.currentStock = 0.0,
    this.unit = '',
    this.threshold = 1.0,
    this.bundleSize = 1.0,
    this.category = '생활용품',
    this.detailCategory,
    this.location = '기타',
  });

  /// 빠른 생성 (품목명만)
  factory WmsInventoryInput.quick({required String name}) {
    return WmsInventoryInput(name: name);
  }

  /// 전체 정보 생성
  factory WmsInventoryInput.full({
    required String name,
    String? barcode,
    required double currentStock,
    required String unit,
    required double threshold,
    double bundleSize = 1.0,
    String category = '생활용품',
    String? detailCategory,
    String location = '기타',
  }) {
    return WmsInventoryInput(
      name: name,
      barcode: barcode,
      currentStock: currentStock,
      unit: unit,
      threshold: threshold,
      bundleSize: bundleSize,
      category: category,
      detailCategory: detailCategory,
      location: location,
    );
  }

  /// 유효성 검사
  WmsValidationResult validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('품목명을 입력하세요');
    }
    if (currentStock < 0) {
      errors.add('재고는 0 이상이어야 합니다');
    }
    if (threshold < 0) {
      errors.add('알림 기준은 0 이상이어야 합니다');
    }
    if (bundleSize <= 0) {
      errors.add('묶음 크기는 0보다 커야 합니다');
    }
    if (location.trim().isEmpty) {
      errors.add('보관 위치를 입력하세요');
    }

    return WmsValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}

/// 유통기한 아이템 입력 인터페이스
class WmsExpiryInput {
  final String name;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final String memo;
  final double quantity;
  final String unit;
  final String category;
  final String location;
  final double price;
  final String supplier;
  final List<String> healthTags;

  const WmsExpiryInput({
    required this.name,
    required this.purchaseDate,
    required this.expiryDate,
    this.memo = '',
    this.quantity = 1.0,
    this.unit = '',
    this.category = '기타',
    this.location = '냉장',
    this.price = 0.0,
    this.supplier = '',
    this.healthTags = const [],
  });

  WmsValidationResult validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('식품명을 입력하세요');
    }
    if (expiryDate.isBefore(purchaseDate)) {
      errors.add('유통기한은 구입일 이후여야 합니다');
    }
    if (quantity <= 0) {
      errors.add('수량은 0보다 커야 합니다');
    }
    if (price < 0) {
      errors.add('가격은 0 이상이어야 합니다');
    }

    return WmsValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}

/// 유효성 검사 결과
class WmsValidationResult {
  final bool isValid;
  final List<String> errors;

  const WmsValidationResult({
    required this.isValid,
    this.errors = const <String>[],
  });
}

/// 작업 결과
class WmsOperationResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final String? warningMessage;
  final WmsOperationType type;

  const WmsOperationResult._({
    required this.success,
    this.data,
    this.errorMessage,
    this.warningMessage,
    this.type = WmsOperationType.success,
  });

  factory WmsOperationResult.success(T? data) {
    return WmsOperationResult._(success: true, data: data);
  }

  factory WmsOperationResult.failure(String message) {
    return WmsOperationResult._(
      success: false,
      errorMessage: message,
      type: WmsOperationType.failure,
    );
  }

  factory WmsOperationResult.duplicate(T existingData) {
    return WmsOperationResult._(
      success: false,
      data: existingData,
      errorMessage: '이미 존재하는 품목입니다',
      type: WmsOperationType.duplicate,
    );
  }

  factory WmsOperationResult.warning(T? data, String message) {
    return WmsOperationResult._(
      success: true,
      data: data,
      warningMessage: message,
      type: WmsOperationType.warning,
    );
  }
}

enum WmsOperationType { success, failure, duplicate, warning }

/// 입력 소스
enum WmsInputSource {
  manual, // 수동 입력 (재고 관리 화면)
  quickUse, // 빠른 차감
  shoppingCart, // 장바구니
  voiceCommand, // 음성 명령
  autoSync, // 자동 동기화
  draftRestore, // 임시저장 복원
}
