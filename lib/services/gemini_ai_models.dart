// ignore_for_file: lines_longer_than_80_chars

// Gemini AI 서비스에서 사용하는 결과 모델 클래스들

/// 카테고리 분류 결과
class CategoryResult {
  final String mainCategory;
  final String? subCategory;
  final double confidence;

  CategoryResult({
    required this.mainCategory,
    this.subCategory,
    this.confidence = 0.5,
  });

  factory CategoryResult.unknown() =>
      CategoryResult(mainCategory: '기타', subCategory: '기타', confidence: 0.0);

  String get fullCategory =>
      subCategory != null ? '$mainCategory > $subCategory' : mainCategory;

  @override
  String toString() => 'CategoryResult($fullCategory, $confidence)';
}

/// 사용자 질문 분석 결과
class QueryIntent {
  final String intent;
  final String? category;
  final String? period;
  final DateTime? startDate;
  final DateTime? endDate;

  QueryIntent({
    required this.intent,
    this.category,
    this.period,
    this.startDate,
    this.endDate,
  });

  factory QueryIntent.unknown() => QueryIntent(intent: 'unknown');

  factory QueryIntent.fromJson(Map<String, dynamic> json) {
    return QueryIntent(
      intent: json['intent'] as String? ?? 'unknown',
      category: json['category'] as String?,
      period: json['period'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
    );
  }

  bool get isUnknown => intent == 'unknown';

  @override
  String toString() => 'QueryIntent($intent, $category, $period)';
}

/// 음성 명령 분석 결과
class VoiceCommand {
  final String action;
  final double? amount;
  final String? description;
  final String? category;
  final String? screen;
  final String? query;

  VoiceCommand({
    required this.action,
    this.amount,
    this.description,
    this.category,
    this.screen,
    this.query,
  });

  factory VoiceCommand.unknown() => VoiceCommand(action: 'unknown');

  factory VoiceCommand.fromJson(Map<String, dynamic> json) {
    final params = json['params'] as Map<String, dynamic>? ?? {};
    return VoiceCommand(
      action: json['action'] as String? ?? 'unknown',
      amount: (params['amount'] as num?)?.toDouble(),
      description: params['description'] as String?,
      category: params['category'] as String?,
      screen: params['screen'] as String?,
      query: params['query'] as String?,
    );
  }

  bool get isUnknown => action == 'unknown';

  @override
  String toString() =>
      'VoiceCommand($action, amount: $amount, desc: $description)';
}
