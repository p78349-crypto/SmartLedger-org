import 'package:flutter/material.dart';
import '../models/savings_plan.dart';
import 'savings_plan_form_screen.dart';
import '../services/savings_plan_service.dart';
import '../services/transaction_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_formats.dart';
import '../utils/number_formats.dart';
import '../widgets/state_placeholders.dart';

class SavingsPlanListScreen extends StatefulWidget {
  final String accountName;
  const SavingsPlanListScreen({super.key, required this.accountName});

  @override
  State<SavingsPlanListScreen> createState() => _SavingsPlanListScreenState();
}

class _SavingsPlanListScreenState extends State<SavingsPlanListScreen> {
  List<SavingsPlan> _plans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await SavingsPlanService().loadPlans();
      await TransactionService().loadTransactions();
      if (!mounted) return;
      setState(() {
        _plans = SavingsPlanService().getPlans(widget.accountName);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '예금을 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openForm({SavingsPlan? plan}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SavingsPlanFormScreen(
          accountName: widget.accountName,
          initialPlan: plan,
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      await _loadPlans();
    }
  }

  Future<void> _deletePlan(SavingsPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('예금 삭제'),
        content: Text('"${plan.name}" 계획을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      await SavingsPlanService().deletePlan(widget.accountName, plan.id);
      await _loadPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '예금 목록',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.savingsText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openForm,
            tooltip: '예금 추가',
          ),
        ],
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingCardListSkeleton(itemCount: 5, height: 140),
            )
          : _error != null
          ? ErrorState(message: _error, onRetry: _loadPlans)
          : _plans.isEmpty
          ? EmptyState(
              title: '등록된 예금이 없습니다',
              message: '목표를 만들어 자동이체/알림으로 관리하세요.',
              primaryLabel: '예금 추가',
              onPrimary: _openForm,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                final progress = plan.paidCount / plan.termMonths;
                final monthlyAmount = NumberFormats.currency.format(
                  plan.monthlyAmount,
                );
                final depositedAmount = NumberFormats.currency.format(
                  plan.depositedAmount,
                );
                final expectedAmount = NumberFormats.currency.format(
                  plan.expectedMaturityAmount,
                );
                final startDateStr = DateFormats.yMddot.format(plan.startDate);
                final maturityDateStr = DateFormats.yMddot.format(
                  plan.maturityDate,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                plan.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  iconSize: 20,
                                  onPressed: () => _openForm(plan: plan),
                                  tooltip: '수정',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  iconSize: 20,
                                  color: Colors.red,
                                  onPressed: () => _deletePlan(plan),
                                  tooltip: '삭제',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              plan.autoDeposit
                                  ? Icons.check_circle
                                  : Icons.notifications_active,
                              size: 16,
                              color: plan.autoDeposit
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              plan.autoDeposit ? '자동이체' : '알림',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '월 $monthlyAmount원',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '${plan.paidCount}/${plan.termMonths}회',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '납입 금액',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '$depositedAmount원',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '만기 예상액',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '$expectedAmount원',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '시작: $startDateStr',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '만기: $maturityDateStr',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
