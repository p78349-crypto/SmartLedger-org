class Account {
  final String name;
  final DateTime createdAt;
  final double carryoverAmount; // 이월된 남은 돈
  final double overdraftAmount; // 예산 초과분 (미래에서 끌어온 돈)
  final DateTime? lastCarryoverDate; // 마지막 이월 날짜
  final String? password; // 계정 비밀번호 (선택적)
  // NOTE: 거래/통계/자산/고정비용/백업 데이터는 별도 서비스에서 관리
  // ( TransactionService, AssetService, FixedCostService, BackupService 참조 )

  Account({
    required this.name,
    DateTime? createdAt,
    this.carryoverAmount = 0,
    this.overdraftAmount = 0,
    this.lastCarryoverDate,
    this.password,
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
      password: json['password'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'carryoverAmount': carryoverAmount,
      'overdraftAmount': overdraftAmount,
      'lastCarryoverDate': lastCarryoverDate?.toIso8601String(),
      if (password != null) 'password': password,
    };
  }
}
