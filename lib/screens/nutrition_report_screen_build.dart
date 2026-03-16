// ignore_for_file: invalid_use_of_protected_member
part of 'nutrition_report_screen.dart';

/// Extension: main build method for NutritionReportScreen.
extension NutritionReportBuild on _NutritionReportScreenState {
  Widget _buildMain(BuildContext context) {
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
                if (DateTime.now().day >= 20) _buildChallengeBanner(theme),
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
                                _saveSearch(historyItem);
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
                        '메모/내역 텍스트의 "식재료 + 금액(원)" 패턴을 추정합니다.',
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
                                    _foodSearchController.selection =
                                        TextSelection.fromPosition(
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
      floatingActionButton: _buildBottomButtons(theme),
    );
  }

  Widget _buildChallengeBanner(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200)),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.savings_outlined, color: Colors.green[800]),
              const SizedBox(width: 8),
              Text('냉장고 파먹기 챌린지 기간! 🍳',
                style: TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 16, color: Colors.green[900])),
            ]),
            const SizedBox(height: 8),
            const Text(
              '매달 20일은 냉장고 비우기 챌린지 시작일입니다.\n'
              '남은 10일간 식재료 구입 없이 냉장고 속 재료로만 요리해보세요!\n'
              '식비 절약과 냉장고 정리를 동시에 실천할 수 있습니다.',
              style: TextStyle(height: 1.5, fontSize: 14)),
          ]),
      ),
    );
  }

  Widget _buildBottomButtons(ThemeData theme) {
    final btnShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.green.shade600),
    );
    const btnPad = EdgeInsets.symmetric(horizontal: 16);

    return Padding(
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
                final acct = prefs.getString('selected_account')?.trim() ?? 'A';
                if (!mounted) return;
                navigator.pushNamed(AppRoutes.recipeManagement,
                  arguments: RecipeManagementArgs(accountName: acct));
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiaryContainer,
                foregroundColor: theme.colorScheme.onTertiaryContainer,
                padding: btnPad, shape: btnShape),
              child: const Text('나의레시피', style: TextStyle(fontSize: 13)),
            ),
          ),
          SizedBox(
            height: 40,
            child: FilledButton.tonal(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final prefs = await SharedPreferences.getInstance();
                final acct = prefs.getString('selected_account')?.trim() ?? 'A';
                if (!mounted) return;
                navigator.pushNamed(AppRoutes.recipeManagement,
                  arguments: RecipeManagementArgs(
                    accountName: acct, initialTabIndex: 1));
              },
              style: FilledButton.styleFrom(
                padding: btnPad, shape: btnShape),
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
                padding: btnPad, shape: btnShape),
              child: const Text('재고확인', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
