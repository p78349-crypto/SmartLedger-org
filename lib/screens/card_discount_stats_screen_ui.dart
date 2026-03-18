part of 'card_discount_stats_screen.dart';

extension CardDiscountStatsUI on _CardDiscountStatsScreenState {
  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final byCategory = _aggregateForPeriod();
    final totalRaw = byCategory.values.fold<double>(0, (s, v) => s + v);
    final annualRatePctUsed = _annualRatePctFromTextOrFallback(
      _annualRateController.text,
    );
    final total = _applyAnnualRate(
      totalRaw,
      years: _selectedYears,
      annualRatePct: annualRatePctUsed,
    );
    const target = 100000000.0; // 1억
    final ratio = total > 0 ? (total / target * 100) : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('1억 모으기 프로젝트')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // ── Subtitle ──
            Text(
              '포인트모아서 1억만들기,\n포인트 사용하지말고 고이게 해보세요',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // ── 2×2 Grid ──
            Row(
              children: [
                Expanded(
                  child: _buildCategoryBox(
                    theme,
                    '카드 할인금액',
                    byCategory[_CardDiscountStatsScreenState._catCard] ?? 0,
                    Icons.credit_card,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryBox(
                    theme,
                    '마트할인금액',
                    byCategory[_CardDiscountStatsScreenState._catMart] ?? 0,
                    Icons.store,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCategoryBox(
                    theme,
                    '쇼핑몰 할인금액',
                    byCategory[_CardDiscountStatsScreenState._catShopping] ?? 0,
                    Icons.shopping_bag_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryBox(
                    theme,
                    '기타',
                    byCategory[_CardDiscountStatsScreenState._catOther] ?? 0,
                    Icons.more_horiz,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Period selector ──
            _buildSectionBox(
              theme,
              child: Column(
                children: [
                  Text(
                    '기간선택 버튼',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _CardDiscountStatsScreenState._periodYears.map((
                      y,
                    ) {
                      final selected = y == _selectedYears;
                      return ChoiceChip(
                        label: Text('$y'),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedYears = y),
                        selectedColor: scheme.primary,
                        labelStyle: TextStyle(
                          color: selected ? scheme.onPrimary : scheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: scheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Annual rate input (default 3%) ──
            _buildSectionBox(
              theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '연 이율 입력 기본값 3%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '변경은 1억 프로젝트 설정(기어)에서만 가능합니다.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 45,
                        child: TextField(
                          controller: _annualRateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          readOnly: true,
                          showCursor: false,
                          enableInteractiveSelection: false,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '%',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _interestMode ==
                                  _CardDiscountStatsScreenState
                                      ._modeSimpleAnnual
                              ? '선택 기간($_selectedYears년) 동안 연이자(단리)로 계산됩니다.'
                              : '선택 기간($_selectedYears년) 동안 복리로 계산됩니다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text(
                    '이자 계산',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('연이자'),
                        selected:
                            _interestMode ==
                            _CardDiscountStatsScreenState._modeSimpleAnnual,
                        selectedColor: scheme.primary,
                        labelStyle: TextStyle(
                          color:
                              _interestMode ==
                                  _CardDiscountStatsScreenState
                                      ._modeSimpleAnnual
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: scheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('연복리'),
                        selected:
                            _interestMode ==
                            _CardDiscountStatsScreenState._modeCompoundYearly,
                        selectedColor: scheme.primary,
                        labelStyle: TextStyle(
                          color:
                              _interestMode ==
                                  _CardDiscountStatsScreenState
                                      ._modeCompoundYearly
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: scheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('월복리'),
                        selected:
                            _interestMode ==
                            _CardDiscountStatsScreenState._modeCompoundMonthly,
                        selectedColor: scheme.primary,
                        labelStyle: TextStyle(
                          color:
                              _interestMode ==
                                  _CardDiscountStatsScreenState
                                      ._modeCompoundMonthly
                              ? scheme.onPrimary
                              : scheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: scheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Total amount ──
            _buildSectionBox(
              theme,
              child: Column(
                children: [
                  Text(
                    '카드,마트 쇼핑몰,기타 금액 합계금액',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(total),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '원금: ${CurrencyFormatter.format(totalRaw)} / 연 ${annualRatePctUsed.toStringAsFixed(1)}% 반영',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 1억 ratio ──
            _buildSectionBox(
              theme,
              child: Column(
                children: [
                  Text(
                    '1억 모으기 프로젝트 /합계금액 차지하는 비율%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${ratio.toStringAsFixed(2)}%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (ratio / 100).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // space for FAB
          ],
        ),
      ),

      // ── FAB → 기존 1억 프로젝트 상세 화면 ──
      floatingActionButton: FloatingActionButton(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        onPressed: () {
          Navigator.of(context).pushNamed(
            AppRoutes.assetProject100m,
            arguments: AccountArgs(accountName: widget.accountName),
          );
        },
        tooltip: '1억 프로젝트 상세',
        child: const Icon(Icons.flag_outlined),
      ),
    );
  }

  Widget _buildCategoryBox(
    ThemeData theme,
    String label,
    double amount,
    IconData icon,
  ) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBox(ThemeData theme, {required Widget child}) {
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline, width: 1.5),
      ),
      child: child,
    );
  }
}
