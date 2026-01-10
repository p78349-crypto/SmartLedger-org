import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; - 제거됨 (책스캔앱 연계 전용)
import '../widgets/ingredient_health_analyzer_dialog.dart';
import '../utils/ingredient_health_score_utils.dart';

/// 영수증 재료 건강도 간편 분석 화면
/// 터치 한번으로 빠르게 건강 점수 확인
class QuickHealthAnalyzerScreen extends StatefulWidget {
  const QuickHealthAnalyzerScreen({super.key});

  @override
  State<QuickHealthAnalyzerScreen> createState() =>
      _QuickHealthAnalyzerScreenState();
}

class _QuickHealthAnalyzerScreenState extends State<QuickHealthAnalyzerScreen> {
  // 영수증 예시 (사용자가 입력한 영수증 재료)
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
  // final ImagePicker _imagePicker = ImagePicker(); - 제거됨

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
      _analysis =
          IngredientHealthScoreUtils.analyzeIngredients(_selectedIngredients);
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
      appBar: AppBar(
        title: const Text('영수증 건강도 분석'),
        actions: [
          IconButton(
            icon: const Icon(Icons.scanner),
            tooltip: '책스캔앱 OCR 연계',
            onPressed: _launchBookScanApp,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '재료 추가',
            onPressed: _showCustomAnalyzer,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '도움말',
            onPressed: _showHelp,
          ),
        ],
      ),
      body: Column(
        children: [
          // 요약 카드
          if (_analysis != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getScoreColor(_analysis!.overallScore),
                    _getScoreColor(_analysis!.overallScore)
                        .withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getScoreColor(_analysis!.overallScore)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '영수증 건강 점수',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_analysis!.overallScore}점',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    IngredientHealthScoreUtils.getScoreLabel(
                      _analysis!.overallScore,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _analysis!.summary,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // 통계
          if (_analysis != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '총 재료',
                      '${_selectedIngredients.length}개',
                      Icons.shopping_basket,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '건강 재료',
                      '${(_analysis!.healthyRatio * 100).toInt()}%',
                      Icons.favorite,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '평균',
                      _analysis!.averageScore.toStringAsFixed(1),
                      Icons.analytics,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // 재료 목록
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
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
                          if (_selectedIngredients.length ==
                              _receiptIngredients.length) {
                            _selectedIngredients.clear();
                          } else {
                            _selectedIngredients =
                                List.from(_receiptIngredients);
                          }
                        });
                        _analyzeIngredients();
                      },
                      icon: Icon(
                        _selectedIngredients.length == _receiptIngredients.length
                            ? Icons.deselect
                            : Icons.select_all,
                        size: 16,
                      ),
                      label: Text(
                        _selectedIngredients.length == _receiptIngredients.length
                            ? '전체 해제'
                            : '전체 선택',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._receiptIngredients.map((ingredient) {
                  final isSelected = _selectedIngredients.contains(ingredient);
                  final score =
                      IngredientHealthScoreUtils.getScore(ingredient);
                  final scoreColor = _getScoreColor(score);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isSelected ? 2 : 0,
                    color: isSelected
                        ? null
                        : Colors.grey.shade100,
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => _toggleIngredient(ingredient),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              ingredient,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: scoreColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$score',
                                  style: TextStyle(
                                    color: scoreColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  IngredientHealthScoreUtils.getScoreLabel(
                                          score)
                                      .split(' ')
                                      .first,
                                  style: TextStyle(
                                    color: scoreColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      subtitle: isSelected
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                IngredientHealthScoreUtils.getScoreDescription(
                                    score),
                                style: const TextStyle(fontSize: 11),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCustomAnalyzer,
        icon: const Icon(Icons.add),
        label: const Text('새 재료 분석'),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
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

  /// 책스캔앱 OCR 연계 호출
  void _launchBookScanApp() {
    // TODO: 책스캔앱 URL Scheme 호출
    // bookscan://ocr?source=smartledger&type=receipt&return=healthAnalyzer
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.scanner, color: Colors.blue),
            SizedBox(width: 8),
            Text('책스캔앱 연계'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📱 책스캔 PDF 앱으로 영수증을 촬영하세요.'),
            SizedBox(height: 12),
            Text(
              '🔍 OCR 처리 후 재료 목록을\n자동으로 SmartLedger로 보냅니다.',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            Text(
              '✅ 장점: ML Kit 없이도 정확한 OCR',
              style: TextStyle(fontSize: 11, color: Colors.green),
            ),
            Text(
              '✅ 장점: 앱 용량 최소화 (스토어 업로드 가능)',
              style: TextStyle(fontSize: 11, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showCustomAnalyzer() async {
    final result = await showDialog<IngredientAnalysis>(
      context: context,
      builder: (context) => IngredientHealthAnalyzerDialog(
        initialIngredients: _selectedIngredients,
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '분석 완료: ${result.overallScore}점 (${IngredientHealthScoreUtils.getScoreLabel(result.overallScore)})',
          ),
          backgroundColor: _getScoreColor(result.overallScore),
        ),
      );
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('건강 점수 기준'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem('💚 5점 - 매우 건강', '채소, 버섯, 해조류\n영양소 풍부, 칼로리 낮음'),
              const Divider(),
              _buildHelpItem('💚 4점 - 건강', '생선, 두부, 콩, 감자\n단백질 풍부, 건강한 지방'),
              const Divider(),
              _buildHelpItem('🟡 3점 - 보통', '닭고기, 계란, 쌀, 우유\n적당히 섭취 권장'),
              const Divider(),
              _buildHelpItem('🟠 2점 - 주의', '돼지고기, 소고기, 치즈\n지방 많음, 적게 섭취'),
              const Divider(),
              _buildHelpItem('🔴 1점 - 비건강', '튀김, 가공육, 인스턴트\n가급적 피하세요'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
