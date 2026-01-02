import 'package:flutter/material.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/nutrition_food_knowledge.dart';
import 'package:smart_ledger/utils/nutrition_report_utils.dart';

class NutritionReportScreen extends StatefulWidget {
  const NutritionReportScreen({
    super.key,
    required this.rawText,
    this.onAddIngredient,
  });

  final String rawText;
  final ValueChanged<String>? onAddIngredient;

  @override
  State<NutritionReportScreen> createState() => _NutritionReportScreenState();
}

class _NutritionReportScreenState extends State<NutritionReportScreen> {
  final TextEditingController _foodSearchController = TextEditingController();
  String _foodQuery = '';
  List<String> _searchHistory = [];

  late final NutritionReport _report;

  @override
  void initState() {
    super.initState();
    _report = NutritionReportUtils.buildFromRawText(widget.rawText);

    if (_report.items.isNotEmpty) {
      final seed = _report.items.first.name;
      _foodQuery = seed;
      _foodSearchController.text = seed;
      _foodSearchController.selection = TextSelection.fromPosition(
        TextPosition(offset: seed.length),
      );
    } else {
      _loadLastQuery();
    }
    _loadHistory();
  }

  Future<void> _loadLastQuery() async {
    final last = await UserPrefService.getLastRecipeSearchQuery();
    if (last.isNotEmpty && mounted) {
      setState(() {
        _foodQuery = last;
        _foodSearchController.text = last;
      });
    }
  }

  Future<void> _loadHistory() async {
    final history = await UserPrefService.getRecipeSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    await UserPrefService.addToRecipeSearchHistory(query);
    await _loadHistory();
  }

  void _resetSearchForm() {
    setState(() {
      _foodQuery = '';
      _foodSearchController.clear();
    });
    UserPrefService.setLastRecipeSearchQuery('');
  }

  @override
  void dispose() {
    // Save current query as last query on exit
    UserPrefService.setLastRecipeSearchQuery(_foodQuery);
    _foodSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = _report;
    final currency = NumberFormats.currency;

    final totalLabel = report.items.isEmpty
        ? '합계: -'
        : (report.totalMinWon == report.totalMaxWon
            ? '합계: ${currency.format(report.totalMinWon)}원'
            : '합계: ${currency.format(report.totalMinWon)}~${currency.format(report.totalMaxWon)}원');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '레시피/식재료 검색',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _foodSearchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '식재료 검색 (예: 닭고기)',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _foodQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: '검색 폼 초기화',
                        onPressed: _resetSearchForm,
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  _foodQuery = value;
                });
                UserPrefService.setLastRecipeSearchQuery(value);
              },
              onSubmitted: _saveSearch,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_searchHistory.isNotEmpty && _foodQuery.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InfoCard(
                      title: '최근 검색어',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final historyItem in _searchHistory)
                            ActionChip(
                              label: Text(historyItem),
                              onPressed: () {
                                setState(() {
                                  _foodQuery = historyItem;
                                  _foodSearchController.text = historyItem;
                                });
                                _saveSearch(historyItem); // Refresh history order
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                _InfoCard(
                  title: '검색 결과',
                  child: _FoodSearchResult(
                    query: _foodQuery,
                    onAdd: widget.onAddIngredient,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: '요약',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '품목 ${report.items.length}개 · $totalLabel',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '분석은 메모/내역 텍스트에서 “식재료 + 금액(원)” 패턴을 읽어 추정합니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search field moved to top (fixed)
          // _InfoCard(title: '식재료 검색', ...),

          _InfoCard(
            title: '구매 식재료',
            child: report.items.isEmpty
                ? Text(
                    '메모에 예시처럼 적으면 자동 분석이 됩니다.\n'
                    '예) 달고기(1마리 6500-7500원) 당근 3000원 양배추 1000원 팽이 1개 350원',
                    style: theme.textTheme.bodyMedium,
                  )
                : Column(
                    children: [
                      for (final item in report.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _IngredientRow(
                            item: item,
                            onTap: () {
                              setState(() {
                                _foodQuery = item.name;
                                _foodSearchController.text = item.name;
                                _foodSearchController.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(offset: item.name.length),
                                );
                              });
                            },
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),

          _InfoCard(
            title: '영양 포인트(간단)',
            child: _NutritionHighlights(items: report.items),
          ),
          const SizedBox(height: 12),

          _InfoCard(
            title: '같이 요리하면 좋은 조합',
            child: _PairingSuggestions(items: report.items),
          ),
          const SizedBox(height: 12),

          if (report.hasCola2LHint) ...[
            const _InfoCard(
              title: '콜라 2L 설탕 큐브 환산',
              child: _ColaSugarCard(),
            ),
            const SizedBox(height: 12),
          ],

          _InfoCard(
            title: '추가하면 좋은 재료(저렴/실용)',
            child: _ExtraRecommendations(onAdd: widget.onAddIngredient),
          ),
          const SizedBox(height: 12),

          _InfoCard(
            title: '영양학적 최종 판단 요약',
            child: _FinalJudgementSummary(items: report.items),
          ),
          const SizedBox(height: 12),

          Text(
            '참고: 본 화면은 일반적인 식단/영양 정보이며, 특정 질환의 진단/치료 목적이 아닙니다. '
            '알레르기·질환·복용약이 있으면 의료전문가와 상의하세요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.foodExpiry);
        },
        icon: const Icon(IconCatalog.inventory2),
        label: const Text('식재료 재고 확인'),
      ),
    );
  }
}

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

class _FoodSearchResult extends StatelessWidget {
  const _FoodSearchResult({required this.query, this.onAdd});

  final String query;
  final ValueChanged<String>? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Text(
        '예: 닭고기, 계란, 두부',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final entry = NutritionFoodKnowledge.lookup(trimmed);
    if (entry == null) {
      return Text(
        '“$trimmed” 데이터가 아직 없습니다.\n'
        '현재 예시: 닭고기, 계란, 두부',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.primaryName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '1인 하루 섭취 권장량(대략)',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.dailyIntakeText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '같이 요리하면 좋은 재료 추천',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        for (final p in entry.pairings)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '• ${p.ingredient} — ${p.why}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (onAdd != null) {
                      onAdd!(p.ingredient);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"${p.ingredient}"을(를) 쇼핑 목록에 추가했습니다.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('쇼핑 화면에서 열면 바로 추가할 수 있어요.')),
                      );
                    }
                  },
                  child: const Text('추가'),
                ),
              ],
            ),
          ),

        if (entry.quantitySuggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '추천 재료량(예시)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in entry.quantitySuggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $line',
                style: theme.textTheme.bodySmall,
              ),
            ),
          Text(
            '참고: 인원/레시피/취향에 따라 달라질 수 있어요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.item,
    this.onTap,
  });

  final NutritionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormats.currency;

    final priceLabel = item.priceMinWon == item.priceMaxWon
        ? '${currency.format(item.priceMinWon)}원'
        : '${currency.format(item.priceMinWon)}~${currency.format(item.priceMaxWon)}원';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              priceLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _FinalJudgementSummary extends StatelessWidget {
  const _FinalJudgementSummary({required this.items});

  final List<NutritionItem> items;

  bool _hasAny(List<String> keys) {
    for (final k in keys) {
      if (items.any((e) => e.name.contains(k))) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasProtein = _hasAny(
      <String>['닭', '달고기', '생선', '연어', '소고기', '돼지고기', '두부', '계란'],
    );
    final hasVeg = _hasAny(
      <String>['양배추', '당근', '양파', '호박', '가지', '브로콜리', '시금치', '토마토'],
    );
    final hasMushroom = _hasAny(<String>['표고', '느타리', '팽이', '버섯']);

    final verdict = (hasProtein && hasVeg)
        ? '균형 잡힌 식단(단백질 + 채소)'
        : (hasProtein ? '단백질은 좋고, 채소 보강 추천' : '채소/단백질 균형 보강 추천');

    final bullets = <String>[];
    if (hasProtein) {
      bullets.add('고단백 식재료가 포함되어 한 끼 구성에 도움이 됩니다.');
    } else {
      bullets.add('단백질원이 보이면 더 균형 잡히기 쉬워요(예: 두부/계란/살코기).');
    }
    if (hasVeg) {
      bullets.add('채소가 포함되어 식이섬유/미네랄 보강에 도움이 됩니다.');
    } else {
      bullets.add('채소를 1~2가지 추가하면 포만감/균형에 도움이 됩니다.');
    }
    if (hasMushroom) {
      bullets.add('버섯류가 있으면 감칠맛/식이섬유 측면에서 보완이 됩니다.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '판단 결과: $verdict',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final b in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '• $b',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

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

    final looksLikeUserSet = hasChicken && hasMushroom &&
        (hasCabbage || hasOnion || hasCarrot || hasBroccoli || hasPumpkin || hasEggplant || hasPotato);

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
        '죽염도 나트륨은 “종류”보다 “사용량”이 더 중요합니다. '
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
      bullets.add('양배추/양파/당근은 “기본 채소 베이스”로 여러 요리에 재사용하기 좋아요.');
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
          '2L 기준 당류를 라벨 확인 없이 추정하면, 대략 ${est.sugarMinG}~${est.sugarMaxG}g 수준인 경우가 많습니다.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '설탕 큐브 1개를 3~4g으로 보면 약 ${est.minCubes}~${est.maxCubes}개 범위로 표현할 수 있어요.',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '정확히는 제품 라벨의 “당류(g)”를 보고 계산하는 게 가장 안전합니다.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

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
    const bullets = [
      '계란: 저렴한 완전단백질 + 요리에 넣기 쉬움.',
      '두부: 가성비 단백질/칼슘(제품별 차이) + 생선/버섯과도 잘 어울림.',
      '김/미역: 미네랄 보강 + 국/반찬으로 간편.',
      '마늘/생강: 향·풍미를 올려 염분을 줄이는 데 도움.',
      '현미/잡곡(또는 귀리): 식이섬유를 늘려 포만감 유지에 도움.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('• $b', style: theme.textTheme.bodyMedium),
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

