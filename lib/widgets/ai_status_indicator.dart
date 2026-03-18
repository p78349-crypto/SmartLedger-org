import 'package:flutter/material.dart';
import '../services/ai_model_preferences_service.dart';
import '../config/ai_security_seal.dart';

/// 현재 AI 설정을 간단하게 표시하는 위젯
/// 🔒 현재 보안상 이유로 AI 기능 봉인됨 (2026-02-21)
/// 다른 화면에서 AI 상태를 빠르게 확인할 때 사용
class AiStatusIndicator extends StatefulWidget {
  final AiFeature? feature;
  final bool showLabel;

  const AiStatusIndicator({super.key, this.feature, this.showLabel = true});

  @override
  State<AiStatusIndicator> createState() => _AiStatusIndicatorState();
}

class _AiStatusIndicatorState extends State<AiStatusIndicator> {
  final AiModelPreferencesService _prefsService =
      AiModelPreferencesService.instance;

  bool _aiEnabled = true;
  bool _preferOffline = true;
  bool _featureEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAiStatus();
  }

  Future<void> _loadAiStatus() async {
    try {
      _aiEnabled = await _prefsService.aiEnabled;
      _preferOffline = await _prefsService.preferOfflineAi;

      if (widget.feature != null) {
        _featureEnabled = await _prefsService.shouldUseAiFor(widget.feature!);
      }

      if (mounted) setState(() {});
    } catch (e) {
      print('AI 상태 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 보안 봉인 체크
    if (AiSecuritySeal.isSealed && !AiSecuritySeal.isDeveloperModeEnabled) {
      return _buildIndicator(
        icon: Icons.security,
        color: Colors.red,
        label: 'AI 봉인됨',
      );
    }

    if (!_aiEnabled || (widget.feature != null && !_featureEnabled)) {
      return _buildIndicator(
        icon: Icons.calculate,
        color: Colors.grey,
        label: '전통적 알고리즘',
      );
    }

    return _buildIndicator(
      icon: _preferOffline ? Icons.offline_bolt : Icons.cloud,
      color: _preferOffline ? Colors.green : Colors.blue,
      label: _preferOffline ? 'Gemini Nano' : 'Gemini Flash',
    );
  }

  Widget _buildIndicator({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    if (!widget.showLabel) {
      return Icon(icon, color: color, size: 16);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// AI 기능별 상태를 표시하는 위젯
class AiFeatureStatus extends StatelessWidget {
  final String featureName;
  final AiFeature feature;

  const AiFeatureStatus({
    super.key,
    required this.featureName,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.psychology),
        title: Text(featureName),
        trailing: AiStatusIndicator(feature: feature, showLabel: true),
        onTap: () {
          // AI 모델 선택 화면으로 이동
          Navigator.pushNamed(context, '/ai/model-selector');
        },
      ),
    );
  }
}

/// 전체 AI 시스템 상태를 요약해서 보여주는 위젯
class AiSystemStatusSummary extends StatefulWidget {
  const AiSystemStatusSummary({super.key});

  @override
  State<AiSystemStatusSummary> createState() => _AiSystemStatusSummaryState();
}

class _AiSystemStatusSummaryState extends State<AiSystemStatusSummary> {
  final AiModelPreferencesService _prefsService =
      AiModelPreferencesService.instance;

  Map<String, dynamic> _statusSummary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatusSummary();
  }

  Future<void> _loadStatusSummary() async {
    try {
      final summary = await _prefsService.getSettingsSummary();
      setState(() {
        _statusSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 보안 봉인 체크
    if (AiSecuritySeal.isSealed && !AiSecuritySeal.isDeveloperModeEnabled) {
      return _buildSealedSummary(context);
    }

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final aiEnabled = _statusSummary['aiEnabled'] ?? false;
    final modelPriority =
        _statusSummary['modelPriority'] as List<String>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🤖 AI 시스템 상태',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/ai/model-selector'),
                  icon: const Icon(Icons.settings, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'AI 기능',
              aiEnabled ? '활성화됨' : '비활성화됨',
              aiEnabled ? Colors.green : Colors.grey,
            ),
            if (modelPriority.isNotEmpty)
              _buildSummaryRow('우선 모델', modelPriority.first, Colors.blue),
            _buildSummaryRow(
              'CEO 예측',
              _statusSummary['useAiForCeoPrediction'] == true ? 'AI 사용' : '전통적',
              _statusSummary['useAiForCeoPrediction'] == true
                  ? Colors.purple
                  : Colors.grey,
            ),
            _buildSummaryRow(
              '투자 참고정보',
              _statusSummary['useAiForInvestment'] == true ? 'AI 사용' : '전통적',
              _statusSummary['useAiForInvestment'] == true
                  ? Colors.purple
                  : Colors.grey,
            ),
            _buildSummaryRow(
              '재무 분석',
              _statusSummary['useAiForAnalytics'] == true ? 'AI 사용' : '전통적',
              _statusSummary['useAiForAnalytics'] == true
                  ? Colors.purple
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔒 보안 봉인 상태 요약
  Widget _buildSealedSummary(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      '🔒 AI 시스템 상태',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.block, color: Colors.red, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('AI 기능', '보안 봉인됨', Colors.red),
            _buildSummaryRow('현재 모델', '전통적 알고리즘만', Colors.grey),
            _buildSummaryRow('CEO 예측', '통계 기반', Colors.grey),
            _buildSummaryRow('투자 참고정보', '수학적 계산', Colors.grey),
            _buildSummaryRow('재무 분석', '패턴 분석', Colors.grey),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '⚠️ 국제적 보안 요구사항으로 AI 기능이 일시 비활성화됨 (2026-02-21)',
                style: TextStyle(fontSize: 11, color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
