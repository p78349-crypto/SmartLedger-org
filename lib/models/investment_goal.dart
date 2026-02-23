enum InvestmentGoalType {
  emergencyFund('비상금'),
  shortTerm('단기 투자'),
  homePurchase('주택/부동산'),
  education('교육비'),
  retirement('은퇴 자금'),
  business('사업/회사'),
  other('기타');

  final String label;
  const InvestmentGoalType(this.label);
}

enum InvestmentGoalHorizon {
  shortTerm('1년 이내'),
  midTerm('3~5년'),
  longTerm('10년 이상');

  final String label;
  const InvestmentGoalHorizon(this.label);
}

class InvestmentGoal {
  final String id;
  final String title;
  final InvestmentGoalType type;
  final InvestmentGoalHorizon horizon;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final int priority;
  final String? riskLevel; // AssetRiskLevel label

  InvestmentGoal({
    required this.id,
    required this.title,
    required this.type,
    required this.horizon,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    this.priority = 3,
    this.riskLevel,
  });

  double get progressPct =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount) * 100;

  InvestmentGoal copyWith({
    String? title,
    InvestmentGoalType? type,
    InvestmentGoalHorizon? horizon,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    int? priority,
    String? riskLevel,
  }) {
    return InvestmentGoal(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      horizon: horizon ?? this.horizon,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      priority: priority ?? this.priority,
      riskLevel: riskLevel ?? this.riskLevel,
    );
  }

  factory InvestmentGoal.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'other';
    final horizonStr = json['horizon'] as String? ?? 'shortTerm';
    final type = InvestmentGoalType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => InvestmentGoalType.other,
    );
    final horizon = InvestmentGoalHorizon.values.firstWhere(
      (e) => e.name == horizonStr,
      orElse: () => InvestmentGoalHorizon.shortTerm,
    );
    return InvestmentGoal(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      type: type,
      horizon: horizon,
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'] as String)
          : null,
      priority: (json['priority'] as num?)?.toInt() ?? 3,
      riskLevel: json['riskLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'horizon': horizon.name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate?.toIso8601String(),
      'priority': priority,
      'riskLevel': riskLevel,
    };
  }
}
