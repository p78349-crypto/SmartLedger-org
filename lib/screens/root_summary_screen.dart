import 'package:flutter/material.dart';
import '../utils/top_level_stats_utils.dart';
import '../widgets/root_summary_card.dart';

/// ROOT 요약 화면
/// 전체 계정의 수입/지출/예금/순이익을 한눈에 보여줍니다.
class RootSummaryScreen extends StatefulWidget {
  const RootSummaryScreen({super.key});

  @override
  State<RootSummaryScreen> createState() => _RootSummaryScreenState();
}

class _RootSummaryScreenState extends State<RootSummaryScreen> {
  bool _isLoading = true;
  RootDashboardContext? _context;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final context = TopLevelStatsUtils.buildDashboardContext();
      if (!mounted) return;
      setState(() {
        _context = context;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ROOT 요약'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _context == null
              ? const Center(child: Text('데이터를 불러올 수 없습니다.'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RootSummaryCard(
                          data: _context!.summaryData,
                          onViewDetail: () {},
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '통계 정보',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  '전체 계정 수',
                                  '${_context!.accounts.length}개',
                                  theme,
                                ),
                                const Divider(height: 16),
                                _buildInfoRow(
                                  '전체 거래 건수',
                                  '${_context!.allTransactions.length}건',
                                  theme,
                                ),
                                const Divider(height: 16),
                                _buildInfoRow(
                                  '전체 고정비',
                                  '${_context!.allFixedCosts.length}개',
                                  theme,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
