import 'package:flutter/foundation.dart';

@immutable
class NutritionItem {
  const NutritionItem({
    required this.name,
    required this.priceMinWon,
    required this.priceMaxWon,
  });

  final String name;
  final int priceMinWon;
  final int priceMaxWon;

  int get priceMidWon => ((priceMinWon + priceMaxWon) / 2).round();
}

@immutable
class NutritionReport {
  const NutritionReport({
    required this.items,
    required this.totalMinWon,
    required this.totalMaxWon,
    required this.hasCola2LHint,
  });

  final List<NutritionItem> items;
  final int totalMinWon;
  final int totalMaxWon;
  final bool hasCola2LHint;
}

class NutritionReportUtils {
  NutritionReportUtils._();

  static final RegExp _parenPrice = RegExp(
    r'([가-힣A-Za-z]{1,20})\s*\([^)]*?(\d{2,6})\s*(?:-|~)\s*(\d{2,6})\s*원[^)]*\)',
  );

  static final RegExp _inlinePrice = RegExp(
    r'([가-힣A-Za-z]{1,20})\s*(?:\d+\s*(?:마리|개|봉|팩|g|kg|ml|l|L|리터)\s*)*'
    r'(\d{2,6})(?:\s*(?:-|~)\s*(\d{2,6}))?\s*원',
  );

  static NutritionReport buildFromRawText(String raw) {
    final text = raw.replaceAll('\n', ' ').trim();
    final Map<String, NutritionItem> byName = <String, NutritionItem>{};

    void addItem(String name, int minWon, int maxWon) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) return;
      final normalized = _normalizeName(trimmed);

      final next = NutritionItem(
        name: trimmed,
        priceMinWon: minWon,
        priceMaxWon: maxWon,
      );

      final existing = byName[normalized];
      if (existing == null) {
        byName[normalized] = next;
        return;
      }

      // Merge duplicates by expanding range.
      byName[normalized] = NutritionItem(
        name: existing.name,
        priceMinWon: _min(existing.priceMinWon, next.priceMinWon),
        priceMaxWon: _max(existing.priceMaxWon, next.priceMaxWon),
      );
    }

    for (final m in _parenPrice.allMatches(text)) {
      final name = m.group(1) ?? '';
      final minWon = int.tryParse(m.group(2) ?? '') ?? 0;
      final maxWon = int.tryParse(m.group(3) ?? '') ?? 0;
      if (minWon > 0 && maxWon > 0) {
        addItem(name, minWon, maxWon);
      }
    }

    for (final m in _inlinePrice.allMatches(text)) {
      final name = m.group(1) ?? '';
      final minWon = int.tryParse(m.group(2) ?? '') ?? 0;
      final maxWon = int.tryParse(m.group(3) ?? '') ?? minWon;
      if (minWon > 0) {
        addItem(name, minWon, maxWon);
      }
    }

    final items = byName.values.toList(growable: false)
      ..sort((a, b) => b.priceMidWon.compareTo(a.priceMidWon));

    final totalMin = items.fold<int>(0, (sum, i) => sum + i.priceMinWon);
    final totalMax = items.fold<int>(0, (sum, i) => sum + i.priceMaxWon);

    final hasCola2LHint = _looksLikeCola2L(text);

    return NutritionReport(
      items: items,
      totalMinWon: totalMin,
      totalMaxWon: totalMax,
      hasCola2LHint: hasCola2LHint,
    );
  }

  static bool _looksLikeCola2L(String text) {
    final lower = text.toLowerCase();
    final hasCola =
        lower.contains('콜라') ||
        lower.contains('coke') ||
        lower.contains('cola');
    if (!hasCola) return false;
    return lower.contains('2l') ||
        lower.contains('2 l') ||
        lower.contains('2리터') ||
        lower.contains('2 리터');
  }

  static String _normalizeName(String raw) {
    return raw
        .replaceAll(' ', '')
        .replaceAll('표교버벗', '표고버섯')
        .replaceAll('버벗', '버섯');
  }

  static int _min(int a, int b) => a < b ? a : b;
  static int _max(int a, int b) => a > b ? a : b;

  /// 콜라 2L 당류를 설탕 큐브로 환산한 범위를 반환.
  ///
  /// - 브랜드/라벨에 따라 당류가 달라 정확치는 제품 라벨이 필요합니다.
  /// - 기본 가정: 2L 당류 200~220g, 설탕 큐브 3~4g.
  static ({int minCubes, int maxCubes, int sugarMinG, int sugarMaxG})
  estimateSugarCubesForCola2L() {
    const sugarMinG = 200;
    const sugarMaxG = 220;
    const cubeMaxG = 4;
    const cubeMinG = 3;

    final minCubes = (sugarMinG / cubeMaxG).round();
    final maxCubes = (sugarMaxG / cubeMinG).round();

    return (
      minCubes: minCubes,
      maxCubes: maxCubes,
      sugarMinG: sugarMinG,
      sugarMaxG: sugarMaxG,
    );
  }
}
