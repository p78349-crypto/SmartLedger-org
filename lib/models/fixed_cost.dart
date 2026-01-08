import 'dart:convert';

class FixedCost {
  final String id;
  final String name;
  final double amount;
  final String? vendor;
  final String paymentMethod;
  final String? memo;
  final int? dueDay; // 1~31 중 납부일, 없으면 null

  FixedCost({
    required this.id,
    required this.name,
    required this.amount,
    this.vendor,
    this.paymentMethod = '현금',
    this.memo,
    this.dueDay,
  });

  static String _legacyIdFromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String? ?? '').trim();
    final amount = (json['amount'] as num?)?.toDouble() ?? 0;
    final vendor = (json['vendor'] as String? ?? '').trim();
    final paymentMethod = (json['paymentMethod'] as String? ?? '현금').trim();
    final dueDay = (json['dueDay'] as num?)?.toInt();

    final canonical = StringBuffer()
      ..write('name=')
      ..write(name)
      ..write('|amount=')
      ..write(amount.toStringAsFixed(2))
      ..write('|vendor=')
      ..write(vendor)
      ..write('|payment=')
      ..write(paymentMethod)
      ..write('|dueDay=')
      ..write(dueDay?.toString() ?? 'null');

    // Stable FNV-1a 32-bit hash over UTF-8 bytes.
    var hash = 0x811c9dc5;
    for (final b in utf8.encode(canonical.toString())) {
      hash ^= b;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 'legacy_${hash.toRadixString(16).padLeft(8, '0')}';
  }

  factory FixedCost.fromJson(Map<String, dynamic> json) {
    return FixedCost(
      id: (json['id'] as String?) ?? _legacyIdFromJson(json),
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      vendor: json['vendor'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? '현금',
      memo: json['memo'] as String?,
      dueDay: (json['dueDay'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'vendor': vendor,
      'paymentMethod': paymentMethod,
      'memo': memo,
      'dueDay': dueDay,
    };
  }
}
