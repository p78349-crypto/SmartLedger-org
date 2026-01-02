class FixedCost {
  final String name;
  final double amount;
  final String? vendor;
  final String paymentMethod;
  final String? memo;
  final int? dueDay; // 1~31 중 납부일, 없으면 null

  FixedCost({
    required this.name,
    required this.amount,
    this.vendor,
    this.paymentMethod = '현금',
    this.memo,
    this.dueDay,
  });

  factory FixedCost.fromJson(Map<String, dynamic> json) {
    return FixedCost(
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
      'name': name,
      'amount': amount,
      'vendor': vendor,
      'paymentMethod': paymentMethod,
      'memo': memo,
      'dueDay': dueDay,
    };
  }
}

