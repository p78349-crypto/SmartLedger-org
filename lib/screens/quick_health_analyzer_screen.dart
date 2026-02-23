import 'package:flutter/material.dart';
import '../utils/ingredient_health_score_utils.dart';
import 'quick_health_analyzer_screen_widgets.dart';

/// 영수증 재료 건강도 간편 분석 화면
/// 터치 한번으로 빠르게 건강 점수 확인
class QuickHealthAnalyzerScreen extends StatefulWidget {
  const QuickHealthAnalyzerScreen({super.key});

  @override
  State<QuickHealthAnalyzerScreen> createState() =>
      _QuickHealthAnalyzerScreenState();
}

class _QuickHealthAnalyzerScreenState
    extends State<QuickHealthAnalyzerScreen> {
  final List<String> _receiptIngredients = [
    '닭튀김당',
    '느타리버섯',
    '표고버섯',
    '호박',
    '팽이버섯',
    '양배추',
    '당근',
    '가지',
    '양파',
    '마늘',
    '고추장',
    '된장',
    '브로콜리',
    '감자',
    '쌀',
    '우유',
    '요구르트',
  ];

  List<String> _selectedIngredients = [];
  IngredientAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    // 모든 재료 기본 선택
    _selectedIngredients = List.from(_receiptIngredients);
    _analyzeIngredients();
  }

  void _analyzeIngredients() {
    if (_selectedIngredients.isEmpty) {
      setState(() => _analysis = null);
      return;
    }

    setState(() {
      _analysis = IngredientHealthScoreUtils.analyzeIngredients(
        _selectedIngredients,
      );
    });
  }

  void _toggleIngredient(String ingredient) {
    setState(() {
      if (_selectedIngredients.contains(ingredient)) {
        _selectedIngredients.remove(ingredient);
      } else {
        _selectedIngredients.add(ingredient);
      }
    });
    _analyzeIngredients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_analysis != null)
            HealthScoreCard(
              score: _analysis!.overallScore,
              summary: _analysis!.summary,
            ),
          if (_analysis != null) _buildStats(),
          const SizedBox(height: 16),
          _buildIngredientList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCustomAnalyzer(
          context,
          _selectedIngredients,
        ),
        icon: const Icon(Icons.add),
        label: const Text('새 재료 분석'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('영수증 건강도 분석'),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) {
            if (v == 'add') {
              showCustomAnalyzer(
                context,
                _selectedIngredients,
              );
            } else if (v == 'help') {
              showHealthHelp(context);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'add',
              child: Row(
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text('재료 추가'),
                ],
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Text('도움말'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: HealthStatCard(
              label: '총 재료',
              value:
                  '${_selectedIngredients.length}개',
              icon: Icons.shopping_basket,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HealthStatCard(
              label: '건강 재료',
              value:
                  '${(_analysis!.healthyRatio * 100).toInt()}%',
              icon: Icons.favorite,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HealthStatCard(
              label: '평균',
              value: _analysis!.averageScore
                  .toStringAsFixed(1),
              icon: Icons.analytics,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientList() {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildListHeader(),
          const SizedBox(height: 12),
          ..._receiptIngredients.map(
            (ing) => IngredientTile(
              ingredient: ing,
              isSelected: _selectedIngredients
                  .contains(ing),
              onToggle: _toggleIngredient,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    final allSelected =
        _selectedIngredients.length ==
            _receiptIngredients.length;
    return Row(
      children: [
        const Text(
          '재료 선택',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () {
            setState(() {
              if (allSelected) {
                _selectedIngredients.clear();
              } else {
                _selectedIngredients =
                    List.from(_receiptIngredients);
              }
            });
            _analyzeIngredients();
          },
          icon: Icon(
            allSelected
                ? Icons.deselect
                : Icons.select_all,
            size: 16,
          ),
          label: Text(
            allSelected ? '전체 해제' : '전체 선택',
          ),
        ),
      ],
    );
  }

}
