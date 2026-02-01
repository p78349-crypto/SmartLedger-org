import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'gemma_api_service.dart';
import 'gemini_ai_service.dart';

/// 영수증 처리 통합 서비스
///
/// Gemma API와 Gemini API를 조합하여 최적의 결과를 제공합니다.
///
/// 처리 순서:
/// 1. Gemma API 시도 (로컬, 빠름, 정확함)
/// 2. 실패 시 Gemini API 폴백 (클라우드, 느림)
class ReceiptProcessingService {
  static final ReceiptProcessingService _instance =
      ReceiptProcessingService._internal();
  factory ReceiptProcessingService() => _instance;
  ReceiptProcessingService._internal();

  final GemmaApiService _gemmaService = GemmaApiService();
  final GeminiAiService _geminiService = GeminiAiService.instance;

  /// 영수증 텍스트 처리
  ///
  /// [ocrText]: OCR로 추출된 원본 텍스트
  /// [forceGemini]: true면 Gemma 건너뛰고 Gemini 사용
  ///
  /// Returns: (성공 여부, 결과, 사용된 모델)
  Future<ReceiptProcessingResult> processReceipt({
    required String ocrText,
    bool forceGemini = false,
  }) async {
    debugPrint('🔍 Receipt processing started');
    debugPrint('OCR text length: ${ocrText.length} chars');

    // 1. Gemma API 시도 (로컬 우선)
    if (!forceGemini) {
      final needsCheck = _gemmaService.needsHealthCheck;
      if (needsCheck) {
        debugPrint('🏥 Checking Gemma server health...');
        await _gemmaService.checkHealth();
      }

      if (_gemmaService.isServerHealthy) {
        debugPrint('🤖 Trying Gemma API (local)...');
        final gemmaResult = await _gemmaService.extractReceiptInfo(ocrText);

        if (gemmaResult != null) {
          debugPrint('✅ Gemma extraction successful!');
          return ReceiptProcessingResult(
            success: true,
            data: gemmaResult,
            model: 'Gemma 2 2B (Local)',
          );
        } else {
          debugPrint('⚠️ Gemma extraction returned null');
        }
      } else {
        debugPrint('⚠️ Gemma server not available, skipping...');
      }
    }

    // 2. Gemini API 폴백
    if (_geminiService.isReady) {
      debugPrint('🌐 Falling back to Gemini API (cloud)...');

      try {
        // Gemini에게 구조화 요청
        final prompt =
            '''
다음 영수증 텍스트를 분석하여 JSON 형식으로 상품 정보를 추출해주세요.

영수증 텍스트:
$ocrText

JSON 형식 (다른 텍스트 없이 JSON만 출력):
{
  "store_name": "상점명",
  "date": "YYYY-MM-DD",
  "items": [
    {
      "name": "상품명",
      "quantity": 수량,
      "unit_price": 단가,
      "total_price": 총액
    }
  ],
  "total_amount": 총합계
}
''';

        final response = await _geminiService.generateText(prompt);

        if (response != null && response.isNotEmpty) {
          // JSON 파싱 시도
          final parsed = _parseGeminiResponse(response);
          if (parsed != null) {
            debugPrint('✅ Gemini extraction successful!');
            return ReceiptProcessingResult(
              success: true,
              data: parsed,
              model: 'Gemini (Cloud)',
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Gemini processing error: $e');
      }
    }

    // 3. 모두 실패
    debugPrint('❌ All receipt processing methods failed');
    return ReceiptProcessingResult(
      success: false,
      model: 'None',
      error: 'Gemma 서버를 사용할 수 없고 Gemini API도 실패했습니다.',
    );
  }

  /// Gemini 응답에서 JSON 추출 및 파싱
  ReceiptExtractionResult? _parseGeminiResponse(String response) {
    try {
      // JSON 블록 찾기
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        debugPrint('⚠️ No JSON found in Gemini response');
        return null;
      }

      final jsonStr = response.substring(jsonStart, jsonEnd + 1);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      return ReceiptExtractionResult.fromJson(json);
    } catch (e) {
      debugPrint('❌ Failed to parse Gemini JSON: $e');
      return null;
    }
  }

  /// Gemma 서버 상태 확인
  Future<bool> checkGemmaServerHealth() {
    return _gemmaService.checkHealth();
  }

  /// Gemma 서버 사용 가능 여부
  bool get isGemmaServerAvailable => _gemmaService.isServerHealthy;

  /// Gemini API 사용 가능 여부
  bool get isGeminiAvailable => _geminiService.isReady;
}

/// 영수증 처리 결과
class ReceiptProcessingResult {
  final bool success;
  final ReceiptExtractionResult? data;
  final String model;
  final String? error;

  ReceiptProcessingResult({
    required this.success,
    this.data,
    required this.model,
    this.error,
  });
}
