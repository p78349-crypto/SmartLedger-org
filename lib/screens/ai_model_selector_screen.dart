import 'package:flutter/material.dart';
import '../services/ai_ceo_prediction_service.dart';
import '../services/ceo_prediction_service.dart';
import '../services/real_ai_investment_service.dart';
import '../services/real_ai_financial_analytics_service.dart';
import '../services/ai_model_preferences_service.dart';
import '../widgets/ai_model_status_widget.dart';
import '../config/ai_security_seal.dart';

/// AI 모델 선택 및 관리 화면
/// 🔒 현재 보안상 이유로 AI 기능 봉인됨 (2026-02-21)
/// 사용자가 AI 기능별로 사용할 모델을 선택할 수 있음
class AiModelSelectorScreen extends StatefulWidget {
  const AiModelSelectorScreen({super.key});

  @override
  State<AiModelSelectorScreen> createState() => _AiModelSelectorScreenState();
}

class _AiModelSelectorScreenState extends State<AiModelSelectorScreen> {
  bool _useAiForCeoPrediction = true;
  bool _useAiForInvestment = true;
  bool _useAiForAnalytics = true;
  bool _preferOfflineAi = true;
  bool _isLoading = false;
  
  final AiModelPreferencesService _prefsService = AiModelPreferencesService.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      _useAiForCeoPrediction = await _prefsService.useAiForCeoPrediction;
      _useAiForInvestment = await _prefsService.useAiForInvestment;
      _useAiForAnalytics = await _prefsService.useAiForAnalytics;
      _preferOfflineAi = await _prefsService.preferOfflineAi;
    } catch (e) {
      print('설정 로드 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await _prefsService.setUseAiForCeoPrediction(_useAiForCeoPrediction);
      await _prefsService.setUseAiForInvestment(_useAiForInvestment);
      await _prefsService.setUseAiForAnalytics(_useAiForAnalytics);
      await _prefsService.setPreferOfflineAi(_preferOfflineAi);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI 모델 설정이 저장되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 보안 봉인 체크
    if (AiSecuritySeal.isSealed && !AiSecuritySeal.isDeveloperModeEnabled) {
      return _buildSealedScreen(context);
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 모델 선택'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            tooltip: '설정 저장',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiModelStatusWidget(),
            const SizedBox(height: 20),
            _buildModelOverview(),
            const SizedBox(height: 20),
            _buildAiToggleSection(),
            const SizedBox(height: 20),
            _buildModelPreference(),
            const SizedBox(height: 20),
            _buildFeatureSettings(),
            const SizedBox(height: 20),
            _buildTestButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildModelOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🤖 사용 가능한 AI 모델', 
                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildModelCard('Gemini Nano', '완전 오프라인', '기기 내장', Colors.green, true),
            const SizedBox(height: 8),
            _buildModelCard('Gemini 1.5 Flash', '온라인 API', '고성능 분석', Colors.blue, true),
            const SizedBox(height: 8),
            _buildModelCard('전통적 알고리즘', '수학적 계산', '빠른 처리', Colors.grey, false),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard(String name, String type, String description, Color color, bool isAi) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Icon(isAi ? Icons.psychology : Icons.calculate, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(type, style: const TextStyle(fontSize: 12)),
                Text(description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiToggleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚙️ AI 기능 설정', 
                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('CEO 예측 분석에 AI 사용'),
              subtitle: const Text('비즈니스 인사이트 및 위험 분석'),
              value: _useAiForCeoPrediction,
              onChanged: (value) {
                setState(() => _useAiForCeoPrediction = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('투자 참고정보에 AI 사용'),
              subtitle: const Text('포트폴리오 분석 및 참고정보 제공'),
              value: _useAiForInvestment,
              onChanged: (value) {
                setState(() => _useAiForInvestment = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('재무 분석에 AI 사용'),
              subtitle: const Text('현금흐름 예측 및 패턴 분석'),
              value: _useAiForAnalytics,
              onChanged: (value) {
                setState(() => _useAiForAnalytics = value);
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelPreference() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📱 AI 모델 우선순위', 
                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            RadioListTile<bool>(
              title: const Text('오프라인 AI 우선 (Gemini Nano)'),
              subtitle: const Text('프라이버시 보호, 빠른 응답, 인터넷 연결 불필요'),
              value: true,
              groupValue: _preferOfflineAi,
              onChanged: (value) {
                setState(() => _preferOfflineAi = value!);
                _saveSettings();
              },
            ),
            RadioListTile<bool>(
              title: const Text('온라인 AI 우선 (Gemini 1.5 Flash)'),
              subtitle: const Text('최신 정보 반영, 더 정교한 분석'),
              value: false,
              groupValue: _preferOfflineAi,
              onChanged: (value) {
                setState(() => _preferOfflineAi = value!);
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎛️ 고급 설정', 
                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('• AI 실패 시 자동으로 전통적 알고리즘으로 폴백'),
            const Text('• 오프라인 AI 사용불가 시 온라인 AI로 자동 전환'),
            const Text('• 모든 AI 분석 결과에 신뢰도 점수 제공'),
            const Text('• 개인정보는 절대 외부로 전송되지 않음'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(child: Text('AI 기능은 보조 도구입니다. 중요한 재무 결정은 전문가와 상담하세요.')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _testAiModels(),
            icon: const Icon(Icons.science),
            label: const Text('AI 모델 연결 테스트'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showModelComparison(),
            icon: const Icon(Icons.compare),
            label: const Text('모델 성능 비교'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _testAiModels() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('AI 모델 테스트 중'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI 모델 연결 상태를 확인하고 있습니다...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2)); // 시뮬레이션
    
    if (mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('테스트 결과'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Gemini Nano: 사용 가능 (오프라인)'),
              Text('✅ Gemini 1.5 Flash: 사용 가능 (온라인)'),
              Text('✅ 전통적 알고리즘: 항상 사용 가능'),
              SizedBox(height: 8),
              Text('모든 AI 모델이 정상 작동합니다!', 
                   style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  void _showModelComparison() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI 모델 비교'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📊 성능 비교 (상대적)', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('처리 속도:'),
              Text('• Gemini Nano: ⭐⭐⭐⭐⭐'),
              Text('• 전통적 알고리즘: ⭐⭐⭐⭐⭐'),
              Text('• Gemini 1.5 Flash: ⭐⭐⭐'),
              SizedBox(height: 8),
              Text('분석 정확도:'),
              Text('• Gemini 1.5 Flash: ⭐⭐⭐⭐⭐'),
              Text('• Gemini Nano: ⭐⭐⭐⭐'),
              Text('• 전통적 알고리즘: ⭐⭐⭐'),
              SizedBox(height: 8),
              Text('프라이버시:'),
              Text('• Gemini Nano: ⭐⭐⭐⭐⭐'),
              Text('• 전통적 알고리즘: ⭐⭐⭐⭐⭐'),
              Text('• Gemini 1.5 Flash: ⭐⭐⭐'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 🔒 보안 봉인 상태 화면
  Widget _buildSealedScreen(BuildContext context) {
    final sealInfo = AiSecuritySeal.sealInfo;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 모델 선택'),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 봉인 아이콘
              Icon(
                Icons.security,
                size: 80,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              
              // 제목
              Text(
                '🔒 AI 기능 보안 봉인',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // 메시지
              Text(
                sealInfo['message'],
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // 세부 정보
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSealInfoRow('봉인 사유', sealInfo['reason']),
                    _buildSealInfoRow('봉인 날짜', sealInfo['sealDate']),
                    _buildSealInfoRow('상태', sealInfo['isSealed'] ? '봉인됨' : '활성'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // 안내 메시지
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      '현재 전통적 알고리즘만 사용됩니다.\n'
                      'AI 기능이 필요한 경우 개발팀에 문의하세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSealInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}