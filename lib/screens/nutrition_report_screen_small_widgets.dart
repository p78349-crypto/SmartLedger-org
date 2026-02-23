part of 'nutrition_report_screen.dart';

/// Reusable info card wrapper.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// Ingredient row displaying name and price range.
class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.item, this.onTap});

  final NutritionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormats.currency;

    final minLabel = currency.format(item.priceMinWon);
    final maxLabel = currency.format(item.priceMaxWon);
    final priceLabel = item.priceMinWon == item.priceMaxWon
        ? '$minLabel원'
        : '$minLabel~$maxLabel원';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              priceLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple nutrition highlights bullets.
class _NutritionHighlights extends StatelessWidget {
  const _NutritionHighlights({required this.items});

  final List<NutritionItem> items;

  bool _has(String key) {
    return items.any((e) => e.name.contains(key));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bullets = <String>[];

    if (_has('달고기') || _has('생선')) {
      bullets.add('달고기/생선: 단백질 중심 + (생선 종류에 따라) 불포화지방산 섭취에 도움.');
    }
    if (_has('표고') || _has('느타리') || _has('팽이') || _has('버섯')) {
      bullets.add('버섯류: 식이섬유·베타글루칸 → 포만감/장 건강/면역 기능에 도움 될 수 있음.');
    }
    if (_has('당근')) {
      bullets.add('당근: 베타카로틴(비타민A 전구체) → 눈/피부 건강에 도움.');
    }
    if (_has('양배추')) {
      bullets.add('양배추: 식이섬유 + 비타민C·K → 장 건강/항산화에 도움.');
    }
    if (_has('양파')) {
      bullets.add('양파: 폴리페놀(퀘르세틴) → 항산화/혈관 건강에 도움 될 수 있음.');
    }
    if (_has('가지')) {
      bullets.add('가지: 식이섬유 + 폴리페놀(색소) → 포만감/항산화에 도움.');
    }
    if (_has('호박')) {
      bullets.add('호박: 칼륨·식이섬유 중심 → 붓기/나트륨 균형에 도움 될 수 있음.');
    }

    if (bullets.isEmpty) {
      return Text(
        '메모에 식재료 이름을 포함하면 포인트가 더 정확해져요.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('• $b', style: theme.textTheme.bodyMedium),
          ),
      ],
    );
  }
}

/// Simple dessert suggestions.
class _DessertSuggestions extends StatelessWidget {
  const _DessertSuggestions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final desserts = [
      {
        'name': '⭐ 카카오(100% 분말) + 아몬드(100% 분말)',
        'desc': '최고 추천! 포만감 최강 + 영양 완벽(단백질3g, 지방6g, 식이섬유2.1g)',
      },
      {
        'name': '카카오(100% 분말) + 우유',
        'desc': '단백질/칼슘 보충 + 초콜릿의 폴리페놀, 비용 효율적',
      },
      {
        'name': '카카오(100% 분말) + 요구르트',
        'desc': '유산균 + 항산화 성분 조합, 저비용 고영양',
      },
      {
        'name': '아몬드(100% 분말) + 요구르트',
        'desc': '건강한 지방/식이섬유 + 유산균, 추천 조합',
      },
      {'name': '냉동 바나나', 'desc': '칼륨 풍부, 장기 보관 가능 (선택적)'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '식사 후 조금 부족한 영양을 보충하는 간단한 조합',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in desserts)
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
      ],
    );
  }
}
