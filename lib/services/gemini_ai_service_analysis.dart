// ignore_for_file: lines_longer_than_80_chars
part of 'gemini_ai_service.dart';

/// GeminiAiService 확장 - 음성 명령, 분석, 텍스트 생성
extension GeminiAiServiceAnalysis on GeminiAiService {
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
