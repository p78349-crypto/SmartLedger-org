import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Google AI Edge SDK (AICore)를 통한 Gemini Nano 호출
///
/// 안드로이드 시스템에 내장된 Gemini Nano를 직접 활용
/// - 완전 오프라인 동작
/// - API 키 불필요
/// - 빠른 응답 속도
/// - 시스템 리소스 최적화
class AICoreGeminiService {
  static const MethodChannel _channel = MethodChannel('com.smartledger/aicore');

  /// AICore 사용 가능 여부 확인 및 초기화 시도
  Future<bool> isAvailable() async {
    try {
      final available = await _channel.invokeMethod<bool>('isAICoreAvailable');
      if (available == true) {
        // 모델이 존재하면 로드 시도
        await _channel.invokeMethod<bool>('loadModel');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AICore] 상태 체크 실패: $e');
      return false;
    }
  }

  /// 영수증 텍스트 파싱 (온디바이스 Gemini Nano)
  ///
  /// [ocrText]: OCR로 추출된 영수증 텍스트
  ///
  /// Returns: {
  ///   "store": "스토어명",
  ///   "date": "2026-01-28",
  ///   "items": [{"name": "사과", "qty": 2, "unit_price": 2500, "total": 5000}],
  ///   "total": 5000,
  ///   "confidence": 0.95
  /// }
  Future<Map<String, dynamic>> parseReceiptText(String ocrText) async {
    try {
      final prompt =
          '''
다음 영수증 텍스트를 JSON으로 변환하세요:

$ocrText

JSON 형식:
{
  "store": "상점명",
  "date": "YYYY-MM-DD",
  "items": [
    {"name": "상품명", "qty": 수량, "unit_price": 단가, "total": 소계}
  ],
  "total": 총액,
  "confidence": 0.0-1.0
}
''';

      final result = await _channel.invokeMethod<String>('generateText', {
        'prompt': prompt,
      });

      if (result == null) {
        return {'error': 'AICore에서 응답이 없습니다'};
      }

      return _extractJson(result);
    } catch (e) {
      return {'error': 'AICore 처리 실패: $e'};
    }
  }

  /// 음성 입력 처리 (자연어 이해)
  ///
  /// [userSpeech]: "마트에서 사과 2개 5000원 샀어"
  ///
  /// Returns: 구조화된 거래 정보
  Future<Map<String, dynamic>> processVoiceInput(String userSpeech) async {
    try {
      final prompt =
          '''
다음 음성 입력을 가계부 거래로 변환하세요:

"$userSpeech"

JSON 형식:
{
  "store": "상점명",
  "date": "오늘 날짜",
  "items": [{"name": "상품명", "qty": 수량, "unit_price": 단가, "total": 금액}],
  "total": 총액,
  "category": "식비|교통비|일용품|의류|문화|의료|기타",
  "confidence": 0.0-1.0
}
''';

      final result = await _channel.invokeMethod<String>('generateText', {
        'prompt': prompt,
      });

      if (result == null) {
        return {'error': 'AICore에서 응답이 없습니다'};
      }

      return _extractJson(result);
    } catch (e) {
      return {'error': 'AICore 처리 실패: $e'};
    }
  }

  /// 카테고리 자동 분류 (Gemma 2 2B 온디바이스 모델 활용)
  Future<String?> predictCategory(String itemName, {List<String>? candidateCategories}) async {
    try {
      // 기본 카테고리 목록 (기본은 지출용)
      final categories = candidateCategories ?? [
        '식비',
        '식품·음료비',
        '주거비',
        '교통비',
        '통신비',
        '생활용품비',
        '의료비',
        '문화/여가/자기개발',
        '용돈/경조사비',
        '의류/잡화',
        '저축/투자'
      ];

      final prompt = '''
상품명: "$itemName"

위 상품에 가장 적절한 가계부 카테고리를 다음 목록 중에서 하나만 선택하여 답변하세요.
목록: ${categories.join(', ')}

답변:
''';

      final result = await _channel.invokeMethod<String>('generateText', {
        'prompt': prompt,
      });

      final prediction = result?.trim() ?? '';
      
      // 결과 중 유효한 카테고리가 포함되어 있는지 확인
      for (final cat in categories) {
        if (prediction.contains(cat)) return cat;
      }
      
      return null;
    } catch (e) {
      debugPrint('[AICore] 카테고리 예측 실패: $e');
      return null;
    }
  }

  /// 다국어 자동 감지 및 번역
  ///
  /// [text]: 모든 언어의 텍스트 (영어, 중국어, 일본어, 한국어 등)
  /// [targetLang]: 목표 언어 ("ko", "en", "ja", "zh")
  ///
  /// Returns: {
  ///   "detected_language": "en",
  ///   "original_text": "Starbucks Americano 5 dollars",
  ///   "translated_text": "스타벅스 아메리카노 5달러",
  ///   "parsed_data": {...거래 정보...}
  /// }
  Future<Map<String, dynamic>> translateAndParse(
    String text, {
    String targetLang = 'ko',
  }) async {
    try {
      final prompt =
          '''
다음 텍스트를 분석하세요:

텍스트: "$text"

작업:
1. 언어 감지
2. ${_getLanguageName(targetLang)}로 번역
3. 가계부 거래 정보 추출

JSON 형식:
{
  "detected_language": "언어코드",
  "original_text": "원문",
  "translated_text": "번역문",
  "parsed_data": {
    "store": "상점명",
    "items": [{"name": "상품명", "qty": 수량, "total": 금액}],
    "total": 총액,
    "currency": "통화"
  }
}
''';

      final result = await _channel.invokeMethod<String>('generateText', {
        'prompt': prompt,
      });

      if (result == null) {
        return {'error': 'AICore에서 응답이 없습니다'};
      }

      return _extractJson(result);
    } catch (e) {
      return {'error': 'AICore 처리 실패: $e'};
    }
  }

  /// 실시간 음성 번역
  ///
  /// [voiceText]: 음성 인식된 텍스트 (모든 언어)
  /// [targetLang]: 목표 언어
  ///
  /// 사용 예:
  /// ```dart
  /// final result = await translateVoiceToKorean("Convenience store milk 3 dollars");
  /// // → "편의점 우유 3달러"
  /// ```
  Future<Map<String, dynamic>> translateVoiceToKorean(String voiceText) async {
    return await translateAndParse(voiceText);
  }

  /// 다국어 영수증 파싱
  ///
  /// 영어, 중국어, 일본어 영수증을 자동 감지하고 한국어로 변환
  Future<Map<String, dynamic>> parseMultilingualReceipt(
    String receiptText,
  ) async {
    try {
      final prompt =
          '''
다음 영수증을 분석하고 한국어로 변환하세요:

$receiptText

JSON 형식:
{
  "detected_language": "언어코드",
  "store": "상점명 (한국어)",
  "date": "YYYY-MM-DD",
  "items": [
    {"name": "상품명 (한국어)", "qty": 수량, "unit_price": 단가, "total": 소계}
  ],
  "total": 총액,
  "original_currency": "원래 통화",
  "converted_krw": "원화 환산액 (선택)"
}
''';

      final result = await _channel.invokeMethod<String>('generateText', {
        'prompt': prompt,
      });

      if (result == null) {
        return {'error': 'AICore에서 응답이 없습니다'};
      }

      return _extractJson(result);
    } catch (e) {
      return {'error': 'AICore 처리 실패: $e'};
    }
  }

  /// 언어 코드 → 이름 변환
  String _getLanguageName(String langCode) {
    const languages = {
      'ko': '한국어',
      'en': '영어',
      'ja': '일본어',
      'zh': '중국어',
      'es': '스페인어',
      'fr': '프랑스어',
    };
    return languages[langCode] ?? '한국어';
  }

  /// JSON 추출 (Gemini 응답에서 JSON만 파싱)
  Map<String, dynamic> _extractJson(String response) {
    try {
      // ```json ... ``` 형식 제거
      var cleaned = response.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }

      // JSON 파싱
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      }

      return {'error': 'JSON 파싱 실패', 'raw': response};
    } catch (e) {
      return {'error': 'JSON 디코딩 실패: $e', 'raw': response};
    }
  }

  /// 사용자 선호 언어 가져오기 (시스템 언어 기반)
  ///
  /// 예: 일본에서 사용 → 'ja' 반환
  ///     한국에서 사용 → 'ko' 반환
  static Future<String> getPreferredLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 사용자가 수동으로 설정한 언어 확인 (기존 설정 재사용)
    final userLang = prefs.getString('user_language');
    if (userLang != null && userLang != 'system') {
      return userLang;
    }

    // 2. 시스템 언어 기본값 (한국어)
    return 'ko';
  }

  /// 선호 언어 설정 (기존 언어 설정과 호환)
  static Future<void> setPreferredLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', langCode);
  }
}
