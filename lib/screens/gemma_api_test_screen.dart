import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/gemma_api_service.dart';
import '../services/receipt_processing_service.dart';

/// Gemma API 테스트 화면
class GemmaApiTestScreen extends StatefulWidget {
  const GemmaApiTestScreen({super.key});

  @override
  State<GemmaApiTestScreen> createState() => _GemmaApiTestScreenState();
}

class _GemmaApiTestScreenState extends State<GemmaApiTestScreen> {
  final _gemmaService = GemmaApiService();
  final _receiptService = ReceiptProcessingService();
  final _textController = TextEditingController();

  bool _isProcessing = false;
  bool? _serverHealthy;
  ReceiptProcessingResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _checkServerHealth();
    _loadSampleReceipt();
  }

  Future<void> _checkServerHealth() async {
    setState(() => _isProcessing = true);
    final healthy = await _gemmaService.checkHealth();
    setState(() {
      _serverHealthy = healthy;
      _isProcessing = false;
    });
  }

  void _loadSampleReceipt() {
    _textController.text = '''이마트 서초점
2026-01-27 14:32

바나나        2,980원 x 2 = 5,960원
우유 1L      3,200원 x 1 = 3,200원
계란 30구    6,500원 x 1 = 6,500원

합계: 15,660원
카드결제
''';
  }

  Future<void> _processReceipt({bool forceGemini = false}) async {
    if (_textController.text.trim().isEmpty) {
      _showSnackBar('영수증 텍스트를 입력해주세요.', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await _receiptService.processReceipt(
        ocrText: _textController.text,
        forceGemini: forceGemini,
      );

      setState(() {
        _lastResult = result;
        _isProcessing = false;
      });

      if (result.success) {
        _showSnackBar('✅ 추출 성공! (${result.model})', isError: false);
      } else {
        _showSnackBar('❌ 추출 실패: ${result.error}', isError: true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar('오류: $e', isError: true);
    }
  }

  Future<void> _testSample() async {
    setState(() => _isProcessing = true);
    final result = await _gemmaService.testSampleReceipt();
    setState(() => _isProcessing = false);

    if (result != null) {
      _showSnackBar('샘플 테스트 성공!', isError: false);
      // 결과 다이얼로그 표시
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('샘플 테스트 결과'),
            content: SingleChildScrollView(
              child: Text(result.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
      }
    } else {
      _showSnackBar('샘플 테스트 실패', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemma API 테스트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isProcessing ? null : _checkServerHealth,
            tooltip: '서버 상태 확인',
          ),
        ],
      ),
      body: Column(
        children: [
          // 서버 상태
          _buildServerStatus(),

          // 입력 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '영수증 텍스트',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'OCR 텍스트를 입력하거나 샘플 로드...',
                      ),
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 버튼
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _loadSampleReceipt,
                        icon: const Icon(Icons.note_add),
                        label: const Text('샘플 로드'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : _processReceipt,
                        icon: const Icon(Icons.smart_toy),
                        label: const Text('Gemma 추출'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _processReceipt(forceGemini: true),
                        icon: const Icon(Icons.cloud),
                        label: const Text('Gemini 추출'),
                      ),
                      if (_serverHealthy == true)
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _testSample,
                          icon: const Icon(Icons.science),
                          label: const Text('서버 샘플 테스트'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  // 결과 영역
                  const Text(
                    '추출 결과',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 3,
                    child: _buildResultView(),
                  ),
                ],
              ),
            ),
          ),

          // 로딩 인디케이터
          if (_isProcessing)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildServerStatus() {
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    if (_serverHealthy == null) {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
      statusText = '서버 상태 확인 중...';
    } else if (_serverHealthy == true) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Gemma 서버 실행 중 ✅';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber;
      statusText = 'Gemma 서버 미실행 (Gemini 폴백 가능)';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: statusColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_gemmaService.lastHealthCheck != null)
            Text(
              '마지막 체크: ${_formatTime(_gemmaService.lastHealthCheck!)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    if (_lastResult == null) {
      return const Center(
        child: Text(
          '영수증을 처리하면 결과가 여기에 표시됩니다.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (!_lastResult!.success) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '추출 실패',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _lastResult!.error ?? '알 수 없는 오류',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final data = _lastResult!.data!;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(8),
          color: Colors.green.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '추출 성공 (${_lastResult!.model})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: data.toJson().toString()));
                    _showSnackBar('결과 복사됨', isError: false);
                  },
                  tooltip: '결과 복사',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 상점명
            if (data.storeName != null) ...[
              _buildInfoRow('🏪 상점', data.storeName!),
              const SizedBox(height: 4),
            ],

            // 날짜
            if (data.date != null) ...[
              _buildInfoRow('📅 날짜', _formatDate(data.date!)),
              const SizedBox(height: 4),
            ],

            // 총액
            if (data.totalAmount != null) ...[
              _buildInfoRow('💰 총액', '${_formatMoney(data.totalAmount!)}원'),
              const SizedBox(height: 8),
            ],

            // 항목 목록
            if (data.items.isNotEmpty) ...[
              const Text(
                '📦 항목:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...data.items.map(_buildItemCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(ReceiptItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatMoney(item.unitPrice)}원 x ${item.quantity}개',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Text(
                  '${_formatMoney(item.totalPrice)}원',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
