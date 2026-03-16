import 'package:flutter/material.dart';

class InvestmentRecommendationDialog extends StatelessWidget {
  final double emergencyFundAmount;
  final double monthlyAverageSavings;
  final VoidCallback onInvest;
  final VoidCallback onLater;

  const InvestmentRecommendationDialog({
    super.key,
    required this.emergencyFundAmount,
    required this.monthlyAverageSavings,
    required this.onInvest,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remainingAmount = 120000 - emergencyFundAmount;
    final monthsToComplete = (remainingAmount / monthlyAverageSavings).ceil();

    return AlertDialog(
      title: const Text('🌟 예금 분석 참고정보'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '축하합니다!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Emergency fund amount is private;
                  // indicate without showing the amount
                  _buildInfoRow('현재 비상금:', '비공개', scheme.primary),
                  const SizedBox(height: 8),
                  _buildInfoRow('필요한 총액:', '₩120,000', scheme.primary),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    '부족한 금액:',
                    '₩${remainingAmount.toStringAsFixed(0)}',
                    scheme.tertiary,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Builder(
                      builder: (ctx) {
                        final monthlyAvgStr = monthlyAverageSavings
                            .toStringAsFixed(0);
                        final monthsStr =
                            '$monthsToComplete개월 내 '
                            '목표 달성 가능!';
                        final monthlyCompletionText =
                            '월평균 ₩$monthlyAvgStr 예금 기준, $monthsStr';
                        return Text(
                          monthlyCompletionText,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('예금 분석 요약', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(
              '비상금 준비 현황과 월 저축 흐름을 기반으로 예금 계획을 점검할 수 있습니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 분석 포인트',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 비상금: 안전하게 유지 (120,000원)\n'
                    '• 추가 예금: 여유 자금 범위 내 계획 점검\n'
                    '• 목표: $monthsToComplete개월 후 재평가',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onLater();
          },
          child: const Text('나중에'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onInvest();
          },
          child: const Text('분석 확인'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
