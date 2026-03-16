import 'package:flutter/material.dart';

import '../navigation/app_routes_args.dart';
import '../navigation/app_routes_paths.dart';
import '../services/reward_badge_service.dart';
import 'micro_savings_nudge_screen.dart';

class RewardSystemStatsScreen extends StatefulWidget {
  const RewardSystemStatsScreen({super.key, required this.accountName});

  final String accountName;

  @override
  State<RewardSystemStatsScreen> createState() =>
      _RewardSystemStatsScreenState();
}

class _RewardSystemStatsScreenState extends State<RewardSystemStatsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('보상 시스템'),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: RewardBadgeService.instance.getCounts(widget.accountName),
        builder: (context, snapshot) {
          final counts = snapshot.data ?? const <String, int>{};
          final p = counts[RewardBadgeService.typeProject100m] ?? 0;
          final s = counts[RewardBadgeService.typeSkippedSpend] ?? 0;
          final f = counts[RewardBadgeService.typeFoodRescue] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '금메달이 계속 쌓입니다 🥇',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _countChip(theme, '참은 소비', s),
                  _countChip(theme, '포인트 모으기', p),
                  _countChip(theme, '식료품 소비', f),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  '하단 3개 버튼에서 기록/사용을 진행하면 자동으로 금메달이 누적됩니다.\n'
                  '보상 확인은 이 통계 화면에서만 합니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MicroSavingsNudgeScreen(
                          accountName: widget.accountName,
                          initialTypeIndex: 0,
                        ),
                      ),
                    );
                  },
                  child: const Text('참은 소비'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MicroSavingsNudgeScreen(
                          accountName: widget.accountName,
                          initialTypeIndex: 1,
                        ),
                      ),
                    );
                  },
                  child: const Text('포인트 모으기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.foodExpiry,
                      arguments: const FoodExpiryArgs(autoUsageMode: true),
                    );
                  },
                  child: const Text('식료품 소비'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countChip(ThemeData theme, String label, int count) {
    return Chip(
      avatar: const Icon(Icons.emoji_events, size: 18),
      label: Text('$label $count'),
      visualDensity: VisualDensity.compact,
    );
  }
}
