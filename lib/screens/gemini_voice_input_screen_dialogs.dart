import 'package:flutter/material.dart';

/// 거래 확인 다이얼로그
void showGeminiConfirmDialog({
  required BuildContext context,
  required Map<String, dynamic> data,
  required Future<void> Function(Map<String, dynamic>) onSave,
}) {
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
              await onSave(data);
            },
            child: const Text('✅ 저장'),
          ),
        ],
      );
    },
  );
}

/// OCR 텍스트 입력 다이얼로그
void showGeminiTextInputDialog({
  required BuildContext context,
  required Future<void> Function(String) onSubmit,
}) {
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
            await onSubmit(controller.text);
          },
          child: const Text('분석'),
        ),
      ],
    ),
  );
}
