import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import '../services/transaction_service.dart';

/// 지출 입력 내역을 날짜별로 정리하여 저장/로드하는 유틸리티
///
/// 상품명, 가격, 수량, 단가, 결재수단, 메모, 카테고리 등을 포함
class TransactionByDateUtils {
  TransactionByDateUtils._();

  static const String _storageKeyPrefix = 'tx_by_date_v1';

  static String _key(String accountName) => '${_storageKeyPrefix}_$accountName';

  /// 데이터베이스(TransactionService)에서 데이터를 읽어와 날짜별로 정렬 및 저장
  static Future<void> syncFromDatabase(String accountName) async {
    // 1. DB(Service)에서 데이터 가져오기
    final allTxs = TransactionService().getTransactions(accountName);

    // 2. 날짜별 그룹화 (yyyy-MM-dd)
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    // 최신 날짜가 위로 오도록 정렬하기 위해, 일단 리스트로 모으거나 Map에 넣고 나중에 정렬
    // 여기서는 Map 구성 후 저장 시점에 정렬 여부는 사용하는 쪽이나 JSON 구조상 순서 보장이 안될 수 있음을 감안.
    // 하지만 Dart Map은 삽입 순서를 유지하므로 날짜 순서대로 넣으면 됨. (또는 정렬해서 넣음)

    // 날짜별 정렬 (최신순)
    final sortedTxs = List<Transaction>.from(allTxs)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final tx in sortedTxs) {
      final dateKey = tx.date.toIso8601String().split('T').first;

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }

      // 요구사항: 상품명, 가격, 수량, 단가, 결재수단, 메모, 카테고리
      grouped[dateKey]!.add({
        'id': tx.id, // 식별용
        'name': tx.description, // 상품명
        'amount': tx.amount, // 가격 (총액)
        'quantity': tx.quantity, // 수량
        'unitPrice': tx.unitPrice, // 단가
        'paymentMethod': tx.paymentMethod, // 결재수단
        'memo': tx.memo, // 메모
        'category': tx.mainCategory, // 카테고리
        'date': tx.date.toIso8601String(), // 전체 시간
        'type': tx.type.name, // 거래 유형 (지출/수입 등)
      });
    }

    // 3. 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(accountName), jsonEncode(grouped));
  }

  /// 저장된 날짜별 데이터 로드
  static Future<Map<String, List<Map<String, dynamic>>>> load(
    String accountName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(accountName));
    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      // JSON 디코딩 결과는 Map<String, dynamic>이지만 값 부분이 List<dynamic>일 수 있으므로 캐스팅
      final result = <String, List<Map<String, dynamic>>>{};

      decoded.forEach((key, value) {
        if (value is List) {
          result[key] = value.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      });

      return result;
    } catch (e) {
      return {};
    }
  }

  /// 특정 날짜의 데이터만 가져오기
  static Future<List<Map<String, dynamic>>> getParamsByDate(
    String accountName,
    String dateKey,
  ) async {
    final all = await load(accountName);
    return all[dateKey] ?? [];
  }
}
