import 'package:flutter/material.dart';
import '../utils/ingredient_health_score_utils.dart';
import 'ingredient_health_analyzer_result.dart';

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
                            backgroundColor: getDialogScoreColor(
                              score,
                            ).withValues(alpha: 0.2),
                            side: BorderSide(
                              color: getDialogScoreColor(score),
                            ),
                            avatar: CircleAvatar(
                              backgroundColor:
                                  getDialogScoreColor(score),
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
                    if (_analysis != null)
                      AnalysisResultSection(
                        analysis: _analysis!,
                        ingredientCount: _ingredients.length,
                      ),
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

}
