import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'gemini_ai_models.dart';
export 'gemini_ai_models.dart';

part 'gemini_ai_service_analysis.dart';

/// Gemini AI 서비스 (🔒 봉인 상태 유지)
class GeminiAiService {
  static GeminiAiService? _instance;
  GenerativeModel? _model;
  bool _isInitialized = false;

  GeminiAiService._();

  static GeminiAiService get instance {
    _instance ??= GeminiAiService._();
    return _instance!;
  }

  Future<void> initialize(String apiKey) async {
    if (_isInitialized) return;
    _model = GenerativeModel(
      model: 'sealed',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.0, maxOutputTokens: 1),
    );
    _isInitialized = true;
    debugPrint('🔒 Gemini AI 봉인 모드 초기화');
  }

  bool get isReady => _isInitialized && _model != null;

  Future<CategoryResult> classifyCategory(
    String description, {
    double? amount,
  }) async {
    if (!isReady) return CategoryResult.unknown();
    try {
      final prompt = jsonEncode({'description': description, 'amount': amount});
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.isEmpty) return CategoryResult.unknown();
      final parsed = jsonDecode(text);
      if (parsed is Map<String, dynamic>) {
        return CategoryResult(
          mainCategory: parsed['main'] as String? ?? '기타',
          subCategory: parsed['sub'] as String?,
          confidence: (parsed['confidence'] as num?)?.toDouble() ?? 0.0,
        );
      }
      return CategoryResult.unknown();
    } catch (_) {
      return CategoryResult.unknown();
    }
  }

  Future<QueryIntent> parseUserQuestion(String question) async {
    if (!isReady) return QueryIntent.unknown();
    try {
      final response = await _model!.generateContent([Content.text(question)]);
      final text = response.text;
      if (text == null || text.isEmpty) return QueryIntent.unknown();
      final parsed = jsonDecode(text);
      if (parsed is Map<String, dynamic>) {
        return QueryIntent.fromJson(parsed);
      }
      return QueryIntent.unknown();
    } catch (_) {
      return QueryIntent.unknown();
    }
  }
}

class GenerativeModel {
  GenerativeModel({
    required String model,
    required String apiKey,
    GenerationConfig? generationConfig,
  });

  Future<_SealedGenerateResponse> generateContent(
    List<dynamic> contents,
  ) async {
    return const _SealedGenerateResponse(null);
  }
}

class GenerationConfig {
  GenerationConfig({double? temperature, int? maxOutputTokens});
}

class Content {
  static String text(String value) => value;
}

class _SealedGenerateResponse {
  final String? text;
  const _SealedGenerateResponse(this.text);
}
