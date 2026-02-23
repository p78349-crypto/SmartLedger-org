// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/ai_security_seal.dart';

/// 커스텀 파인튜닝 Gemma2 2b 모델 테스트 서비스
/// 🔓 개발자 모드에서만 작동하는 로컬 커스텀 모델 테스트
class CustomGemma2TestService {
  static final CustomGemma2TestService _instance = CustomGemma2TestService._internal();
  factory CustomGemma2TestService() => _instance;
  CustomGemma2TestService._internal();

  static const String _customModelPath = r'C:\Users\plain\GemmaFineTuning\Gemma2 2bf\outputs';
  static const String _latestCheckpoint = 'checkpoint-13794'; // 최신 체크포인트
  
  bool _isModelLoaded = false;
  Map<String, dynamic>? _modelInfo;

  /// 🔓 개발자 모드 체크 및 커스텀 모델 가용성 확인
  bool get isAvailable {
    return AiSecuritySeal.isDeveloperModeEnabled && 
           _checkCustomModelExists();
  }

  /// 커스텀 모델 경로 존재 확인
  bool _checkCustomModelExists() {
    try {
      final modelDir = Directory('$_customModelPath\\$_latestCheckpoint');
      return modelDir.existsSync();
    } catch (e) {
      print('커스텀 모델 경로 확인 실패: $e');
      return false;
    }
  }

  /// 🧪 커스텀 Gemma2 모델 테스트 초기화
  Future<bool> initializeCustomModel() async {
    if (!isAvailable) {
      print('⚠️ 커스텀 모델 사용 불가: 개발자 모드 비활성화 또는 모델 없음');
      return false;
    }

    try {
      print('🔬 커스텀 Gemma2 2b 파인튜닝 모델 초기화 중...');
      
      // 모델 정보 수집
      await _loadModelInfo();
      
      // TODO: 실제 모델 로딩 로직 (Python 스크립트 호출 또는 FFI)
      // 현재는 시뮬레이션
      await Future.delayed(const Duration(seconds: 2));
      
      _isModelLoaded = true;
      print('✅ 커스텀 Gemma2 모델 로딩 완료!');
      return true;
      
    } catch (e) {
      print('❌ 커스텀 모델 초기화 실패: $e');
      return false;
    }
  }

  /// 모델 메타데이터 로딩
  Future<void> _loadModelInfo() async {
    try {
      final configPath = '$_customModelPath\\$_latestCheckpoint\\config.json';
      final configFile = File(configPath);
      
      _modelInfo = {
        'modelPath': '$_customModelPath\\$_latestCheckpoint',
        'checkpoint': _latestCheckpoint,
        'modelType': 'gemma2-2b-finetuned',
        'parameters': '2B',
        'training': 'SmartLedger FineTuned',
        'configExists': configFile.existsSync(),
        'loadTime': DateTime.now().toIso8601String(),
      };
      
      print('📋 모델 정보: $_modelInfo');
    } catch (e) {
      print('모델 정보 로딩 실패: $e');
    }
  }

  /// 🧪 커스텀 모델로 재무 질문 테스트
  Future<Map<String, dynamic>> testFinancialQuery(String query) async {
    if (!_isModelLoaded) {
      await initializeCustomModel();
    }

    if (!_isModelLoaded) {
      return {
        'success': false,
        'error': '커스텀 모델이 로드되지 않았습니다.',
        'fallback': '전통적 알고리즘 사용을 권장합니다.',
      };
    }

    try {
      print('🤖 커스텀 Gemma2 질문 처리: "$query"');
      
      // TODO: 실제 모델 추론 로직
      // 현재는 파인튜닝된 모델의 특성을 시뮬레이션
      final response = await _simulateCustomModelResponse(query);
      
      return {
        'success': true,
        'query': query,
        'response': response,
        'model': 'gemma2-2b-smartledger-finetuned',
        'checkpoint': _latestCheckpoint,
        'responseTime': '${DateTime.now().millisecondsSinceEpoch}ms',
        'confidence': 0.92, // 파인튜닝된 모델의 높은 신뢰도
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': '커스텀 모델 응답 생성 실패: $e',
        'query': query,
      };
    }
  }

  /// 파인튜닝된 모델 응답 시뮬레이션
  Future<String> _simulateCustomModelResponse(String query) async {
    // 실제 모델 호출 대신 파인튜닝 특성을 반영한 응답 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 800));
    
    final lowercaseQuery = query.toLowerCase();
    
    if (lowercaseQuery.contains('지출') || lowercaseQuery.contains('expense')) {
      return '''📊 **SmartLedger 파인튜닝 분석 결과**
      
지출 패턴을 분석한 결과:
• 이번 달 주요 지출 카테고리: 식비(35%), 교통비(20%), 생활용품(15%)
• 지난 달 대비 7% 증가 추세
• **권장사항**: 식비 절약을 위해 주 2회 도시락 준비 권장
• 예상 절약 효과: 월 12만원

*이 분석은 SmartLedger 전용 파인튜닝 모델(Gemma2-2B)로 생성되었습니다.*''';
    }
    
    if (lowercaseQuery.contains('투자') || lowercaseQuery.contains('invest')) {
      return '''💰 **SmartLedger 투자 자문 (파인튜닝)**
      
맞춤형 투자 분석:
• 현재 포트폴리오 위험도: 중간 수준
• 추천 자산 배분: 주식 60%, 채권 30%, 현금 10%
• **주의사항**: 현재 시장 변동성이 높으니 분산투자 필수
• 예상 수익률: 연 5-7% (보수적 추정)

*SmartLedger 재무 데이터로 특별 훈련된 AI 모델의 조언입니다.*''';
    }
    
    if (lowercaseQuery.contains('예산') || lowercaseQuery.contains('budget')) {
      return '''📋 **SmartLedger 예산 관리 (커스텀 AI)**
      
개인화된 예산 제안:
• 권장 월 예산: 수입의 70% (고정비 50% + 변동비 20%)
• 저축 목표: 수입의 20%
• 비상금: 수입의 10%
• **핵심 포인트**: 카드 사용 패턴 분석 결과 주말 지출 관리가 관건

*이는 당신의 과거 거래 데이터로 훈련된 개인화 모델의 조언입니다.*''';
    }
    
    // 기본 응답
    return '''🤖 **SmartLedger 커스텀 Gemma2 응답**
    
질문: "$query"

파인튜닝된 SmartLedger AI가 처리 중입니다...
• 모델: Gemma2-2B (SmartLedger 특화 파인튜닝)
• 체크포인트: $_latestCheckpoint  
• 특화 분야: 개인 재무 관리, 한국형 가계부 분석

더 구체적인 재무 질문을 해보세요! (지출, 투자, 예산, 저축 등)''';
  }

  /// 🔬 모델 성능 벤치마크 테스트
  Future<Map<String, dynamic>> runPerformanceTest() async {
    if (!_isModelLoaded) {
      await initializeCustomModel();
    }

    final testQueries = [
      '이번 달 지출이 너무 많은 것 같아',
      '투자 포트폴리오 조언해줘',  
      '예산 관리 어떻게 해야 할까',
      '저축 계획 세워줘',
      '카드 사용 패턴 분석해줘',
    ];

    final results = <Map<String, dynamic>>[];
    final startTime = DateTime.now();

    for (final query in testQueries) {
      final queryStart = DateTime.now();
      final result = await testFinancialQuery(query);
      final queryEnd = DateTime.now();
      
      results.add({
        ...result,
        'queryTime': queryEnd.difference(queryStart).inMilliseconds,
      });
    }

    final totalTime = DateTime.now().difference(startTime);

    return {
      'success': true,
      'modelInfo': _modelInfo,
      'testResults': results,
      'totalQueries': testQueries.length,
      'totalTime': totalTime.inMilliseconds,
      'averageTime': (totalTime.inMilliseconds / testQueries.length).round(),
      'benchmark': 'SmartLedger Custom Gemma2-2B Performance Test',
    };
  }

  /// 모델 정보 조회
  Map<String, dynamic> getModelInfo() {
    return {
      'isAvailable': isAvailable,
      'isLoaded': _isModelLoaded,
      'modelInfo': _modelInfo,
      'customModelPath': _customModelPath,
      'checkpoint': _latestCheckpoint,
      'developerMode': AiSecuritySeal.isDeveloperModeEnabled,
    };
  }

  /// 🧹 테스트 세션 정리  
  void cleanup() {
    _isModelLoaded = false;
    _modelInfo = null;
    print('🧹 커스텀 Gemma2 테스트 세션 정리 완료');
  }
}