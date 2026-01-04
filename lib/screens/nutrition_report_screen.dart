import 'package:flutter/material.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
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
    final totalMinLabel = currency.format(report.totalMinWon);
    final totalMaxLabel = currency.format(report.totalMaxWon);

    final totalLabel = report.items.isEmpty
        ? '합계: -'
        : (report.totalMinWon == report.totalMaxWon
              ? '합계: $totalMinLabel원'
              : '합계: $totalMinLabel~$totalMaxLabel원');

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
                                _saveSearch(
                                  historyItem,
                                ); // Refresh history order
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
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💡 지출 입력 화면의 "메모" 필드에 식재료 정보를 작성하면 자동으로 분석됩니다.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '예시:\n'
                              '닭고기(1마리 6500-7500원) 당근 3000원 '
                              '양배추 1000원 팽이 1개 350원',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            for (final item in report.items)
                              _IngredientRow(
                                item: item,
                                onTap: () {
                                  setState(() {
                                    _foodQuery = item.name;
                                    _foodSearchController.text = item.name;
                                    _foodSearchController
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(offset: item.name.length),
                                    );
                                  });
                                },
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

                const _InfoCard(
                  title: '요리 준비 가이드(실제 검증됨)',
                  child: _CookingPreparationGuide(),
                ),
                const SizedBox(height: 12),

                const _InfoCard(
                  title: '식사 후 간단한 후식 조합',
                  child: _DessertSuggestions(),
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
          final ingredients = _report.items.map((e) => e.name).toList();
          Navigator.of(context).pushNamed(
            AppRoutes.foodExpiry,
            arguments: {
              'initialIngredients': ingredients,
              'autoUsageMode': true,
            },
          );
        },
        icon: const Icon(Icons.soup_kitchen),
        label: const Text('재고 확인 및 요리 시작'),
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
                style: theme.textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: '${p.ingredient}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: p.why),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),

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
              child: Text(
                line,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 8),
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

class _CookingPreparationGuide extends StatelessWidget {
  const _CookingPreparationGuide();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final sections = [
      {
        'title': '한 끼 필요 재료 (5L 냄비 1회 기준)',
        'items': [
          '5L 냄비 1회에 들어가는 양이 6-7끼 분량이므로,',
          '기본: 닭고기/돼지고기 약 114g (800g ÷ 7끼)',
          '양파 약 1/2개, 당근 약 1/3-1/2개',
          '가지 약 1/3-1/2개, 호박 약 1/4개',
          '감자 약 1/2개, 양배추 약 30g',
          '버섯류 (표고 약 1/3개, 느타리 + 팽이 약간)',
          '+ 국물(육수 + 된장) 약 350-400ml',
        ],
      },
      {
        'title': '구매 시 권장량 (여러 끼 고려)',
        'items': [
          '닭고기/돼지고기: 800g (약 4끼 분량)',
          '양배추: 1/4통 (약 3-4끼)',
          '양파: 3개 (약 3끼)',
          '당근 1봉지(4개): 약 4끼 (2개/끼)',
          '가지 1팩(3개): 약 3끼 (1개/끼)',
          '호박 1팩(2개): 약 2끼 (1개/끼)',
          '감자 1팩(5개): 약 5끼 (1개/끼)',
          '표고버섯 1팩(3개): 약 3끼 (1개/끼)',
          '팽이버섯 1봉지: 약 1-2끼',
          '느타리버섯 1봉지: 약 2-3끼',
          '소계: 약 20,000원으로 6-7끼 가능 (양념류 별도)',
        ],
      },
      {
        'title': '준비물 (필수)',
        'items': [
          '★ 5L 냄비 1개 (용량 표시: 5.0L) - 이것이 기준입니다',
          '★ 뚜껑 있는 냄비 추천',
          '★ 가스레인지 또는 핫플레이트',
        ],
      },
      {
        'title': '준비 순서 (5L 냄비 1회 기준 - 냄비 가득)',
        'items': [
          '1) 돼지고기 또는 닭고기 800g을 물 2.5-3L에 넣고 육수 우려내기 (5-10분)',
          '2) 된장(큰 스푼 2-3) + 고추장(큰 스푼 1-2) + 마늘/생강 넣기',
          '3) 양파 3개 모두 → 당근 2-3개 → 가지 2-3개 → 호박 1-2개 순으로 투입',
          '4) 감자 2-3개 추가',
          '5) 버섯류(표고 2-3개 + 느타리 1줌 + 팽이 1줌) 모두 추가',
          '6) 양배추 대량(약 150-200g) 마지막에 투입',
          '7) 깻잎/상추 등 잎채소(선택) 마지막 1분 전 추가',
          '8) 모든 재료가 부드러워질 때까지 끓임 (30-40분)',
          '※ 5.0L 냄비가 거의 가득 찼을 정도로 채우면 영양 만점!',
        ],
      },
      {
        'title': '소요 시간 (실제 경험)',
        'items': [
          '전체 조리 시간: 약 1시간 10분-1시간 30분',
          '  └ 재료 준비(손질): 약 20-30분',
          '  └ 끓이기: 약 40-50분',
          '한 번 요리로 2일 식사 가능!',
          '  └ 1일차: 3끼 (또는 3-4끼)',
          '  └ 2일차: 3-4끼 (또는 3끼)',
        ],
      },
      {
        'title': '2일 활용법 (바쁜 직장인 추천)',
        'items': [
          '1단계) 토요일 오전에 1시간 정도 투자해서 5L 냄비 가득 요리',
          '2단계) 모두 식힌 후 일회분씩 밀폐 용기에 담기 (6-7개 분할)',
          '3단계) 냉장실에 보관 (최대 2-3일, 3일 이상 보관 금지!)',
          '⚠️ 2일 분량을 초과하면 변질 위험 있음',
          '결과) 토요일-일요일: 요리 없이 준비된 음식만 먹으면 됨!',
          '장점: 바쁜 주중에 시간 절약 + 건강한 식단 유지',
        ],
      },
      {
        'title': '3일 이상 보관 방법',
        'items': [
          '필요한 경우에만 냉동 추천',
          '1회분씩 소분해서 냉동용기에 담기 (약간씩 자주 먹을 때 편함)',
          '냉동 보관: 최대 1개월 가능',
          '해동: 자연 해동 또는 전자레인지 사용',
          '재가열: 냄비에 넣고 약불에서 천천히 데우기',
        ],
      },
      {
        'title': '정확한 비용 계산 (실제 영수증 기반)',
        'items': [
          '🥩 고기류: 약 4,255원',
          '  └ 한돈사태 또는 돼지고기 살코기 (1묶음)',
          '🥕 채소류: 약 7,720원',
          '  └ 당근(495원) + 애호박(2,180원) + 양배추(376원)',
          '  └ 가지(2,333원) + 감자(354원) + 양파(426원) + 깻잎(660원) + 브로콜리(1,200원)',
          '🍄 버섯류: 약 1,320원',
          '  └ 표고(993원) + 팽이(327원)',
          '━━━━━━━━━━━━━━━━━━━━',
          '💰 1회 요리 총액: 13,668원 (실제 영수증)',
          '6-7끼 ÷ 13,668원 = 1끼당 약 1,950-2,280원',
        ],
      },
      {
        'title': '월간 절약 시뮬레이션 (실제 데이터)',
        'items': [
          '주말 2회 요리(토, 일): 13,668 × 2 = 27,336원',
          '월간 총액: 27,336 × 4주 = 약 109,344원 (약 11만원)',
          '외식 비교(1끼 10,000-15,000원):',
          '  └ 1주일 7끼 × 12,500원(평균) = 87,500원',
          '  └ 월간 약 350,000-400,000원 ⚠️',
          '월간 절약액: 약 241,000-291,000원! 🎯',
          '연간 절약액: 약 2,890,000-3,490,000원!!',
          '※ 1끼당 약 2,000원으로 외식 대비 80% 절약!',
        ],
      },
      {
        'title': '팁 및 안전 주의사항',
        'items': [
          '간은 죽염/소금으로 마지막에 조정',
          '남은 재료는 다음 번 요리에 재활용',
          '가격은 지역/시즌/마트에 따라 ±10-20% 변동',
          '⚠️ 냉장 보관: 최대 2-3일 (3일 이상 보관 금지!)',
          '⚠️ 변질 위험 시 냉동하고 1-2일 분씩 소분 보관 추천',
          '⚠️ 냄새나 맛이 이상하면 버리기 (식중독 위험)',
          '💧 물 섭취: 채소 많음 → 식이섬유 증가 → 변비 예방 필수',
          '  └ 하루 최소 1리터 ~ 최대 2리터 물 섭취 권장',
          '  └ 특히 아침에 일어나서 따뜻한 물 한잔 마시기',
        ],
      },
      {
        'title': '건강 효과 (의학적 가치)',
        'items': [
          '🩺 당뇨병 관리: 3:1 채소-고기 비율 → 혈당 안정 (저GI 식단)',
          '💊 혈압 관리: 칼륨 풍부(양파, 당근, 감자) → 혈압 감소 효과',
          '🫀 고지혈증 개선: 포화지방 적음 + 식이섬유 풍부 → 콜레스테롤 개선',
          '🧠 두뇌건강: 카카오(폴리페놀) + 우유(칼슘) → 인지기능 향상',
          '🦴 뼈건강: 표고버섯(비타민D) + 우유(칼슘) → 골밀도 증가',
          '🔥 소화건강: 식이섬유 24g/끼 → 변비 예방 + 장 건강',
          '⚖️ 체중관리: 1끼 800-900kcal (저칼로리) → 안전한 감량',
          '━━━━━━━━━━━━━━━━━━━━',
          '결론: 외식이 악화시키는 질환들을 개선하는 거의 완전한 식단',
        ],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section['title'] as String,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              for (final item in section['items'] as List<String>)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(bottom: 1),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(item, style: theme.textTheme.bodySmall),
                ),
              const SizedBox(height: 8),
            ],
          ),
      ],
    );
  }
}

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
      {'name': '카카오(100% 분말) + 우유', 'desc': '단백질/칼슘 보충 + 초콜릿의 폴리페놀, 비용 효율적'},
      {'name': '카카오(100% 분말) + 요구르트', 'desc': '유산균 + 항산화 성분 조합, 저비용 고영양'},
      {'name': '아몬드(100% 분말) + 요구르트', 'desc': '건강한 지방/식이섬유 + 유산균, 추천 조합'},
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
