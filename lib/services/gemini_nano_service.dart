// ignore_for_file: avoid_slow_async_io

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Gemini Nano를 사용한 영수증 파싱 서비스
/// 음성, 이미지, 텍스트 모두 처리 가능
class GeminiNanoService {
  static const String _apiKey = 'YOUR_GEMINI_API_KEY'; // TODO: 설정 필요
  late final GenerativeModel _model;

  GeminiNanoService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash', // Nano 모델 또는 Flash
      apiKey: _apiKey,
    );
  }

  /// OCR 텍스트 파싱 (가장 빠름)
  Future<Map<String, dynamic>> parseReceiptText(String ocrText) async {
    try {
      final prompt = '''
당신은 가계부 AI 비서입니다. 다음 영수증 텍스트를 분석하고 구조화된 데이터로 변환하세요.

입력: $ocrText

다음 JSON 형식으로 응답하세요:
{
  "store": "상점명",
  "date": "YYYY-MM-DD (없으면 오늘 날짜)",
  "items": [
    {
      "name": "상품명",
      "qty": 수량,
      "unit_price": 단가,
      "total": 소계
    }
  ],
  "total": 총액,
  "payment_method": "결제수단 (선택)",
  "confidence": 0.95 (신뢰도, 0-1)
}

주의:
- JSON만 응답 (설명 없음)
- 단가 = 단위당 가격
- total = qty * unit_price
- 없는 정보는 null 사용
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseJsonResponse(response.text ?? '{}');
    } catch (e) {
      return {'error': '파싱 실패: $e', 'confidence': 0.0};
    }
  }

  /// 음성 + 자연언어 처리
  Future<Map<String, dynamic>> processVoiceInput(String userSpeech) async {
    try {
      final prompt = '''
사용자가 말한 영수증 정보: "$userSpeech"

이를 가계부 항목으로 구조화하세요.

예시:
입력: "마트에서 사과 2개 5000원하고 우유 2500원 샀어"
출력:
{
  "store": "마트",
  "items": [
    {"name": "사과", "qty": 2, "unit_price": 2500, "total": 5000},
    {"name": "우유", "qty": 1, "unit_price": 2500, "total": 2500}
  ],
  "total": 7500,
  "confidence": 0.95
}

JSON으로만 응답하세요.
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return _parseJsonResponse(response.text ?? '{}');
    } catch (e) {
      return {'error': '음성 처리 실패: $e', 'confidence': 0.0};
    }
  }

  /// 이미지 영수증 처리 (멀티모달)
  Future<Map<String, dynamic>> processReceiptImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return {'error': '이미지 파일 없음', 'confidence': 0.0};
      }

      final imageBytes = await imageFile.readAsBytes();
      final mimeType = _getMimeType(imagePath);

      const prompt = '''
이 영수증 사진에서 정보를 추출하세요:

필수:
- 상점명
- 항목 (상품명, 수량, 단가, 총액)
- 총액

선택:
- 구매 날짜
- 결제 수단

JSON 형식:
{
  "store": "...",
  "date": "YYYY-MM-DD",
  "items": [{"name": "...", "qty": ..., "unit_price": ..., "total": ...}],
  "total": ...,
  "confidence": 0.95
}
      ''';

      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ]);

      return _parseJsonResponse(response.text ?? '{}');
    } catch (e) {
      return {'error': '이미지 처리 실패: $e', 'confidence': 0.0};
    }
  }

  /// 복합 입력 처리 (음성 + 이미지)
  Future<Map<String, dynamic>> processMultiInput(
    String voiceText,
    String? imagePath,
  ) async {
    try {
      final voiceResult = await processVoiceInput(voiceText);

      if (imagePath != null) {
        final imageResult = await processReceiptImage(imagePath);
        return _mergeAndValidate(voiceResult, imageResult);
      }

      return voiceResult;
    } catch (e) {
      return {'error': '복합 처리 실패: $e', 'confidence': 0.0};
    }
  }

  /// 카테고리 자동 분류
  Future<String?> predictCategory(String itemName) async {
    try {
      final prompt = '''
가계부 항목 분류:
"$itemName"이 어느 카테고리에 속하는지 분류하세요.

가능한 분류:
- 식비 (식료품, 외식, 음료)
- 교통비 (버스, 택시, 주유, 주차)
- 일용품 (세제, 휴지, 샴푸 등)
- 의류 (옷, 신발, 액세서리)
- 문화 (영화, 책, 게임)
- 의료 (약, 병원)
- 기타

카테고리 이름만 응답하세요 (한국어).
      ''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    } catch (e) {
      return null;
    }
  }

  // ========== 헬퍼 함수 ==========

  String _getMimeType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Map<String, dynamic> _parseJsonResponse(String text) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        return Map<String, dynamic>.from(jsonDecode(jsonString) as Map);
      }
    } catch (e) {
      debugPrint('JSON 파싱 실패: $e');
    }
    return {'error': '응답 파싱 실패', 'confidence': 0.0};
  }

  Map<String, dynamic> _mergeAndValidate(
    Map<String, dynamic> voiceResult,
    Map<String, dynamic> imageResult,
  ) {
    final voiceConfidence = (voiceResult['confidence'] as num?)?.toDouble() ?? 0.8;
    final imageConfidence = (imageResult['confidence'] as num?)?.toDouble() ?? 0.9;

    if (imageConfidence > voiceConfidence) {
      return imageResult;
    }
    return voiceResult;
  }
}
