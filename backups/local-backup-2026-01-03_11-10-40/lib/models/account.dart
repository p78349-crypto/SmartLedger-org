class Account {
  final String name;
  final DateTime createdAt;
  final double carryoverAmount; // 이월된 남은 돈
  final double overdraftAmount; // 예산 초과분 (미래에서 끌어온 돈)
  final DateTime? lastCarryoverDate; // 마지막 이월 날짜
  // TODO: 거래, 통계, 자산, 고정비용, 백업 등 데이터 필드 추가

  Account({
    required this.name,
    DateTime? createdAt,
    this.carryoverAmount = 0,
    this.overdraftAmount = 0,
    this.lastCarryoverDate,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      name: json['name'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      carryoverAmount: (json['carryoverAmount'] as num?)?.toDouble() ?? 0,
      overdraftAmount: (json['overdraftAmount'] as num?)?.toDouble() ?? 0,
      lastCarryoverDate: json['lastCarryoverDate'] != null
          ? DateTime.tryParse(json['lastCarryoverDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'carryoverAmount': carryoverAmount,
      'overdraftAmount': overdraftAmount,
      'lastCarryoverDate': lastCarryoverDate?.toIso8601String(),
    };
  }
}
