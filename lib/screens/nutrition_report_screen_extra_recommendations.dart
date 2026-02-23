part of 'nutrition_report_screen.dart';

/// Extra ingredient recommendations with "show all" bottom sheet.
class _ExtraRecommendations extends StatelessWidget {
  const _ExtraRecommendations({this.onAdd});

  final ValueChanged<String>? onAdd;

  void _showAllIngredients(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final all = NutritionFoodKnowledge.allEntries;
          return Column(
            children: [
              AppBar(
                title: const Text('모든 식재료'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: all.length,
                  itemBuilder: (context, index) {
                    final entry = all[index];
                    return ListTile(
                      title: Text(entry.primaryName),
                      subtitle: Text(entry.keywords.take(3).join(', ')),
                      onTap: () {
                        onAdd?.call(entry.primaryName);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recommendations = [
      {'name': '계란', 'desc': '저렴한 완전단백질 + 요리에 넣기 쉬움'},
      {'name': '두부', 'desc': '가성비 단백질/칼슘(제품별 차이) + 생선/버섯과도 잘 어울림'},
      {'name': '김/미역', 'desc': '미네랄 보강 + 국/반찬으로 간편'},
      {'name': '마늘/생강', 'desc': '향·풍미를 올려 염분을 줄이는 데 도움'},
      {'name': '현미/잡곡(또는 귀리)', 'desc': '식이섬유를 늘려 포만감 유지에 도움'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in recommendations)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  width: 0.5,
                ),
              ),
            ),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '${item['name']}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: item['desc']),
                ],
              ),
            ),
          ),
        if (onAdd != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAllIngredients(context),
              icon: const Icon(Icons.list),
              label: const Text('모든 재료 보기 / 추가'),
            ),
          ),
        ],
      ],
    );
  }
}
