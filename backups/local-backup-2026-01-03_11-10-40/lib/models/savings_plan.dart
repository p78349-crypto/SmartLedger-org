import 'dart:math';

class SavingsPlan {
  final String id;
  final String bankName; // 은행명
  final String name;
  final double monthlyAmount;
  final DateTime startDate;
  final int termMonths;
  final double interestRate; // Stored as decimal e.g. 0.035 means 3.5%
  final List<int> paidMonths;
  final DateTime createdAt;
  final bool autoDeposit; // 자동이체 여부

  const SavingsPlan({
    required this.id,
    this.bankName = '', // 기본값 빈 문자열
    required this.name,
    required this.monthlyAmount,
    required this.startDate,
    required this.termMonths,
    required this.interestRate,
    required this.paidMonths,
    required this.createdAt,
    this.autoDeposit = true, // 기본값 true
  });

  SavingsPlan copyWith({
    String? id,
    String? bankName,
    String? name,
    double? monthlyAmount,
    DateTime? startDate,
    int? termMonths,
    double? interestRate,
    List<int>? paidMonths,
    DateTime? createdAt,
    bool? autoDeposit,
  }) {
    return SavingsPlan(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      name: name ?? this.name,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      startDate: startDate ?? this.startDate,
      termMonths: termMonths ?? this.termMonths,
      interestRate: interestRate ?? this.interestRate,
      paidMonths: paidMonths ?? List<int>.from(this.paidMonths),
      createdAt: createdAt ?? this.createdAt,
      autoDeposit: autoDeposit ?? this.autoDeposit,
    );
  }

  factory SavingsPlan.fromJson(Map<String, dynamic> json) {
    return SavingsPlan(
      id: json['id'] as String,
      bankName: json['bankName'] as String? ?? '',
      name: json['name'] as String? ?? '예금',
      monthlyAmount: (json['monthlyAmount'] as num?)?.toDouble() ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      termMonths: (json['termMonths'] as num?)?.toInt() ?? 12,
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0,
      paidMonths: ((json['paidMonths'] as List?) ?? const <dynamic>[])
          .map((e) => (e as num).toInt())
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      autoDeposit: json['autoDeposit'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankName': bankName,
      'name': name,
      'monthlyAmount': monthlyAmount,
      'startDate': startDate.toIso8601String(),
      'termMonths': termMonths,
      'interestRate': interestRate,
      'paidMonths': paidMonths,
      'createdAt': createdAt.toIso8601String(),
      'autoDeposit': autoDeposit,
    };
  }

  int get paidCount => paidMonths.length;

  int get remainingCount => max(termMonths - paidCount, 0);

  double get depositedAmount => paidCount * monthlyAmount;

  double get targetPrincipal => termMonths * monthlyAmount;

  double get expectedInterest =>
      targetPrincipal * interestRate * (termMonths / 12); // 단리 기준

  double get expectedMaturityAmount => targetPrincipal + expectedInterest;

  DateTime get maturityDate => dueDateFor(termMonths - 1);

  DateTime dueDateFor(int monthIndex) {
    final base = DateTime(startDate.year, startDate.month + monthIndex, 1);
    final day = startDate.day;
    final lastDayOfMonth = DateTime(base.year, base.month + 1, 0).day;
    final safeDay = day < 1
        ? 1
        : day > lastDayOfMonth
        ? lastDayOfMonth
        : day;
    return DateTime(base.year, base.month, safeDay);
  }

  int dueCount(DateTime asOf) {
    int count = 0;
    for (var i = 0; i < termMonths; i++) {
      final dueDate = dueDateFor(i);
      if (!dueDate.isAfter(asOf)) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  double projectedBalance(DateTime asOf) {
    final completed = paidCount;
    final remaining = termMonths - completed;
    if (remaining <= 0) {
      return expectedMaturityAmount;
    }
    final progressPrincipal = completed * monthlyAmount;
    final progressInterest =
        expectedInterest * (completed / termMonths.toDouble());
    return progressPrincipal + progressInterest;
  }
}
