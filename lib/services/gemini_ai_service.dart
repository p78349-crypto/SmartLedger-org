// ignore_for_file: lines_longer_than_80_chars
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

/// SmartLedger 똑똑한 비서 - Gemini AI 서비스
///
/// 주요 기능:
/// 1. 카테고리 자동 분류 (키워드 없을 때)
/// 2. 자연어 질문 → 데이터 조회
/// 3. 음성 명령 의도 파악
/// 4. 지출 분석 & 조언
class GeminiAiService {
  static GeminiAiService? _instance;
  GenerativeModel? _model;
  bool _isInitialized = false;

  GeminiAiService._();

  static GeminiAiService get instance {
    _instance ??= GeminiAiService._();
    return _instance!;
  }

  /// API 키로 초기화
  Future<void> initialize(String apiKey) async {
    if (_isInitialized) return;

    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3, // 낮은 온도 = 일관된 응답
          maxOutputTokens: 1024,
        ),
      );
      _isInitialized = true;
      debugPrint('✅ Gemini AI 서비스 초기화 완료');
    } catch (e) {
      debugPrint('❌ Gemini AI 초기화 실패: $e');
      rethrow;
    }
  }

  bool get isReady => _isInitialized && _model != null;

  // ═══════════════════════════════════════════════════════════════
  // 1️⃣ 카테고리 자동 분류
  // ═══════════════════════════════════════════════════════════════

  /// 거래 내역에서 카테고리 추론
  Future<CategoryResult> classifyCategory(
    String description, {
    double? amount,
  }) async {
    if (!isReady) return CategoryResult.unknown();

    final prompt =
        '''
당신은 가계부 카테고리 분류 전문가입니다.

거래 내역: "$description"
${amount != null ? '금액: ${amount.toInt()}원' : ''}

다음 카테고리 중 가장 적합한 것을 선택하세요:
- 식비 > 식자재 구매 / 외식 / 배달 / 카페 / 간식
- 교통 > 대중교통 / 택시 / 주유 / 주차
- 생활 > 마트 / 편의점 / 생활용품 / 의류
- 주거 > 월세 / 관리비 / 공과금 / 통신비
- 의료 > 병원 / 약국 / 건강
- 문화 > 영화 / 도서 / 구독 / 취미
- 교육 > 학원 / 교재 / 강의
- 경조사 > 축의금 / 조의금 / 선물
- 기타 > 기타

JSON 형식으로만 응답하세요:
{"main": "메인카테고리", "sub": "서브카테고리", "confidence": 0.0~1.0}
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      // JSON 파싱
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(text);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        return CategoryResult(
          mainCategory: json['main'] as String? ?? '기타',
          subCategory: json['sub'] as String?,
          confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
        );
      }
    } catch (e) {
      debugPrint('카테고리 분류 오류: $e');
    }

    return CategoryResult.unknown();
  }

  // ═══════════════════════════════════════════════════════════════
  // 2️⃣ 자연어 질문 → 데이터 조회
  // ═══════════════════════════════════════════════════════════════

  /// 사용자 질문을 분석하여 쿼리 의도 파악
  Future<QueryIntent> parseUserQuestion(String question) async {
    if (!isReady) return QueryIntent.unknown();

    final prompt =
        '''
당신은 가계부 앱의 똑똑한 비서입니다.
사용자 질문을 분석하여 의도를 파악하세요.

질문: "$question"

가능한 의도 유형:
- expense_sum: 지출 합계 조회 ("이번 달 얼마 썼어?")
- expense_category: 카테고리별 지출 ("외식비 얼마야?")
- expense_list: 지출 내역 목록 ("커피 구매 내역")
- expense_compare: 기간 비교 ("지난달보다 얼마나 더 썼어?")
- budget_check: 예산 확인 ("예산 남았어?")
- savings_check: 저축 현황 ("이번 달 저축 얼마야?")
- advice: 조언 요청 ("절약 방법 알려줘")
- unknown: 알 수 없음

JSON 형식으로만 응답:
{
  "intent": "의도유형",
  "category": "카테고리명 또는 null",
  "period": "today/this_week/this_month/last_month/custom 또는 null",
  "startDate": "YYYY-MM-DD 또는 null",
  "endDate": "YYYY-MM-DD 또는 null"
}
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(text);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        return QueryIntent.fromJson(json);
      }
    } catch (e) {
      debugPrint('질문 분석 오류: $e');
    }

    return QueryIntent.unknown();
  }

  // ═══════════════════════════════════════════════════════════════
  // 3️⃣ 음성 명령 의도 파악
  // ═══════════════════════════════════════════════════════════════

  /// 음성 명령에서 액션 파악
  Future<VoiceCommand> parseVoiceCommand(String command) async {
    if (!isReady) return VoiceCommand.unknown();

    final prompt =
        '''
당신은 가계부 앱의 음성 비서입니다.
음성 명령을 분석하여 실행할 액션을 파악하세요.

명령: "$command"

가능한 액션:
- add_expense: 지출 추가 ("3만원 점심값 추가해줘")
- add_income: 수입 추가 ("월급 들어왔어")
- show_summary: 요약 보기 ("이번 달 요약 보여줘")
- show_category: 카테고리별 보기 ("식비 내역 보여줘")
- show_chart: 차트 보기 ("그래프로 보여줘")
- search: 검색 ("스타벅스 찾아줘")
- navigate: 화면 이동 ("설정 가줘", "홈으로")
- unknown: 알 수 없음

JSON 형식으로만 응답:
{
  "action": "액션유형",
  "params": {
    "amount": 금액 또는 null,
    "description": "내용" 또는 null,
    "category": "카테고리" 또는 null,
    "screen": "화면명" 또는 null,
    "query": "검색어" 또는 null
  }
}
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        return VoiceCommand.fromJson(json);
      }
    } catch (e) {
      debugPrint('음성 명령 분석 오류: $e');
    }

    return VoiceCommand.unknown();
  }

  // ═══════════════════════════════════════════════════════════════
  // 4️⃣ 지출 분석 & 조언
  // ═══════════════════════════════════════════════════════════════

  /// 지출 데이터 분석하여 조언 생성
  Future<String> generateAdvice({
    required double totalExpense,
    required double budget,
    required Map<String, double> categoryExpenses,
    double? lastMonthTotal,
  }) async {
    if (!isReady) return '분석 서비스를 사용할 수 없습니다.';

    final categoryList = categoryExpenses.entries
        .map((e) => '${e.key}: ${e.value.toInt()}원')
        .join('\n');

    final prompt =
        '''
당신은 친근한 가계부 재정 상담사입니다.

이번 달 지출 현황:
- 총 지출: ${totalExpense.toInt()}원
- 예산: ${budget.toInt()}원
- 예산 사용률: ${(totalExpense / budget * 100).toInt()}%
${lastMonthTotal != null ? '- 지난달 총 지출: ${lastMonthTotal.toInt()}원' : ''}

카테고리별 지출:
$categoryList

위 데이터를 바탕으로:
1. 현재 지출 상태 평가 (한 문장)
2. 가장 주의해야 할 카테고리
3. 구체적인 절약 팁 1개

친근하고 짧게 (3-4문장) 한국어로 조언해주세요.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? '조언을 생성할 수 없습니다.';
    } catch (e) {
      debugPrint('조언 생성 오류: $e');
      return '조언을 생성하는 중 오류가 발생했습니다.';
    }
  }

  /// 자연어 응답 생성 (데이터 기반)
  Future<String> generateNaturalResponse({
    required String question,
    required String dataContext,
  }) async {
    if (!isReady) return '서비스를 사용할 수 없습니다.';

    final prompt =
        '''
당신은 가계부 앱의 친근한 비서입니다.

사용자 질문: "$question"

조회된 데이터:
$dataContext

위 데이터를 바탕으로 자연스럽고 친근하게 한국어로 답변하세요.
숫자는 읽기 쉽게 표현하고, 이모지를 적절히 사용하세요.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? '응답을 생성할 수 없습니다.';
    } catch (e) {
      debugPrint('응답 생성 오류: $e');
      return '응답을 생성하는 중 오류가 발생했습니다.';
    }
  }

  /// OCR 텍스트 교정
  Future<String> correctOcrText(String ocrText) async {
    if (!isReady) return ocrText;

    final prompt =
        '''
다음 OCR 인식 텍스트의 오타를 교정해주세요.
한국어 영수증/가계부 관련 텍스트입니다.

원본: "$ocrText"

오타만 교정하고, 원래 의미는 유지하세요.
교정된 텍스트만 출력하세요.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? ocrText;
    } catch (e) {
      debugPrint('OCR 교정 오류: $e');
      return ocrText;
    }
  }

  /// 단순 텍스트 생성 (외부 서비스에서 재사용)
  Future<String?> generateText(String prompt) async {
    if (!isReady) return null;
    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    } catch (e) {
      debugPrint('텍스트 생성 오류: $e');
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 결과 클래스들
// ═══════════════════════════════════════════════════════════════

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
