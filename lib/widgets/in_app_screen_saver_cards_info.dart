part of 'in_app_screen_saver.dart';

class _BudgetCard extends StatelessWidget {
  final double planned;
  final double used;
  const _BudgetCard({required this.planned, required this.used});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final pct = planned <= 0 ? 0.0 : (used / planned).clamp(0.0, 2.0);
    return _CardShell(
      title: '예산',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번달 사용률',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: planned <= 0 ? 0 : pct.clamp(0.0, 1.0),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            planned <= 0 ? '계획 예산이 설정되지 않았습니다' : '지출 금액은 보호됩니다',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final double balance;
  final double usedThisMonth;

  const _EmergencyCard({required this.balance, required this.usedThisMonth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _CardShell(
      title: '비상금',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '잔액 보호됨',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            usedThisMonth > 0 ? '이번달 사용 기록 있음' : '이번달 사용 기록 없음',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingCard extends StatelessWidget {
  final int todayCount;
  final int monthCount;

  const _SpendingCard({required this.todayCount, required this.monthCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _CardShell(
      title: '지출 요약',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '오늘',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$todayCount건',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '이번달',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$monthCount건',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '금액은 보호됩니다',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  final _RecentTxSummary recent;
  const _RecentTransactionsCard({required this.recent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _CardShell(
      title: '최근 거래',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 7일 거래 요약(금액 보호)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TinyStat(
                  label: '지출건수',
                  value: '${recent.outflowCount7d}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TinyStat(
                  label: '수입건수',
                  value: '${recent.inflowCount7d}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetFlowCard extends StatelessWidget {
  final AssetFlowStats flow;
  const _AssetFlowCard({required this.flow});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _CardShell(
      title: '자산 흐름(이번달)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '유입/유출은 보호됩니다(건수만 표시)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TinyStat(
                  label: '매도',
                  value: '${flow.countByType[AssetMoveType.sale] ?? 0}건',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TinyStat(
                  label: '매수',
                  value: '${flow.countByType[AssetMoveType.purchase] ?? 0}건',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TinyStat(
            label: '예금',
            value: '${flow.countByType[AssetMoveType.deposit] ?? 0}건',
          ),
        ],
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  final String label;
  final String value;
  const _TinyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
