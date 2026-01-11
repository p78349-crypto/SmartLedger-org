import 'package:flutter/material.dart';
import '../utils/ingredient_health_score_utils.dart';

/// 영수증 재료 건강도 분석 다이얼로그
/// 간편하게 재료 입력하면 건강 점수 즉시 표시
class IngredientHealthAnalyzerDialog extends StatefulWidget {
  final List<String>? initialIngredients;

  const IngredientHealthAnalyzerDialog({super.key, this.initialIngredients});

  @override
  State<IngredientHealthAnalyzerDialog> createState() =>
      _IngredientHealthAnalyzerDialogState();
}

class _IngredientHealthAnalyzerDialogState
    extends State<IngredientHealthAnalyzerDialog> {
  final TextEditingController _controller = TextEditingController();
  List<String> _ingredients = [];
  IngredientAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    if (widget.initialIngredients != null) {
      _ingredients = List.from(widget.initialIngredients!);
      _analyzeIngredients();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyzeIngredients() {
    if (_ingredients.isEmpty) {
      setState(() => _analysis = null);
      return;
    }

    setState(() {
      _analysis = IngredientHealthScoreUtils.analyzeIngredients(_ingredients);
    });
  }

  void _addIngredient() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _ingredients.add(text);
      _controller.clear();
    });
    _analyzeIngredients();
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
    _analyzeIngredients();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.green),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '재료 건강도 분석',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '영수증 재료를 입력하세요',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 재료 입력
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: '예: 양배추, 브로콜리, 닭고기',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (_) => _addIngredient(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addIngredient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('추가'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 재료 목록
                    if (_ingredients.isNotEmpty) ...[
                      const Text(
                        '재료 목록',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _ingredients.asMap().entries.map((entry) {
                          final index = entry.key;
                          final ingredient = entry.value;
                          final score = IngredientHealthScoreUtils.getScore(
                            ingredient,
                          );

                          return Chip(
                            label: Text(ingredient),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeIngredient(index),
                            backgroundColor: _getScoreColor(
                              score,
                            ).withValues(alpha: 0.2),
                            side: BorderSide(color: _getScoreColor(score)),
                            avatar: CircleAvatar(
                              backgroundColor: _getScoreColor(score),
                              child: Text(
                                '$score',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 분석 결과
                    if (_analysis != null) ...[
                      const Divider(),
                      const SizedBox(height: 16),

                      // 전체 건강 점수
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getScoreColor(_analysis!.overallScore),
                              _getScoreColor(
                                _analysis!.overallScore,
                              ).withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '전체 건강 점수',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_analysis!.overallScore}점',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              IngredientHealthScoreUtils.getScoreLabel(
                                _analysis!.overallScore,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              IngredientHealthScoreUtils.getScoreDescription(
                                _analysis!.overallScore,
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 요약 메시지
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _analysis!.summary,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 건강도 분포
                      const Text(
                        '건강도 분포',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatBar(
                        '💚 매우 건강',
                        _analysis!.veryHealthyCount,
                        Colors.green,
                      ),
                      _buildStatBar(
                        '💚 건강',
                        _analysis!.healthyCount,
                        Colors.lightGreen,
                      ),
                      _buildStatBar(
                        '🟡 보통',
                        _analysis!.normalCount,
                        Colors.orange,
                      ),
                      _buildStatBar(
                        '🟠 주의',
                        _analysis!.cautionCount,
                        Colors.deepOrange,
                      ),
                      _buildStatBar(
                        '🔴 비건강',
                        _analysis!.unhealthyCount,
                        Colors.red,
                      ),
                      const SizedBox(height: 16),

                      // 통계
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            '평균 점수',
                            _analysis!.averageScore.toStringAsFixed(1),
                            Colors.blue,
                          ),
                          _buildStatCard(
                            '건강 재료',
                            '${(_analysis!.healthyRatio * 100).toInt()}%',
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 버튼
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _ingredients.clear();
                          _analysis = null;
                        });
                      },
                      child: const Text('초기화'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _analysis != null
                          ? () => Navigator.pop(context, _analysis)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('완료'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar(String label, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();

    final total = _ingredients.length;
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

  Widget _buildStatCard(String label, String value, Color color) {
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

  Color _getScoreColor(int score) {
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
}
