part of 'micro_savings_nudge_screen.dart';

extension MicroSavingsNudgeUI on _MicroSavingsNudgeScreenState {
  Widget _quickEntryCard(ThemeData theme) {
    double totalInput = 0;
    for (var c in _amountControllers) {
      final val = CurrencyFormatter.parse(c.text.trim());
      if (val != null) totalInput += val;
    }

    // 동적 목표 금액 파싱
    final currentTarget =
        CurrencyFormatter.parse(_targetController.text.trim())?.toDouble() ??
        _selectedTarget;

    final r = (_projectSafeRatePct / 100.0) / 12.0;
    const n10 = 120.0;
    double fv10 = 0;
    double monthsToTarget = 0;
    double requiredMonthlyFor10y = 0;

    if (totalInput > 0) {
      if (r > 0) {
        fv10 = totalInput * (math.pow(1 + r, n10) - 1) / r * (1 + r);
        final val = (currentTarget * r) / (totalInput * (1 + r)) + 1;
        if (val > 0) {
          monthsToTarget = math.log(val) / math.log(1 + r);
        }
        requiredMonthlyFor10y =
            currentTarget * r / ((math.pow(1 + r, n10) - 1) * (1 + r));
      } else {
        fv10 = totalInput * n10;
        monthsToTarget = currentTarget / totalInput;
        requiredMonthlyFor10y = currentTarget / n10;
      }
    }

    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_graph,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '자산 가속 입력 & 시뮬레이션',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            // 분류 및 목표 선택
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('참은 소비'),
                        icon: Icon(Icons.money_off, size: 16),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('포인트'),
                        icon: Icon(Icons.card_giftcard, size: 16),
                      ),
                    ],
                    selected: {_selectedTypeIndex},
                    onSelectionChanged: (set) =>
                        setState(() => _selectedTypeIndex = set.first),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '목표 금액 설정:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _targetPresetChip('1,000만', 10000000),
                      const SizedBox(width: 4),
                      _targetPresetChip('3,000만', 30000000),
                      const SizedBox(width: 4),
                      _targetPresetChip('5,000만', 50000000),
                      const SizedBox(width: 4),
                      _targetPresetChip('1억', 100000000),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetController,
                  decoration: const InputDecoration(
                    labelText: '목표 금액 직접 입력',
                    isDense: true,
                    suffixText: '원',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 13),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _amountControllers[index],
                        decoration: InputDecoration(
                          labelText: '금액 ${index + 1}',
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 13),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          if (_showCalculation) {
                            setState(() => _showCalculation = false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _memoControllers[index],
                        decoration: InputDecoration(
                          labelText: '메모 ${index + 1}',
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (!_showCalculation)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: totalInput > 0
                      ? () => setState(() => _showCalculation = true)
                      : null,
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('미래가치 계산해보기'),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '💰 월 합계: ${CurrencyFormatter.format(totalInput)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 16),
                    Text(
                      '📅 10년 후 예상: ${CurrencyFormatter.format(fv10)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      '🚀 목표(${CurrencyFormatter.format(currentTarget)}) 달성: ${monthsToTarget > 0 ? (monthsToTarget / 12).toStringAsFixed(1) : "??"}년',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '💡 10년내 목표 달성을 위해선 매월 ${CurrencyFormatter.format(requiredMonthlyFor10y)} 저축이 필요해요.',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: totalInput > 0 ? _onBatchSave : null,
              icon: const Icon(Icons.save),
              label: Text(
                '${_selectedTypeIndex == 0 ? "참은 소비" : "포인트"} ${CurrencyFormatter.format(totalInput)} 기록하기',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetPresetChip(String label, double value) {
    // 쉼표 포함 형식과 숫자를 비교하기 위해 파싱 필요
    final currentTarget =
        CurrencyFormatter.parse(_targetController.text.trim())?.toDouble() ?? 0;
    final isSelected = currentTarget == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          _selectedTarget = value;
          _targetController.text = CurrencyFormatter.format(value);
        });
      },
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _metric(
    ThemeData theme, {
    required String title,
    required _SumCount month,
    required _SumCount lookback,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(month.total),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '이번달 ${month.count}건 · 최근 6개월 '
              '${CurrencyFormatter.format(lookback.total)} '
              '(${lookback.count}건)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('자산 가속(푼돈 모으기)'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _quickEntryCard(theme),
                const SizedBox(height: 20),
                Text(
                  '나의 저축 현황',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _metric(
                  theme,
                  title: '참은 소비',
                  month: _skippedThisMonth,
                  lookback: _skippedLookback,
                ),
                const SizedBox(height: 12),
                _metric(
                  theme,
                  title: '포인트 모으기',
                  month: _pointsThisMonth,
                  lookback: _pointsLookback,
                ),
                const SizedBox(height: 12),
                _metric(
                  theme,
                  title: '잔돈 모으기(반올림)',
                  month: _roundUpThisMonth,
                  lookback: _roundUpLookback,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text('기타 기능', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final changed = await showRoundUpDialog(
                        context,
                        accountName: widget.accountName,
                      );
                      if (changed) await _load();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('잔돈 모으기(반올림) 수동 기록'),
                  ),
                ),
              ],
            ),
    );
  }
}
