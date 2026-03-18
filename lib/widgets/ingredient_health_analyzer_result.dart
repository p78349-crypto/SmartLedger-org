import 'package:flutter/material.dart';
import '../utils/ingredient_health_score_utils.dart';

/// 건강도 점수 색상 반환 (다이얼로그용)
Color getDialogScoreColor(int score) {
  switch (score) {
    case 5:
      return Colors.green;
    case 4:
      return Colors.lightGreen;
    case 3:
      return Colors.orange;
    case 2:
      return Colors.deepOrange;
    case 1:
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/// 분석 결과 표시 위젯
class AnalysisResultSection extends StatelessWidget {
  final IngredientAnalysis analysis;
  final int ingredientCount;

  const AnalysisResultSection({
    super.key,
    required this.analysis,
    required this.ingredientCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = getDialogScoreColor(analysis.overallScore);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        _OverallScoreCard(score: analysis.overallScore, color: color),
        const SizedBox(height: 16),
        _SummaryBox(summary: analysis.summary),
        const SizedBox(height: 16),
        _DistributionBars(analysis: analysis, total: ingredientCount),
        const SizedBox(height: 16),
        _StatsRow(analysis: analysis),
      ],
    );
  }
}

class _OverallScoreCard extends StatelessWidget {
  final int score;
  final Color color;

  const _OverallScoreCard({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            '전체 건강 점수',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '$score점',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            IngredientHealthScoreUtils.getScoreLabel(score),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            IngredientHealthScoreUtils.getScoreDescription(score),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String summary;
  const _SummaryBox({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(summary, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _DistributionBars extends StatelessWidget {
  final IngredientAnalysis analysis;
  final int total;

  const _DistributionBars({required this.analysis, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '건강도 분포',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _bar('💚 매우 건강', analysis.veryHealthyCount, Colors.green),
        _bar('💚 건강', analysis.healthyCount, Colors.lightGreen),
        _bar('🟡 보통', analysis.normalCount, Colors.orange),
        _bar('🟠 주의', analysis.cautionCount, Colors.deepOrange),
        _bar('🔴 비건강', analysis.unhealthyCount, Colors.red),
      ],
    );
  }

  Widget _bar(String label, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    final ratio = count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 12)),
              ),
              Text(
                '$count개',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final IngredientAnalysis analysis;
  const _StatsRow({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _miniCard(
          '평균 점수',
          analysis.averageScore.toStringAsFixed(1),
          Colors.blue,
        ),
        _miniCard(
          '건강 재료',
          '${(analysis.healthyRatio * 100).toInt()}%',
          Colors.green,
        ),
      ],
    );
  }

  Widget _miniCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
