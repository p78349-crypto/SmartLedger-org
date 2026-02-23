part of 'nutrition_report_screen.dart';

/// Pairing suggestions based on ingredient combinations.
class _PairingSuggestions extends StatelessWidget {
  const _PairingSuggestions({required this.items});

  final List<NutritionItem> items;

  bool _hasAny(List<String> keys) =>
      keys.any((k) => items.any((e) => e.name.contains(k)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bullets = <String>[];

    final hasChicken = _hasAny(['닭', '달고기']);
    final hasFish = _hasAny(['생선', '연어']);
    final hasMushroom = _hasAny(['표고', '느타리', '팽이', '버섯']);
    final hasCabbage = _hasAny(['양배추']);
    final hasOnion = _hasAny(['양파']);
    final hasCarrot = _hasAny(['당근']);
    final hasBroccoli = _hasAny(['브로콜리']);
    final hasPumpkin = _hasAny(['호박']);
    final hasEggplant = _hasAny(['가지']);
    final hasPotato = _hasAny(['감자']);

    final looksLikeUserSet =
        hasChicken &&
        hasMushroom &&
        (hasCabbage ||
            hasOnion ||
            hasCarrot ||
            hasBroccoli ||
            hasPumpkin ||
            hasEggplant ||
            hasPotato);

    if (looksLikeUserSet) {
      bullets.add(
        '추천 영양식(2개):\n'
        '1) 닭고기·버섯·채소 된장탕\n'
        '재료1: 닭(약 800g), 당근, 양파, 양배추, 가지, 감자, 애호박(또는 호박), '
        '팽이버섯/느타리/표고(버섯류), 잎채소(깻잎/시금치 등·선택), 된장(필수), 고추장(선택·소량). '
        '닭 대신 돼지고기로 바꿔서 끓여도 좋아요. '
        '간은 9회 죽염으로 맞추면 더 깔끔하게 느껴질 수 있어요. '
        '2.3L 정도로 끓이면 1인 기준 3회 식사(총 6회 분량)로 나눠 먹기 좋아요. '
        '식재료는 대략 2만원 전후를 목표로 구성할 수 있습니다(지역/시세에 따라 변동).',
      );

      bullets.add(
        '2) 우유 1잔 + 유기농 카카오 분말 1스푼\n'
        '포만감/균형 보강이 필요하면 오트(또는 통곡)·과일 1개·견과/씨앗 중 1~2가지를 함께 곁들이는 편이 좋아요.',
      );

      bullets.add(
        '하루 3끼 기준 사용자 메모(추정):\n'
        '• 칼로리: 약 1,380 kcal\n'
        '• 단백질: 약 108 g\n'
        '• 탄수화물: 약 84 g\n'
        '• 지방: 약 54 g\n'
        '• 식이섬유: 약 24 g\n'
        '참고: 정확한 수치는 재료/양/곁들이는 밥·면/조리법에 따라 크게 달라질 수 있어요. '
        '죽염도 나트륨은 "종류"보다 "사용량"이 더 중요합니다. '
        '우유+카카오를 하루 1회면 1스푼, 하루 3회면 3스푼 기준으로 생각하면 됩니다.',
      );

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

    if (hasFish && hasMushroom) {
      bullets.add(
        '달고기 + 버섯(표고/느타리/팽이): 감칠맛(우마미)이 올라가서 소금/양념을 줄이기 쉬워요. '
        '또한 단백질(생선) + 식이섬유(버섯) 조합으로 포만감/혈당 안정에 유리합니다.',
      );
    }
    if (hasCabbage && hasOnion) {
      bullets.add('양배추 + 양파: 볶음/샐러드/국으로 만들기 쉬운 기본 조합(섬유질 + 항산화).');
    }
    if (hasCarrot && hasOnion) {
      bullets.add('당근 + 양파: 볶음밥/스프/카레 베이스로 활용하면 채소 섭취량을 쉽게 올릴 수 있어요.');
    }
    if (bullets.isEmpty) {
      bullets.add('버섯류는 대부분의 단백질(생선/닭/두부)과 잘 어울려요.');
      bullets.add('양배추/양파/당근은 "기본 채소 베이스"로 여러 요리에 재사용하기 좋아요.');
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

/// Cola 2L sugar cube estimation card.
class _ColaSugarCard extends StatelessWidget {
  const _ColaSugarCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final est = NutritionReportUtils.estimateSugarCubesForCola2L();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2L 기준 당류를 라벨 확인 없이 추정하면, 대략 '
          '${est.sugarMinG}~${est.sugarMaxG}g 수준인 경우가 많습니다.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '설탕 큐브 1개를 3~4g으로 보면 약 '
          '${est.minCubes}~${est.maxCubes}개 범위로 표현할 수 있어요.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '정확히는 제품 라벨의 "당류(g)"를 보고 계산하는 게 가장 안전합니다.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
