import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../navigation/app_routes.dart';
import '../services/recipe_knowledge_service.dart';
import '../services/user_pref_service.dart';
import '../utils/debounce_utils.dart';
import '../utils/number_formats.dart';
import '../utils/nutrition_food_knowledge.dart';
import '../utils/nutrition_report_utils.dart';

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
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 220),
  );
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
    _searchDebouncer.dispose();
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
                _searchDebouncer.run(() {
                  if (!mounted) return;
                  setState(() {
                    _foodQuery = value;
                  });
                  UserPrefService.setLastRecipeSearchQuery(value);
                });
              },
              onSubmitted: _saveSearch,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (DateTime.now().day >= 20)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                color: Colors.green[800],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '냉장고 파먹기 챌린지 기간! 🍳',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '매달 20일은 냉장고 비우기 챌린지 시작일입니다.\n'
                            '남은 10일간 식재료 구입 없이 냉장고 속 재료로만 요리해보세요!\n'
                            '식비 절약과 냉장고 정리를 동시에 실천할 수 있습니다.',
                            style: TextStyle(height: 1.5, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                        '메모/내역 텍스트의 “식재료 + 금액(원)” 패턴을 추정합니다.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 40,
              child: FilledButton.tonal(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final prefs = await SharedPreferences.getInstance();
                  final accountName =
                      prefs.getString('selected_account')?.trim() ?? 'A';
                  if (!mounted) return;
                  navigator.pushNamed(
                    AppRoutes.recipeManagement,
                    arguments: RecipeManagementArgs(accountName: accountName),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  foregroundColor: theme.colorScheme.onTertiaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.pink.shade300),
                  ),
                ),
                child: const Text('나의레시피', style: TextStyle(fontSize: 13)),
              ),
            ),
            SizedBox(
              height: 40,
              child: FilledButton.tonal(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final prefs = await SharedPreferences.getInstance();
                  final accountName =
                      prefs.getString('selected_account')?.trim() ?? 'A';
                  if (!mounted) return;
                  navigator.pushNamed(
                    AppRoutes.recipeManagement,
                    arguments: RecipeManagementArgs(
                      accountName: accountName,
                      initialTabIndex: 1,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.pink.shade300),
                  ),
                ),
                child: const Text('레시피추천', style: TextStyle(fontSize: 13)),
              ),
            ),
            SizedBox(
              height: 40,
              child: FilledButton.tonal(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.foodExpiry),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.pink.shade300),
                  ),
                ),
                child: const Text('재고확인', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
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

class _FoodSearchResult extends StatefulWidget {
  const _FoodSearchResult({required this.query, this.onAdd});

  final String query;
  final ValueChanged<String>? onAdd;

  @override
  State<_FoodSearchResult> createState() => _FoodSearchResultState();
}

class _FoodSearchResultState extends State<_FoodSearchResult> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant _FoodSearchResult oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = widget.query.trim();

    if (trimmed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '식재료를 입력하세요. 예: 닭고기',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Attempt to look up via Service first, fallback to static if needed
    final entry =
        RecipeKnowledgeService.instance.lookup(trimmed) ??
        NutritionFoodKnowledge.lookup(trimmed);

    if (entry == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            '“$trimmed” 데이터가 없습니다.\n(예: 닭고기, 계란, 두부)',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. 헤더 (이름)
        Text(
          entry.primaryName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),

        // 2. 탭 버튼 (Segmented Control 스타일)
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              _buildTabButton(context, 0, '영양 정보'),
              _buildTabButton(context, 1, '꿀조합'),
              _buildTabButton(context, 2, '추천 수량'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. 내용 (AnimatedSwitcher로 부드러운 전환)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildBody(context, entry),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ],
    );
  }

  Widget _buildTabButton(BuildContext context, int index, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : null,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, FoodKnowledgeEntry entry) {
    switch (_selectedIndex) {
      case 0:
        return _buildIntakeInfo(context, entry);
      case 1:
        return _buildPairings(context, entry);
      case 2:
        return _buildQuantities(context, entry);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntakeInfo(BuildContext context, FoodKnowledgeEntry entry) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('intake'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '1인 하루 섭취 권장량',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            entry.dailyIntakeText,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPairings(BuildContext context, FoodKnowledgeEntry entry) {
    final theme = Theme.of(context);
    if (entry.pairings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('추천 조합 데이터가 없습니다.'),
      );
    }
    return Column(
      key: const ValueKey('pairings'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in entry.pairings)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.restaurant,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.ingredient,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.why,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onAdd != null) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => widget.onAdd?.call(p.ingredient),
                    tooltip: '장바구니 담기',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    style: IconButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuantities(BuildContext context, FoodKnowledgeEntry entry) {
    final theme = Theme.of(context);
    if (entry.quantitySuggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('추천 수량 데이터가 없습니다.'),
      );
    }
    return Column(
      key: const ValueKey('quantities'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '인원과 취향에 따라 조절하세요.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final line in entry.quantitySuggestions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    line,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  static final List<Map<String, Object>> sections = [
    {
      'title': '📊 5L 냄비 1회 = 1인 약 6.7끼 (기준)',
      'items': [
        '⭐ 아래 재료 전부가 5L 냄비 1회분입니다',
        '⭐ 총 재료비: 약 14,945원',
        '⭐ 한 끼당 비용: 약 2,231원 (14,945원 ÷ 6.7끼)',
        '',
        '🥩 고기류 (택1):',
        '  └ 한돈사태 8,510원 (½ 사용 = 4,255원)',
        '  └ 한돈뒷다리살 7,690원 (½ 사용 = 3,845원)',
        '  └ 닭볶음탕 6,500원 (전부 사용)',
        '',
        '🥕 채소류:',
        '  └ 흙당근 1,980원/4개 (2개 사용 = 990원)',
        '  └ 애호박 1,980원/2개 (1개 사용 = 990원)',
        '  └ 애호박(대) 2,380원 (1개 사용 = 1,190원)',
        '  └ 깻순 1,980원 (⅓ 사용 = 660원)',
        '  └ 브로콜리 1,200원 (전부 사용)',
        '  └ 아욱 1,480원 (½ 사용 = 740원, 별도 국거리)',
        '  └ 양배추 1,880원 (⅕ 사용 = 376원)',
        '  └ 가지 3,500원/3개 (2개 사용 = 2,333원)',
        '  └ 감자 1,770원/5개 (1개 사용 = 354원)',
        '  └ 양파 2,980원/7개 (3개 사용 = 1,277원)',
        '',
        '🍄 버섯류:',
        '  └ 표고버섯 2,980원/15개 (5개 사용 = 993원)',
        '  └ 팽이버섯 980원/3개 (1개 사용 = 327원)',
      ],
    },
    {
      'title': '💰 한 끼 재료 환산 (5L ÷ 6.7끼)',
      'items': [
        '고기: 약 120g (800g ÷ 6.7)',
        '양파: 약 0.45개 (3개 ÷ 6.7)',
        '당근: 약 0.3개 (2개 ÷ 6.7)',
        '가지: 약 0.3개 (2개 ÷ 6.7)',
        '호박: 약 0.3개 (2개 ÷ 6.7)',
        '감자: 약 0.15개 (1개 ÷ 6.7)',
        '양배추: 약 30g',
        '표고: 약 0.75개 (5개 ÷ 6.7)',
        '팽이: 약 0.15봉지 (1봉지 ÷ 6.7)',
        '국물: 약 370ml (2.5L ÷ 6.7)',
      ],
    },
    {
      'title': '🛒 장보기 참고 (다음 5L 요리 준비)',
      'items': [
        '닭고기/돼지고기: 800g → 6.7끼',
        '양배추 ⅕통: → 6.7끼',
        '양파 3개: → 6.7끼',
        '당근 2개: → 6.7끼',
        '가지 2개: → 6.7끼',
        '호박 2개: → 6.7끼',
        '감자 1개: → 6.7끼',
        '표고버섯 5개: → 6.7끼',
        '팽이버섯 1봉지: → 6.7끼',
        '',
        '💡 합계: 약 15,000원 = 6.7끼 = 한끼당 2,231원',
      ],
    },
    {
      'title': '🐔 닭고기 버전 (닭볶음탕용)',
      'items': [
        '재료: 닭볶음탕용 약 800g (6,500원)',
        '야채: 흙당근, 감자, 양파, 양배추, 가지, 애호박',
        '버섯: 표고, 팽이',
        '양념: 된장 1숟가락 + 고추장 1숟가락 + 마늘 5쪽',
        '조리: 닭 먼저 끓여 육수 우린 후 → 야채 순차 투입',
        '특징: 담백한 맛, 단백질 풍부',
      ],
    },
    {
      'title': '🐷 돼지고기 버전 (한돈사태/뒷다리살)',
      'items': [
        '재료: 한돈사태 또는 뒷다리살 약 400g (4,000원대)',
        '야채: 동일 (당근, 감자, 양파, 양배추, 가지, 애호박)',
        '버섯: 표고, 팽이',
        '양념: 된장 1숟가락 + 고추장 1숟가락 + 마늘 5쪽',
        '조리: 고기 먼저 데친 후 → 야채 순차 투입',
        '특징: 진한 맛, 국물이 걸쭉',
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
        '2) 된장 1숟가락 + 고추장 1숟가락 + 마늘 5쪽 넣기',
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
      'title': '⏱️ 소요 시간',
      'items': [
        '전체 조리: 약 1시간~1시간 30분',
        '  └ 재료 손질: 20-30분',
        '  └ 끓이기: 40-50분',
        '',
        '📅 한 번 요리 = 2일 식사!',
        '  └ 1일차: 3-4끼',
        '  └ 2일차: 3끼',
        '  └ 합계: 6-7끼 (평균 6.7끼)',
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
        '  └ 한돈사태 1/2 (8,510원의 절반)',
        '🥕 채소류: 약 9,370원',
        '  └ 흙당근(990원) + 애호박(990원+1,190원) + 양배추(376원)',
        '  └ 가지(2,333원) + 감자(354원) + 양파(1,277원) + 깻순(660원) + 브로콜리(1,200원)',
        '🍄 버섯류: 약 1,320원',
        '  └ 표고(993원) + 팽이(327원)',
        '━━━━━━━━━━━━━━━━━━━━',
        '💰 1회 요리 총액: 14,945원 (실제 영수증)',
        '6-7끼 ÷ 14,945원 = 1끼당 약 2,135-2,491원',
      ],
    },
    {
      'title': '월간 절약 시뮬레이션 (실제 데이터)',
      'items': [
        '주말 2회 요리(토, 일): 14,945 × 2 = 29,890원',
        '월간 총액: 29,890 × 4주 = 약 119,560원 (약 12만원)',
        '외식 비교(1끼 10,000-15,000원):',
        '  └ 1주일 7끼 × 12,500원(평균) = 87,500원',
        '  └ 월간 약 350,000-400,000원 ⚠️',
        '월간 절약액: 약 230,000-280,000원! 🎯',
        '연간 절약액: 약 2,760,000-3,360,000원!!',
        '※ 1끼당 약 2,300원으로 외식 대비 80% 절약!',
      ],
    },
    {
      'title': '🍮 후식 (디저트/간식)',
      'items': [
        '1) 우유 + 카카오: 우유 1잔 + 유기농 카카오 분말 1스푼',
        '  └ 포만감 보강, 폴리페놀(항산화) + 칼슘',
        '2) 과일: 계절 과일 1개 (사과/바나나/귤 등)',
        '  └ 비타민 + 식이섬유 보충',
        '3) 견과류: 아몬드/호두 한 줌 (약 10-15개)',
        '  └ 좋은 지방 + 단백질',
        '4) 요거트: 그릭요거트 또는 플레인 요거트',
        '  └ 유산균 + 단백질',
        '💡 팁: 후식은 식후 30분~1시간 후 섭취 권장',
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

  /*
  static List<String> extractIngredientNames() {
    final out = <String>[];
    final seen = <String>{};

    void addOne(String v) {
      final t = v.trim();
      if (t.isEmpty) return;
      final key = t.toLowerCase();
      if (seen.add(key)) out.add(t);
    }

    void addSplit(String raw) {
      final cleaned = raw
          .replaceAll('(', ' ')
          .replaceAll(')', ' ')
          .replaceAll('→', ' ')
          .replaceAll(':', ' ')
          .replaceAll('  ', ' ')
          .trim();

      if (cleaned.isEmpty) return;

        final parts = cleaned
          .split(RegExp(r'[,/+]|\s\+\s|\s와\s|\s또는\s'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);

      for (final p in parts) {
        // Keep the leading word-ish part before numbers/units
        final first = p
            .replaceAll(RegExp('[0-9]+([,./][0-9]+)*'), ' ')
            .replaceAll(RegExp('[⅓⅕½]'), ' ')
            .replaceAll(RegExp('원|g|kg|ml|l|개|봉지|통|줌|숟가락|스푼|쪽|잔|회|끼'), ' ')
            .replaceAll(RegExp('약|전부|모두|필수|선택|추천|기준'), ' ')
            .replaceAll(RegExp('\\s+'), ' ')
            .trim();

        if (first.isEmpty) continue;

        // Filter obvious non-ingredients
        final lower = first.toLowerCase();
        if (lower.contains('냄비') ||
            lower.contains('가스레인지') ||
            lower.contains('핫플레이트') ||
            lower.contains('용기') ||
            lower.contains('전자레인지')) {
          continue;
        }

        addOne(first);
      }
    }

    for (final section in sections) {
      final items = section['items'] as List<String>;
      for (final line in items) {
        final t = line.trim();
        if (t.isEmpty) continue;

        // Fast-path: structured lines
        if (t.contains('└')) {
          final idx = t.indexOf('└');
          if (idx >= 0 && idx + 1 < t.length) {
            addSplit(t.substring(idx + 1));
            continue;
          }
        }

        if (t.startsWith('재료') ||
            t.startsWith('야채') ||
            t.startsWith('버섯') ||
            t.startsWith('양념')) {
          final idx = t.indexOf(':');
          if (idx >= 0 && idx + 1 < t.length) {
            addSplit(t.substring(idx + 1));
            continue;
          }
        }

        // Generic: lines with obvious ingredient separators
        if (t.contains(',') ||
            t.contains('/') ||
            t.contains(' + ') ||
            t.contains('또는')) {
          addSplit(t);
        }
      }
    }

    return out;
  }
  */

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

  /*
  static const List<String> recommendationIngredientNames = [
    '계란',
    '두부',
    '김',
    '미역',
    '마늘',
    '생강',
    '현미',
    '잡곡',
    '귀리',
  ];
  */

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
