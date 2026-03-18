// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../utils/ingredient_health_score_utils.dart';
import '../widgets/ingredient_health_analyzer_dialog.dart';

export 'quick_health_analyzer_screen_tiles.dart';

/// 건강도 점수 색상 반환
Color getHealthScoreColor(int score) {
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

/// 건강 점수 요약 카드
class HealthScoreCard extends StatelessWidget {
  final int score;
  final String summary;

  const HealthScoreCard({
    super.key,
    required this.score,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final color = getHealthScoreColor(score);
    return Container(
      // 세로 크기: 화면 높이의 10%로 지정하여 이전보다 절반 가량 축소
      height: MediaQuery.of(context).size.height * 0.10,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          // 높이에 비례한 폰트/아이콘 크기
          final iconSize = (h * 0.22).clamp(12.0, 40.0);
          final titleSize = (h * 0.12).clamp(10.0, 20.0);
          final scoreSize = (h * 0.45).clamp(18.0, 56.0);
          final labelSize = (h * 0.13).clamp(10.0, 22.0);
          final summarySize = (h * 0.10).clamp(10.0, 16.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, color: Colors.white, size: iconSize),
                  SizedBox(height: h * 0.06),
                  AutoSizeText(
                    '영수증 건강 점수',
                    style: TextStyle(color: Colors.white, fontSize: titleSize),
                    maxLines: 1,
                    minFontSize: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: h * 0.06),
                  AutoSizeText(
                    IngredientHealthScoreUtils.getScoreLabel(score),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: labelSize,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    minFontSize: 8,
                  ),
                  SizedBox(height: h * 0.06),
                  Flexible(
                    child: AutoSizeText(
                      summary,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      minFontSize: 8,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: summarySize,
                      ),
                    ),
                  ),
                ],
              ),
              // 오른쪽 상자에 점수 표시
              Positioned(
                right: 16,
                top: h * 0.28,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: AutoSizeText(
                    '$score점',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: scoreSize,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    minFontSize: 12,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 통계 카드 위젯
class HealthStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const HealthStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

/// 커스텀 분석 다이얼로그 표시
Future<void> showCustomAnalyzer(
  BuildContext context,
  List<String> selectedIngredients,
) async {
  final result = await showDialog<IngredientAnalysis>(
    context: context,
    builder: (ctx) =>
        IngredientHealthAnalyzerDialog(initialIngredients: selectedIngredients),
  );

  if (result != null && context.mounted) {
    final scoreLabel = IngredientHealthScoreUtils.getScoreLabel(
      result.overallScore,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '분석 완료: '
          '${result.overallScore}점 ($scoreLabel)',
        ),
        backgroundColor: getHealthScoreColor(result.overallScore),
      ),
    );
  }
}

/// 도움말 다이얼로그 표시
void showHealthHelp(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.help_outline, color: Colors.blue),
          SizedBox(width: 8),
          Text('건강 점수 기준'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _HelpItem(
              title: '💚 5점 - 매우 건강',
              description:
                  '채소, 버섯, 해조류\n'
                  '영양소 풍부, 칼로리 낮음',
            ),
            Divider(),
            _HelpItem(
              title: '💚 4점 - 건강',
              description:
                  '생선, 두부, 콩, 감자\n'
                  '단백질 풍부, 건강한 지방',
            ),
            Divider(),
            _HelpItem(
              title: '🟡 3점 - 보통',
              description:
                  '닭고기, 계란, 쌀, 우유\n'
                  '적당히 섭취 권장',
            ),
            Divider(),
            _HelpItem(
              title: '🟠 2점 - 주의',
              description:
                  '돼지고기, 소고기, 치즈\n'
                  '지방 많음, 적게 섭취',
            ),
            Divider(),
            _HelpItem(
              title: '🔴 1점 - 비건강',
              description:
                  '튀김, 가공육, 인스턴트\n'
                  '가급적 피하세요',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

class _HelpItem extends StatelessWidget {
  final String title;
  final String description;

  const _HelpItem({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
