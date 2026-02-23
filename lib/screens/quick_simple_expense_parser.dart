import 'package:flutter/foundation.dart';

/// Parsed result from a single-line quick expense input.
typedef ParsedExpenseLine =
    ({
      String description,
      int quantity,
      double amount,
      String payment,
      String store,
    });

/// Parse a free-form Korean expense string into structured fields.
///
/// Returns `null` when the input cannot be understood (e.g. missing amount).
ParsedExpenseLine? parseExpenseLine(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;

  // Normalize common separators.
  text = text.replaceAll('.', ' ');
  text = text.replaceAll(RegExp(r'\s+'), ' ');

  // Optional parsing mode (no UI):
  // - "공격": infer more (e.g., bare quantity)
  // - "보수": infer less
  // Default is aggressive to avoid blocking saves.
  bool aggressive = true;
  final modeMatch = RegExp(r'(^|\s)(공격|보수)(\s|$)').firstMatch(text);
  if (modeMatch != null) {
    aggressive = (modeMatch.group(2) == '공격');
    text = text.replaceFirst(modeMatch.group(0)!, ' ').trim();
    text = text.replaceAll(RegExp(r'\s+'), ' ');
  }

  // Amount: prefer explicit "원" but allow bare numbers.
  Match? amountMatch = RegExp(r'(\d[\d,]*)\s*원').firstMatch(text);
  String? rawAmount;

  if (amountMatch != null) {
    rawAmount = (amountMatch.group(1) ?? '').replaceAll(',', '');
    text = text.replaceFirst(amountMatch.group(0)!, ' ').trim();
  } else {
    final allNums = RegExp(r'\d[\d,]*').allMatches(text).toList();
    if (allNums.isEmpty) return null;
    amountMatch = allNums.last;
    rawAmount = text
        .substring(amountMatch.start, amountMatch.end)
        .replaceAll(',', '');
    text =
        (text.substring(0, amountMatch.start) +
                text.substring(amountMatch.end))
            .trim();
  }

  final amount = double.tryParse(rawAmount);
  if (amount == null || amount <= 0) return null;

  // Normalize spaces after removing amount.
  text = text.replaceAll(RegExp(r'\s+'), ' ');

  final tokens = text.split(' ').where((t) => t.trim().isNotEmpty).toList();

  // Payment token.
  String payment = '';
  int paymentIndex = -1;
  for (var i = tokens.length - 1; i >= 0; i--) {
    final t = tokens[i];
    if (t.contains('카드') ||
        t.contains('현금') ||
        t.contains('계좌') ||
        t.contains('이체') ||
        t.contains('페이')) {
      payment = t;
      paymentIndex = i;
      break;
    }
  }
  if (paymentIndex >= 0) {
    tokens.removeAt(paymentIndex);
  }

  payment = payment.trim();
  if (payment.isEmpty) payment = '미지정';

  // Quantity token: prefer explicit unit words to avoid mis-detecting.
  int quantity = 1;
  int qtyIndex = -1;
  final qtyMatchRe = RegExp(r'^(\d+)(개|잔|병|회|장|팩|봉|캔)$');
  for (var i = 0; i < tokens.length; i++) {
    final m = qtyMatchRe.firstMatch(tokens[i]);
    if (m != null) {
      quantity = int.tryParse(m.group(1) ?? '1') ?? 1;
      qtyIndex = i;
      break;
    }
  }
  if (qtyIndex >= 0) {
    tokens.removeAt(qtyIndex);
  }

  // Quantity inference (aggressive only):
  // - "x2" / "2x" / "×2" patterns
  // - bare trailing integer (e.g., "커피 2")
  if (aggressive && tokens.isNotEmpty && qtyIndex < 0) {
    int inferredQty = 1;
    int inferredIndex = -1;
    final xQtyRe1 = RegExp(r'^(?:x|X|\*|×)(\d+)$');
    final xQtyRe2 = RegExp(r'^(\d+)(?:x|X|\*|×)$');
    for (var i = tokens.length - 1; i >= 0; i--) {
      final t = tokens[i];
      final m1 = xQtyRe1.firstMatch(t);
      final m2 = xQtyRe2.firstMatch(t);
      if (m1 != null) {
        inferredQty = int.tryParse(m1.group(1) ?? '1') ?? 1;
        inferredIndex = i;
        break;
      }
      if (m2 != null) {
        inferredQty = int.tryParse(m2.group(1) ?? '1') ?? 1;
        inferredIndex = i;
        break;
      }
    }

    if (inferredIndex < 0 && tokens.length >= 2) {
      final last = tokens.last;
      if (RegExp(r'^\d+$').hasMatch(last)) {
        final v = int.tryParse(last) ?? 1;
        if (v >= 2 && v <= 99) {
          inferredQty = v;
          inferredIndex = tokens.length - 1;
        }
      }
    }

    if (inferredIndex >= 0) {
      quantity = inferredQty;
      tokens.removeAt(inferredIndex);
    }
  }

  // Store tag (aggressive only): "매장:OO" / "가게:OO" / "상호:OO"
  String taggedStore = '';
  if (aggressive && tokens.isNotEmpty) {
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (t.startsWith('매장:') ||
          t.startsWith('가게:') ||
          t.startsWith('상호:')) {
        taggedStore = t.split(':').skip(1).join(':').trim();
        tokens.removeAt(i);
        break;
      }
    }
  }

  // Store/description: be permissive.
  String store = taggedStore.isNotEmpty ? taggedStore : '미지정';
  String description = '';
  if (tokens.isEmpty) {
    description = '';
  } else if (tokens.length == 1) {
    description = tokens.first.trim();
  } else {
    if (taggedStore.isEmpty) {
      store = tokens.removeLast().trim();
    }
    description = tokens.join(' ').trim();
  }

  if (description.isEmpty) {
    description = '간편지출';
  }
  if (store.isEmpty) {
    store = '미지정';
  }

  debugPrint('[Parser] parsed: $description, qty=$quantity, '
      'amount=$amount, payment=$payment, store=$store');

  return (
    description: description,
    quantity: quantity <= 0 ? 1 : quantity,
    amount: amount,
    payment: payment.trim(),
    store: store,
  );
}
