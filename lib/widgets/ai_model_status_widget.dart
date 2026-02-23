import 'package:flutter/material.dart';
import '../services/ai_model_preferences_service.dart';
import '../services/gemini_ai_service.dart';
import '../services/aicore_gemini_service.dart';
import '../config/ai_security_seal.dart';

/// AI 모델 상태 실시간 모니터링 위젯
/// 🔒 현재 보안상 이유로 AI 기능 봉인됨 (2026-02-21)
/// 각 AI 모델의 가용성, 성능, 응답 시간을 실시간으로 표시
class AiModelStatusWidget extends StatefulWidget {
  const AiModelStatusWidget({super.key});

  @override
  State<AiModelStatusWidget> createState() => _AiModelStatusWidgetState();
}

class _AiModelStatusWidgetState extends State<AiModelStatusWidget> {
  final AiModelPreferencesService _prefsService = AiModelPreferencesService.instance;
  final GeminiAiService _geminiService = GeminiAiService.instance;
  final AICoreGeminiService _aicoreService = AICoreGeminiService();

  Map<AiModelType, ModelStatus> _modelStatuses = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkModelStatuses();
  }

  Future<void> _checkModelStatuses() async {
    setState(() => _isLoading = true);

    final futures = <Future>[];
    
    // Gemini Nano 상태 확인
    futures.add(_checkGeminiNanoStatus());
    
    // Gemini Flash 상태 확인  
    futures.add(_checkGeminiFlashStatus());
    
    // 전통적 알고리즘 (항상 사용 가능)
    _modelStatuses[AiModelType.traditional] = ModelStatus(
      isAvailable: true,
      responseTime: 50,
      accuracy: 75,
      status: 'OK',
    );

    await Future.wait(futures);
    setState(() => _isLoading = false);
  }

  Future<void> _checkGeminiNanoStatus() async {
    try {
      final startTime = DateTime.now();
      final isAvailable = await _aicoreService.isAvailable();
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      _modelStatuses[AiModelType.geminiNano] = ModelStatus(
        isAvailable: isAvailable,
        responseTime: responseTime,
        accuracy: isAvailable ? 85 : 0,
        status: isAvailable ? 'OK' : 'Unavailable',
      );
    } catch (e) {
      _modelStatuses[AiModelType.geminiNano] = ModelStatus(
        isAvailable: false,
        responseTime: -1,
        accuracy: 0,
        status: 'Error: $e',
      );
    }
  }

  Future<void> _checkGeminiFlashStatus() async {
    try {
      final startTime = DateTime.now();
      // 간단한 연결 테스트
      await _geminiService.generateText('test');
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      _modelStatuses[AiModelType.geminiFlasch] = ModelStatus(
        isAvailable: true,
        responseTime: responseTime,
        accuracy: 92,
        status: 'OK',
      );
    } catch (e) {
      _modelStatuses[AiModelType.geminiFlasch] = ModelStatus(
        isAvailable: false,
        responseTime: -1,
        accuracy: 0,
        status: 'Network Error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 보안 봉인 체크
    if (AiSecuritySeal.isSealed && !AiSecuritySeal.isDeveloperModeEnabled) {
      return _buildSealedStatusCard();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🤖 AI 모델 상태', 
                           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _isLoading ? null : _checkModelStatuses,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_modelStatuses.isEmpty && !_isLoading)
              const Text('모델 상태를 확인하려면 새로고침 버튼을 누르세요.')
            else
              ..._modelStatuses.entries.map((entry) => 
                _buildModelStatusRow(entry.key, entry.value)),
            const SizedBox(height: 12),
            _buildStatusLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildModelStatusRow(AiModelType modelType, ModelStatus status) {
    final isOnline = modelType == AiModelType.geminiFlasch;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          // 모델 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: status.isAvailable ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getModelIcon(modelType),
              color: status.isAvailable ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // 모델 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(modelType.displayName, 
                         style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.blue.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isOnline ? '온라인' : '오프라인',
                        style: TextStyle(
                          fontSize: 10,
                          color: isOnline ? Colors.blue : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (status.responseTime >= 0)
                      Text('${status.responseTime}ms', 
                           style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    if (status.responseTime >= 0) const Text(' • ', 
                                                              style: TextStyle(fontSize: 12)),
                    Text('정확도 ${status.accuracy}%', 
                         style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          
          // 상태 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
            ),
            child: Text(
              _getStatusText(status),
              style: TextStyle(
                color: _getStatusColor(status),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔒 보안 봉인 상태 카드
  Widget _buildSealedStatusCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text('🔒 AI 모델 상태 (봉인됨)', 
                           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.calculate, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('전통적 알고리즘만 사용 가능', 
                             style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('AI 기능은 보안상 이유로 비활성화됨', 
                             style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text('OK', 
                       style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ 국제적 보안 요구사항으로 인해 AI 모델이 일시적으로 비활성화되었습니다.',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('상태 범례:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildLegendItem(Colors.green, 'OK'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.orange, '느림'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.red, '오류'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  IconData _getModelIcon(AiModelType modelType) {
    switch (modelType) {
      case AiModelType.geminiNano:
        return Icons.offline_bolt;
      case AiModelType.geminiFlasch:
        return Icons.cloud;
      case AiModelType.traditional:
        return Icons.calculate;
    }
  }

  Color _getStatusColor(ModelStatus status) {
    if (!status.isAvailable) return Colors.red;
    if (status.responseTime > 2000) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText(ModelStatus status) {
    if (!status.isAvailable) return '오류';
    if (status.responseTime > 2000) return '느림';
    return 'OK';
  }
}

/// AI 모델 상태 정보를 담는 클래스
class ModelStatus {
  final bool isAvailable;
  final int responseTime; // 밀리초
  final int accuracy; // 퍼센트
  final String status;

  ModelStatus({
    required this.isAvailable,
    required this.responseTime,
    required this.accuracy,
    required this.status,
  });
}