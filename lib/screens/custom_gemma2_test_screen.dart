import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/custom_gemma2_test_service.dart';
import '../config/ai_security_seal.dart';

/// 🔬 커스텀 파인튜닝 Gemma2 모델 테스트 화면
/// 개발자 모드에서만 접근 가능한 테스트 환경
class CustomGemma2TestScreen extends StatefulWidget {
  const CustomGemma2TestScreen({super.key});

  @override
  State<CustomGemma2TestScreen> createState() => _CustomGemma2TestScreenState();
}

class _CustomGemma2TestScreenState extends State<CustomGemma2TestScreen> {
  final CustomGemma2TestService _testService = CustomGemma2TestService();
  final TextEditingController _queryController = TextEditingController();
  
  bool _isInitializing = false;
  bool _isModelLoaded = false;
  bool _isTesting = false;
  Map<String, dynamic>? _modelInfo;
  final List<Map<String, dynamic>> _testResults = [];

  @override
  void initState() {
    super.initState();
    _checkModelAvailability();
  }

  Future<void> _checkModelAvailability() async {
    setState(() => _isInitializing = true);
    
    try {
      _modelInfo = _testService.getModelInfo();
      
      if (_testService.isAvailable) {
        _isModelLoaded = await _testService.initializeCustomModel();
      }
    } catch (e) {
      _showErrorSnackBar('모델 초기화 실패: $e');
    } finally {
      setState(() => _isInitializing = false);
    }
  }

  void _handleQuerySubmitted(String _) {
    _testQuery();
  }

  @override
  Widget build(BuildContext context) {
    // 개발자 모드가 아니면 접근 차단
    if (!AiSecuritySeal.isDeveloperModeEnabled) {
      return _buildAccessDeniedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔬 커스텀 Gemma2 테스트'),
        backgroundColor: Colors.green.shade100,
        actions: [
          IconButton(
            onPressed: _runBenchmarkTest,
            icon: const Icon(Icons.speed),
            tooltip: '성능 벤치마크',
          ),
          IconButton(
            onPressed: _clearResults,
            icon: const Icon(Icons.clear_all),
            tooltip: '결과 초기화',
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildModelStatusCard(),
                if (_isModelLoaded) _buildQueryInput(),
                if (_isModelLoaded) _buildQuickTestButtons(),
                Expanded(child: _buildTestResults()),
              ],
            ),
    );
  }

  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('접근 제한'),
        backgroundColor: Colors.red.shade100,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                '🚫 개발자 모드 전용',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '이 화면은 커스텀 모델 테스트를 위한 개발자 전용 기능입니다.\n'
                '개발자 모드를 활성화하려면 ai_security_seal.dart를 확인하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelStatusCard() {
    final isAvailable = _modelInfo?['isAvailable'] ?? false;
    final customPath = _modelInfo?['customModelPath'] ?? '';
    final checkpoint = _modelInfo?['checkpoint'] ?? '';

    return Card(
      margin: const EdgeInsets.all(16.0),
      color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.error,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '🧪 파인튜닝 모델 상태',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('모델 경로', customPath),
            _buildStatusRow('체크포인트', checkpoint),
            _buildStatusRow('모델 상태', _isModelLoaded ? '✅ 로드됨' : '⏳ 대기 중'),
            _buildStatusRow('개발자 모드', AiSecuritySeal.isDeveloperModeEnabled ? '활성화' : '비활성화'),
            if (!isAvailable) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '파인튜닝 모델을 찾을 수 없습니다. 경로를 확인하세요.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', 
                       style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildQueryInput() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💬 커스텀 모델 테스트 질문',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                hintText: '재무 관련 질문을 입력하세요... (예: 이번 달 지출 분석해줘)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat),
              ),
              maxLines: 3,
              onSubmitted: _handleQuerySubmitted,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testQuery,
                    icon: _isTesting 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: Text(_isTesting ? '테스트 중...' : '테스트 실행'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _queryController.clear,
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestButtons() {
    final quickTests = [
      {'label': '지출 분석', 'query': '이번 달 지출이 너무 많은 것 같아'},
      {'label': '투자 참고정보', 'query': '투자 포트폴리오 참고정보 알려줘'},
      {'label': '예산 관리', 'query': '예산 관리 어떻게 해야 할까'},
      {'label': '저축 계획', 'query': '저축 계획 세워줘'},
    ];

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ 빠른 테스트',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickTests.map((test) => ElevatedButton(
                onPressed: _isTesting ? null : () {
                  _queryController.text = test['query']!;
                  _testQuery();
                },
                child: Text(test['label']!),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    if (_testResults.isEmpty) {
      return const Center(
        child: Text(
          '아직 테스트 결과가 없습니다.\n위에서 질문을 입력하고 테스트해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _testResults.length,
      itemBuilder: (context, index) {
        final result = _testResults[index];
        return _buildResultCard(result, index);
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result, int index) {
    final isSuccess = result['success'] ?? false;
    final query = result['query'] ?? '';
    final response = result['response'] ?? result['error'] ?? '';
    final responseTime = result['queryTime'] ?? result['responseTime'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isSuccess ? Colors.green.shade100 : Colors.red.shade100,
          child: Text('${index + 1}'),
        ),
        title: Text(
          query,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          isSuccess ? '✅ 성공 • ${responseTime}ms' : '❌ 실패',
          style: TextStyle(
            color: isSuccess ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('응답:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(response),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '모델: ${result['model'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: response));
                        _showSuccessSnackBar('응답이 클립보드에 복사되었습니다');
                      },
                      icon: const Icon(Icons.copy, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isTesting = true);

    try {
      final result = await _testService.testFinancialQuery(query);
      
      setState(() {
        _testResults.insert(0, result);
      });

      if (result['success']) {
        _showSuccessSnackBar('테스트 완료!');
      } else {
        _showErrorSnackBar('테스트 실패: ${result['error']}');
      }
    } catch (e) {
      _showErrorSnackBar('테스트 오류: $e');
    } finally {
      setState(() => _isTesting = false);
      _queryController.clear();
    }
  }

  Future<void> _runBenchmarkTest() async {
    setState(() => _isTesting = true);

    try {
      _showInfoSnackBar('성능 벤치마크 실행 중...');
      
      final benchmarkResult = await _testService.runPerformanceTest();
      
      if (benchmarkResult['success']) {
        final testResults = benchmarkResult['testResults'] as List;
        setState(() {
          _testResults.clear();
          _testResults.addAll(testResults.cast<Map<String, dynamic>>());
        });
        
        _showSuccessSnackBar(
          '벤치마크 완료! 평균 응답시간: ${benchmarkResult['averageTime']}ms'
        );
      }
    } catch (e) {
      _showErrorSnackBar('벤치마크 실패: $e');
    } finally {
      setState(() => _isTesting = false);
    }
  }

  void _clearResults() {
    setState(_testResults.clear);
    _showInfoSnackBar('테스트 결과가 초기화되었습니다');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _testService.cleanup();
    super.dispose();
  }
}