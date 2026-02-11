// ignore_for_file: invalid_use_of_protected_member
part of 'gemini_voice_input_screen.dart';

/// Dialogs and UI components
extension GeminiVoiceInputUI on _GeminiVoiceInputScreenState {
  /// OCR 텍스트 입력
  void _showTextInputDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('OCR 텍스트 입력'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '영수증 OCR 텍스트를 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _processTextInput(controller.text);
            },
            child: const Text('분석'),
          ),
        ],
      ),
    );
  }

  /// 확인 다이얼로그
  void _showConfirmDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) {
        final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.8;
        final confidenceColor = confidence > 0.9
            ? Colors.green
            : confidence > 0.7
                ? Colors.orange
                : Colors.red;

        return AlertDialog(
          title: const Text('거래 기록 확인'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 신뢰도 표시
                Row(
                  children: [
                    const Text('신뢰도: '),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: confidenceColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 상점명
                Text(
                  '상점: ${data['store'] ?? '?'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // 날짜
                Text('날짜: ${data['date'] ?? '오늘'}'),
                const SizedBox(height: 12),

                // 항목 목록
                const Text(
                  '항목:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...(data['items'] as List?)?.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8),
                        child: Text(
                          '• ${item['name']}: ${item['qty']}개 × ${item['unit_price']}원 = ${item['total']}원',
                        ),
                      ),
                    ) ??
                    [const Text('항목 없음')],

                const SizedBox(height: 12),

                // 합계
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '합계:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${data['total']}원',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('수정'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _saveTransaction(data);
              },
              child: const Text('✅ 저장'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '파싱 결과',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        Text('상점: ${_parsedData!['store'] ?? '?'}'),
        Text('날짜: ${_parsedData!['date'] ?? '오늘'}'),
        const SizedBox(height: 12),
        const Text('항목:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...(_parsedData!['items'] as List?)?.map(
              (item) => Text(
                '  • ${item['name']}: ${item['qty']}개 × ${item['unit_price']}원',
              ),
            ) ??
            [],
        const SizedBox(height: 12),
        Text(
          '합계: ${_parsedData!['total']}원',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}
