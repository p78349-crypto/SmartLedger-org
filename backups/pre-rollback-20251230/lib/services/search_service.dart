import 'package:smart_ledger/database/app_database.dart';
import 'package:smart_ledger/models/search_filter.dart';
import 'package:smart_ledger/utils/date_formatter.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  /// 거래 검색 (자산 제외)
  List<DbTransaction> searchTransactions(
    List<DbTransaction> transactions,
    SearchFilter filter,
  ) {
    if (filter.isEmpty) return transactions;

    final query = filter.query.toLowerCase().trim();

    return transactions.where((tx) {
      switch (filter.category) {
        case SearchCategory.productName:
          // 기본 검색(제품명)은 사용자가 보통 "내용"처럼 쓰기 때문에
          // 메모까지 함께 매칭해 검색 누락을 줄인다.
          return _matchText(tx.description, query) ||
              _matchText(tx.memo, query);

        case SearchCategory.paymentMethod:
          return _matchText(tx.paymentMethod, query);

        case SearchCategory.memo:
          return _matchText(tx.memo, query);

        case SearchCategory.amount:
          return _matchAmount(tx.amount, query);

        case SearchCategory.date:
          return _matchDate(tx.date, query);
      }
    }).toList();
  }

  /// 검색 결과 통계 계산
  SearchStats calculateStats(
    List<DbTransaction> allTransactions,
    List<DbTransaction> filteredTransactions,
  ) {
    final totalAmount = filteredTransactions.fold<double>(
      0.0,
      (sum, tx) => sum + tx.amount,
    );
    final allAmount = allTransactions.fold<double>(
      0.0,
      (sum, tx) => sum + tx.amount,
    );
    final percentage = allAmount > 0 ? (totalAmount / allAmount) * 100 : 0.0;

    return SearchStats(
      matchCount: filteredTransactions.length,
      totalAmount: totalAmount,
      allAmount: allAmount,
      percentage: percentage,
    );
  }

  /// 텍스트 매칭
  bool _matchText(String text, String query) {
    return text.toLowerCase().contains(query);
  }

  /// 금액 매칭
  bool _matchAmount(double amount, String query) {
    // 정확한 금액
    if (RegExp(r'^\d+$').hasMatch(query)) {
      final value = double.tryParse(query);
      if (value != null) {
        return amount == value;
      }
    }

    // 이상 (>=10000)
    if (query.startsWith('>=')) {
      final value = double.tryParse(query.substring(2).trim());
      if (value != null) {
        return amount >= value;
      }
    }

    // 이하 (<=10000)
    if (query.startsWith('<=')) {
      final value = double.tryParse(query.substring(2).trim());
      if (value != null) {
        return amount <= value;
      }
    }

    // 범위 (10000-50000)
    if (query.contains('-')) {
      final parts = query.split('-');
      if (parts.length == 2) {
        final min = double.tryParse(parts[0].trim());
        final max = double.tryParse(parts[1].trim());
        if (min != null && max != null) {
          return amount >= min && amount <= max;
        }
      }
    }

    // 부분 일치
    return amount.toString().contains(query);
  }

  /// 날짜 매칭
  bool _matchDate(DateTime date, String query) {
    // yyyy-MM-dd 형식
    final dateStr = DateFormatter.defaultDate.format(date);
    if (dateStr.contains(query)) return true;

    // yyyy-MM 형식
    final monthStr = DateFormatter.yearMonth.format(date);
    if (monthStr.contains(query)) return true;

    // M월 형식
    final monthOnly = DateFormatter.shortMonth.format(date);
    if (monthOnly.contains(query)) return true;

    // yyyy년 형식
    final yearStr = DateFormatter.yearKorean.format(date);
    if (yearStr.contains(query)) return true;

    return false;
  }

  /// 검색 힌트 제공
  String getSearchHint(SearchCategory category) {
    switch (category) {
      case SearchCategory.productName:
        return '예: 커피, 마트, 편의점';
      case SearchCategory.paymentMethod:
        return '예: 카드, 현금, 국민';
      case SearchCategory.memo:
        return '예: 선물, 회의, 점심';
      case SearchCategory.amount:
        return '예: 50000, >=10000, 1000-5000';
      case SearchCategory.date:
        return '예: 2025-12, 12월, 2025년';
    }
  }
}

