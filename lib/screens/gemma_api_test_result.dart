import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/gemma_api_service.dart';
import '../services/receipt_processing_service.dart';

/// Gemma API 테스트 결과 표시 위젯
class GemmaTestResultView extends StatelessWidget {
  const GemmaTestResultView({
    super.key,
    required this.result,
    required this.onMessage,
  });

  final ReceiptProcessingResult? result;
  final void Function(String msg, {required bool isError}) onMessage;

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const Center(
        child: Text(
          '영수증을 처리하면 결과가 여기에 표시됩니다.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (!result!.success) {
      return _ErrorView(error: result!.error);
    }

    return _SuccessView(result: result!, onMessage: onMessage);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
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
            error ?? '알 수 없는 오류',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.result, required this.onMessage});

  final ReceiptProcessingResult result;
  final void Function(String msg, {required bool isError}) onMessage;

  @override
  Widget build(BuildContext context) {
    final data = result.data!;
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
            _buildHeader(data),
            const Divider(),
            const SizedBox(height: 8),
            if (data.storeName != null) ...[
              _infoRow('🏪 상점', data.storeName!),
              const SizedBox(height: 4),
            ],
            if (data.date != null) ...[
              _infoRow('📅 날짜', _formatDate(data.date!)),
              const SizedBox(height: 4),
            ],
            if (data.totalAmount != null) ...[
              _infoRow('💰 총액', '${_formatMoney(data.totalAmount!)}원'),
              const SizedBox(height: 8),
            ],
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

  Widget _buildHeader(ReceiptExtractionResult data) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '추출 성공 (${result.model})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: data.toJson().toString()));
            onMessage('결과 복사됨', isError: false);
          },
          tooltip: '결과 복사',
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatMoney(item.unitPrice)}원'
                  ' x ${item.quantity}개',
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

  static Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }

  static String _formatMoney(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}'
        '-${date.month.toString().padLeft(2, '0')}'
        '-${date.day.toString().padLeft(2, '0')}';
  }
}
