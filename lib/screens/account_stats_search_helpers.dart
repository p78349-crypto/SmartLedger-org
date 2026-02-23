import '../models/transaction.dart';

import 'account_stats_search_models.dart';
export 'account_stats_search_models.dart';

/// 검색 쿼리를 파싱하여 FTS 쿼리와 필터를 분리.
TxSearchPlan parseTxSearchPlan(String raw) {
  final input = raw.trim();
  final filters = TxSearchFilters();
  if (input.isEmpty) {
    return TxSearchPlan(ftsQuery: '', filters: filters);
  }

  DateTime? parseYmd(String s) {
    final t = s.trim();
    final m = RegExp(r'^(\d{4})-(\d{1,2})(?:-(\d{1,2}))?$').firstMatch(t);
    if (m == null) return null;
    final y = int.tryParse(m.group(1) ?? '');
    final mo = int.tryParse(m.group(2) ?? '');
    final dRaw = m.group(3);
    final d = dRaw == null ? 1 : int.tryParse(dRaw);
    if (y == null || mo == null) return null;
    return DateTime(y, mo, d ?? 1);
  }

  DateTime endOfMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0);

  double? parseAnnualRatePercent(String s) {
    final cleaned = s.trim().replaceAll('%', '');
    final v = double.tryParse(cleaned);
    if (v == null || v < 0 || v > 100) return null;
    return v;
  }

  void applyAmount(String op, double value) {
    final v = value.abs();
    switch (op) {
      case '>=':
      case '>':
        filters.minAmountAbs = (filters.minAmountAbs == null)
            ? v
            : (filters.minAmountAbs! > v ? filters.minAmountAbs : v);
        break;
      case '<=':
      case '<':
        filters.maxAmountAbs = (filters.maxAmountAbs == null)
            ? v
            : (filters.maxAmountAbs! < v ? filters.maxAmountAbs : v);
        break;
      case '=':
        filters.minAmountAbs = v;
        filters.maxAmountAbs = v;
        break;
    }
  }

  void applyBenefitAmount(String op, double value) {
    final v = value.abs();
    switch (op) {
      case '>=':
      case '>':
        filters.minBenefit = (filters.minBenefit == null)
            ? v
            : (filters.minBenefit! > v ? filters.minBenefit : v);
        break;
      case '<=':
      case '<':
        filters.maxBenefit = (filters.maxBenefit == null)
            ? v
            : (filters.maxBenefit! < v ? filters.maxBenefit : v);
        break;
      case '=':
        filters.minBenefit = v;
        filters.maxBenefit = v;
        break;
    }
  }

  final freeTokens = <String>[];
  final tokens = input
      .split(RegExp(r'\s+'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList(growable: false);

  for (final token in tokens) {
    if (token == '지출') {
      filters.types.add(TransactionType.expense);
      continue;
    }
    if (token == '수입') {
      filters.types.add(TransactionType.income);
      continue;
    }
    if (token == '예금' || token == '저축') {
      filters.types.add(TransactionType.savings);
      continue;
    }
    if (token == '반품' || token == '환불') {
      filters.types.add(TransactionType.refund);
      continue;
    }
    if (token == '혜택' || token == '혜택만') {
      filters.benefitOnly = true;
      continue;
    }
    if (token == '포인트' || token == '적립') {
      filters.pointsOnly = true;
      continue;
    }
    if (token == '보수') {
      filters.annualRatePercent = 0;
      continue;
    }
    if (token == '공격') {
      filters.annualRatePercent = 5;
      continue;
    }

    final kv = token.split(':');
    if (kv.length == 2) {
      final key = kv[0].trim();
      final value = kv[1].trim();
      if (value.isEmpty) continue;
      switch (key) {
        case '이자':
        case '금리':
        case 'rate':
        case 'r':
          final rate = parseAnnualRatePercent(value);
          if (rate != null) {
            filters.annualRatePercent = rate;
            continue;
          }
          break;
        case '카드':
        case '결제':
          filters.paymentContains.add(value);
          continue;
        case '공급처':
        case '출처':
        case '마트':
        case '쇼핑몰':
          filters.storeContains.add(value);
          continue;
        case '카테고리':
        case '분류':
          filters.categoryContains.add(value);
          continue;
        case '항목':
        case '내용':
          filters.descriptionContains.add(value);
          continue;
        case '메모':
          filters.memoContains.add(value);
          continue;
        case '기간':
        case '날짜':
          final parts = value.split('..');
          if (parts.length == 2) {
            final start = parseYmd(parts[0]);
            final endRaw = parseYmd(parts[1]);
            if (start != null && endRaw != null) {
              final end = (parts[1].trim().length == 7)
                  ? endOfMonth(endRaw)
                  : endRaw;
              filters.startDate = start;
              filters.endDate = end;
              continue;
            }
          }
          break;
        case '혜택':
          final m = RegExp(r'^(>=|<=|>|<|=)(\d[\d,]*)$').firstMatch(value);
          if (m != null) {
            final op = m.group(1) ?? '';
            final numText = (m.group(2) ?? '').replaceAll(',', '');
            final amount = double.tryParse(numText);
            if (amount != null) {
              filters.benefitOnly = true;
              applyBenefitAmount(op, amount);
              continue;
            }
          }
          break;
      }
    }

    final amountMatch = RegExp(
      r'^(>=|<=|>|<|=)(\d[\d,]*)(?:원)?$',
      unicode: true,
    ).firstMatch(token);
    if (amountMatch != null) {
      final op = amountMatch.group(1) ?? '';
      final numText = (amountMatch.group(2) ?? '').replaceAll(',', '');
      final amount = double.tryParse(numText);
      if (amount != null) {
        applyAmount(op, amount);
        continue;
      }
    }

    freeTokens.add(token);
  }

  return TxSearchPlan(ftsQuery: freeTokens.join(' '), filters: filters);
}
