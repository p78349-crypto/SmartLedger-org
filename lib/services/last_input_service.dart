import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 마지막 입력값 중앙 저장소
///
/// 각 화면에서 입력한 값을 저장하고, 다른 화면에서 필요할 때 가져갈 수 있음.
/// Args로 직접 전달하지 않아도 되므로 화면 간 결합도 감소.
///
/// 사용 예시:
/// ```dart
/// // 저장 (지출입력 화면에서)
/// LastInputService.instance.saveTransaction(
///   paymentMethod: '농협체크카드',
///   memo: '하나로마트',
///   amount: 15000,
/// );
///
/// // 읽기 (포인트입력 화면에서)
/// final lastInput = await LastInputService.instance.getLastTransaction();
/// print(lastInput.paymentMethod); // 농협체크카드
/// ```
class LastInputService {
  LastInputService._();
  static final LastInputService instance = LastInputService._();

  static const String _keyPrefix = 'last_input_';

  // ========== 지출입력 관련 ==========

  /// 마지막 지출입력 정보 저장
  Future<void> saveTransaction({
    required String accountName,
    String? description,
    double? amount,
    double? unitPrice,
    int? quantity,
    String? paymentMethod,
    String? memo,
    String? mainCategory,
    String? subCategory,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'accountName': accountName,
      'description': description,
      'amount': amount,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'paymentMethod': paymentMethod,
      'memo': memo,
      'mainCategory': mainCategory,
      'subCategory': subCategory,
      'date': date?.toIso8601String(),
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(
      '${_keyPrefix}transaction_$accountName',
      jsonEncode(data),
    );
  }

  /// 마지막 지출입력 정보 가져오기
  Future<LastTransactionInput?> getLastTransaction(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_keyPrefix}transaction_$accountName');
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return LastTransactionInput.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ========== 쇼핑 세션 관련 ==========

  /// 쇼핑 세션 정보 저장 (장바구니 → 지출입력 → 포인트 흐름)
  Future<void> saveShoppingSession({
    required String accountName,
    String? paymentMethod,
    String? storeName,
    double? totalAmount,
    double? chargedAmount,
    int? itemCount,
    String? mainCategory,
    String? subCategory,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'accountName': accountName,
      'paymentMethod': paymentMethod,
      'storeName': storeName,
      'totalAmount': totalAmount,
      'chargedAmount': chargedAmount,
      'itemCount': itemCount,
      'mainCategory': mainCategory,
      'subCategory': subCategory,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(
      '${_keyPrefix}shopping_$accountName',
      jsonEncode(data),
    );
  }

  /// 쇼핑 세션 정보 가져오기
  Future<LastShoppingSession?> getShoppingSession(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_keyPrefix}shopping_$accountName');
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return LastShoppingSession.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// 쇼핑 세션 업데이트 (지출입력 결과 반영)
  Future<void> updateShoppingSessionFromTransaction({
    required String accountName,
    required String? paymentMethod,
    required String? memo,
    required String? mainCategory,
    required String? subCategory,
    required double amount,
  }) async {
    final existing = await getShoppingSession(accountName);

    await saveShoppingSession(
      accountName: accountName,
      paymentMethod: paymentMethod ?? existing?.paymentMethod,
      storeName: memo ?? existing?.storeName,
      totalAmount: (existing?.totalAmount ?? 0) + amount,
      chargedAmount: (existing?.chargedAmount ?? 0) + amount,
      itemCount: (existing?.itemCount ?? 0) + 1,
      mainCategory: mainCategory ?? existing?.mainCategory,
      subCategory: subCategory ?? existing?.subCategory,
    );
  }

  /// 쇼핑 세션 초기화 (새 쇼핑 시작)
  Future<void> startNewShoppingSession(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_keyPrefix}shopping_$accountName');
  }

  /// 쇼핑 세션 종료
  Future<void> endShoppingSession(String accountName) async {
    // 세션 데이터는 유지 (포인트 입력에서 사용)
    // 필요 시 여기서 정리 작업 수행
  }

  // ========== 결제수단 관련 ==========

  /// 마지막 결제수단 저장
  Future<void> saveLastPaymentMethod(String accountName, String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_keyPrefix}payment_$accountName', method);
  }

  /// 마지막 결제수단 가져오기
  Future<String?> getLastPaymentMethod(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_keyPrefix}payment_$accountName');
  }

  // ========== 메모(매장명) 관련 ==========

  /// 마지막 메모 저장
  Future<void> saveLastMemo(String accountName, String memo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_keyPrefix}memo_$accountName', memo);
  }

  /// 마지막 메모 가져오기
  Future<String?> getLastMemo(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_keyPrefix}memo_$accountName');
  }

  // ========== 카테고리 관련 ==========

  /// 마지막 카테고리 저장
  Future<void> saveLastCategory(
    String accountName,
    String mainCategory,
    String? subCategory,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_keyPrefix}category_main_$accountName',
      mainCategory,
    );
    if (subCategory != null) {
      await prefs.setString(
        '${_keyPrefix}category_sub_$accountName',
        subCategory,
      );
    }
  }

  /// 마지막 카테고리 가져오기
  Future<({String? main, String? sub})> getLastCategory(
    String accountName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return (
      main: prefs.getString('${_keyPrefix}category_main_$accountName'),
      sub: prefs.getString('${_keyPrefix}category_sub_$accountName'),
    );
  }

  // ========== 전체 초기화 ==========

  /// 특정 계정의 모든 마지막 입력값 초기화
  Future<void> clearAll(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.contains('_$accountName'));
    for (final key in keys) {
      if (key.startsWith(_keyPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}

/// 마지막 지출입력 데이터
class LastTransactionInput {
  final String accountName;
  final String? description;
  final double? amount;
  final double? unitPrice;
  final int? quantity;
  final String? paymentMethod;
  final String? memo;
  final String? mainCategory;
  final String? subCategory;
  final DateTime? date;
  final DateTime savedAt;

  const LastTransactionInput({
    required this.accountName,
    this.description,
    this.amount,
    this.unitPrice,
    this.quantity,
    this.paymentMethod,
    this.memo,
    this.mainCategory,
    this.subCategory,
    this.date,
    required this.savedAt,
  });

  factory LastTransactionInput.fromJson(Map<String, dynamic> json) {
    return LastTransactionInput(
      accountName: json['accountName'] as String? ?? '',
      description: json['description'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      quantity: json['quantity'] as int?,
      paymentMethod: json['paymentMethod'] as String?,
      memo: json['memo'] as String?,
      mainCategory: json['mainCategory'] as String?,
      subCategory: json['subCategory'] as String?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String)
          : null,
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// 쇼핑 세션 데이터
class LastShoppingSession {
  final String accountName;
  final String? paymentMethod;
  final String? storeName;
  final double? totalAmount;
  final double? chargedAmount;
  final int? itemCount;
  final String? mainCategory;
  final String? subCategory;
  final DateTime savedAt;

  const LastShoppingSession({
    required this.accountName,
    this.paymentMethod,
    this.storeName,
    this.totalAmount,
    this.chargedAmount,
    this.itemCount,
    this.mainCategory,
    this.subCategory,
    required this.savedAt,
  });

  factory LastShoppingSession.fromJson(Map<String, dynamic> json) {
    return LastShoppingSession(
      accountName: json['accountName'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String?,
      storeName: json['storeName'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      chargedAmount: (json['chargedAmount'] as num?)?.toDouble(),
      itemCount: json['itemCount'] as int?,
      mainCategory: json['mainCategory'] as String?,
      subCategory: json['subCategory'] as String?,
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
