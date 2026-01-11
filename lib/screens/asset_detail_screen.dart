import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_move.dart';
import '../services/asset_move_service.dart';
import '../services/asset_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/profit_loss_calculator.dart';

/// 자산 상세 화면 - 이동 기록 타임라인 표시
class AssetDetailScreen extends StatefulWidget {
  final String accountName;
  final Asset asset;

  const AssetDetailScreen({
    super.key,
    required this.accountName,
    required this.asset,
  });

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  late Asset _currentAsset;

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.asset;
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    try {
      final assetService = AssetService();
      await assetService.loadAssets();
      final assets = assetService.getAssets(widget.accountName);
      final updated = assets.firstWhere(
        (a) => a.id == widget.asset.id,
        orElse: () => widget.asset,
      );
      if (mounted) {
        setState(() => _currentAsset = updated);
      }
    } catch (e) {
      debugPrint('자산 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: AssetMoveService().loadMoves(),
      builder: (context, snapshot) {
        return _buildDetailScreen();
      },
    );
  }

  Widget _buildDetailScreen() {
    final theme = Theme.of(context);
    final assetMoveService = AssetMoveService();
    final rawMoves = assetMoveService.getMovesForAsset(
      widget.accountName,
      widget.asset.id,
    );
    final moves = rawMoves.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 최신순
    final currentAmountLabel = CurrencyFormatter.format(_currentAsset.amount);
    final categoryLabel =
        '${_currentAsset.category.emoji} ${_currentAsset.category.label}';
    final registrationDateLabel = DateFormatter.defaultDate.format(
      _currentAsset.date,
    );
    final costBasisLabel = _currentAsset.costBasis != null
        ? CurrencyFormatter.format(_currentAsset.costBasis!)
        : null;
    final expectedRateLabel = _currentAsset.expectedAnnualRatePct != null
        ? '${_currentAsset.expectedAnnualRatePct!.toStringAsFixed(2)}%'
        : null;
    final targetRatioLabel = _currentAsset.targetRatio != null
        ? '${_currentAsset.targetRatio!.toStringAsFixed(1)}%'
        : null;
    final targetAmountLabel = _currentAsset.targetAmount != null
        ? CurrencyFormatter.format(_currentAsset.targetAmount!)
        : null;
    final hasCostBasis = costBasisLabel != null;
    final hasExpectedRate = expectedRateLabel != null;
    final hasTargetRatio = targetRatioLabel != null;
    final hasTargetAmount = targetAmountLabel != null;
    final costBasisText = costBasisLabel ?? '';
    final expectedRateText = expectedRateLabel ?? '';
    final targetRatioText = targetRatioLabel ?? '';
    final targetAmountText = targetAmountLabel ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asset.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 잔액 카드
            Container(
              width: double.infinity,
              color: theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('현재 잔액', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(
                    currentAmountLabel,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  // ✅ 손익 정보 표시 (원가가 있는 경우만)
                  if (hasCostBasis) ...[
                    const SizedBox(height: 8),
                    _buildProfitLossDisplay(theme),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('카테고리', style: theme.textTheme.labelSmall),
                          Text(
                            categoryLabel,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('등록일', style: theme.textTheme.labelSmall),
                          Text(
                            registrationDateLabel,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // ✅ 원가 정보 표시
                  if (hasCostBasis) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '원가',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            costBasisText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (hasExpectedRate) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '기대수익률(연)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            expectedRateText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (hasTargetRatio || hasTargetAmount) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (hasTargetRatio)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('목표 비율', style: theme.textTheme.labelSmall),
                              Text(
                                targetRatioText,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        if (hasTargetAmount)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('목표액', style: theme.textTheme.labelSmall),
                              Text(
                                targetAmountText,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                  if (_currentAsset.memo.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _currentAsset.memo,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 자산 이동 흐름 경로 (전체 계정 관점)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPerformanceAnalysis(theme),
                  const SizedBox(height: 24),
                  Text(
                    '자산 이동 흐름',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAssetFlowPath(context, theme),
                ],
              ),
            ),

            // 자산 변화 타임라인 (생성 시점부터)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '자산 변화 기록',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '총 ${moves.length + 1}건',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 초기 생성 항목
                  _buildInitialAssetTimeline(context, theme),
                  if (moves.isNotEmpty) const SizedBox(height: 16),
                  // 이동 기록들
                  if (moves.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          '이후 이동 기록이 없습니다',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: moves.length,
                      itemBuilder: (context, index) {
                        final move = moves[index];
                        final isFromCurrent =
                            move.fromAssetId == widget.asset.id;
                        final isOutgoing = isFromCurrent;

                        final isLastMove = index == moves.length - 1;
                        return _buildMoveTimeline(
                          context,
                          move,
                          isOutgoing,
                          isLastMove,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveTimeline(
    BuildContext context,
    AssetMove move,
    bool isOutgoing,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final assetService = AssetService();
    final assets = assetService.getAssets(widget.accountName);
    final moveTimestamp = _formatTimestamp(move.date);

    String? targetAssetName;
    if (isOutgoing) {
      if (move.toAssetId != null) {
        try {
          targetAssetName = assets
              .firstWhere((asset) => asset.id == move.toAssetId)
              .name;
        } catch (_) {}
      }
      targetAssetName ??= move.toCategoryName ?? '알 수 없음';
    } else {
      try {
        targetAssetName = assets
            .firstWhere((asset) => asset.id == move.fromAssetId)
            .name;
      } catch (_) {}
      targetAssetName ??= move.toCategoryName ?? '알 수 없음';
    }

    final directionLabel = isOutgoing ? '→' : '←';
    final amountColor = isOutgoing ? theme.colorScheme.error : Colors.green;
    final amountSign = isOutgoing ? '-' : '+';
    final moveAmountLabel = _formatAmountWithUnit(move.amount);

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타임라인 라인
              Column(
                children: [
                  // 원
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: amountColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // 세로줄
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단: 일시 및 유형
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          moveTimestamp,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: amountColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            move.type.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: amountColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 중앙: 이동 경로
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.asset.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ' $directionLabel ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            targetAssetName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 하단: 금액 및 메모
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$amountSign$moveAmountLabel',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                    if (move.memo.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          move.memo,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const SizedBox(height: 16),
      ],
    );
  }

  String _formatAmountWithUnit(num value) {
    return CurrencyFormatter.format(value);
  }

  String _formatTimestamp(DateTime date) {
    return DateFormatter.dateTime.format(date);
  }

  /// 자산 최초 생성 항목 표시
  Widget _buildInitialAssetTimeline(BuildContext context, ThemeData theme) {
    final creationTimestamp = _formatTimestamp(_currentAsset.date);
    final assetLabel =
        '${_currentAsset.category.emoji} ${_currentAsset.name} 생성';
    final initialAmountLabel = _formatAmountWithUnit(_currentAsset.amount);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 라인
          Column(
            children: [
              // 원
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              // 세로줄
              Expanded(
                child: Container(
                  width: 2,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단: 일시 및 생성
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      creationTimestamp,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '최초 보유',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 중앙: 자산 이름
                Text(
                  assetLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // 하단: 초기 금액
                Text(
                  '+$initialAmountLabel',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (_currentAsset.memo.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _currentAsset.memo,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 자산 성과/이력 분석 (New Feature)
  /// - 예금: 납입액 vs 수령액 -> 이자 계산
  /// - 투자: 총 매수 vs 총 매도 -> 수익률 계산
  /// - 기록: 메모를 강조하여 전략 수립 보조
  Widget _buildPerformanceAnalysis(ThemeData theme) {
    final moves = AssetMoveService().getMovesForAsset(
      widget.accountName,
      widget.asset.id,
    );

    // 1. 데이터 집계
    double totalIn = 0; // 총 투입 (매수/이체입금/예금납입)
    double totalOut = 0; // 총 회수 (매도/이체출금/만기수령)

    // 메모 기록 (전략 노트용)
    final historyItems = <Map<String, dynamic>>[];

    for (var m in moves) {
      final isIn = m.toAssetId == widget.asset.id;
      final isOut = m.fromAssetId == widget.asset.id;

      if (isIn) totalIn += m.amount;
      if (isOut) totalOut += m.amount;

      historyItems.add({
        'date': m.date,
        'type': m.type.label,
        'amount': m.amount,
        'isIncome': isIn, // 나에게 들어온 것(자산 증가?) No.
        // Asset 관점:
        // - In: Cash -> Asset (Investment)
        // - Out: Asset -> Cash (Realization)
        'memo': m.memo,
      });
    }

    // 현재 평가액 포함하여 총 가치 산정
    final currentValue = _currentAsset.amount;

    // 순수익 (실현 + 미실현)
    // Profit = (Total Out + Current Value) - Total In
    final netProfit = (totalOut + currentValue) - totalIn;
    final returnRate = totalIn > 0 ? (netProfit / totalIn) * 100 : 0.0;

    final isDeposit = widget.asset.category == AssetCategory.deposit;
    // Removed unused isInvestment variable

    // 표시 여부 결정 (거래 내역이 없으면 숨김)
    if (moves.isEmpty) return const SizedBox.shrink();

    final profitColor = netProfit > 0
        ? Colors.green
        : (netProfit < 0
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface);
    final profitSign = netProfit > 0 ? '+' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isDeposit ? Icons.savings_outlined : Icons.show_chart,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              isDeposit ? '예금/적금 성과 분석' : '투자 성과 리포트',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 성과 요약 카드
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAnalysisItem(
                    theme,
                    isDeposit ? '총 납입원금' : '총 매수금액',
                    totalIn,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _buildAnalysisItem(
                    theme,
                    isDeposit ? '총 수령액(+평가액)' : '총 매도액(+평가액)',
                    totalOut + currentValue,
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '순수익 (ROI)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$profitSign${CurrencyFormatter.format(netProfit)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: profitColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$profitSign${returnRate.toStringAsFixed(2)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: profitColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (netProfit < 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '손실이 발생했습니다. 아래 기록의 메모를 확인하여 전략을 점검하세요.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text(
          '히스토리 및 전략 노트',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: historyItems.length,
          separatorBuilder: (context, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            // 시간 역순 정렬
            final item = historyItems[historyItems.length - 1 - index];
            final date = item['date'] as DateTime;
            final isAssetIn = item['isIncome'] as bool; // 자산으로 들어옴 (매수/납입)
            // 통상: 매수는 지출(Red/Blue depends on culture). 매도는 수입.
            // 여기서는 TransactionType이 없으므로 Context에 따름.
            // 자산 관점: IN(증가), OUT(감소)
            final amountColor = isAssetIn
                ? theme.colorScheme.primary
                : theme.colorScheme.error;
            final prefix = isAssetIn ? '+ ' : '- ';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormatter.defaultDate.format(date),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isAssetIn
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isAssetIn
                                  ? (isDeposit ? '납입' : '매수')
                                  : (isDeposit ? '출금/만기' : '매도'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$prefix${CurrencyFormatter.format(item['amount'])}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (item['memo'] != null &&
                      (item['memo'] as String).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceContainerHighest, // 강조 배경
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.edit_note, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['memo'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnalysisItem(ThemeData theme, String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(value),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 자산 이동 흐름 경로를 시각화 (개선된 버전)
  Widget _buildAssetFlowPath(BuildContext context, ThemeData theme) {
    final assetService = AssetService();
    final assetMoveService = AssetMoveService();

    // 모든 자산과 이동 기록 로드
    final allAssets = assetService.getAssets(widget.accountName);
    final allMoves = assetMoveService.getMoves(widget.accountName);

    // 이 자산과 관련된 이동만 필터링
    final relatedMoves = allMoves.where((move) {
      final isSource = move.fromAssetId == widget.asset.id;
      final isDestination = move.toAssetId == widget.asset.id;
      return isSource || isDestination;
    });
    final assetMoves = relatedMoves.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (assetMoves.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '아직 이동 기록이 없습니다',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // 경로 데이터 구성
    final pathItems = <Map<String, dynamic>>[];

    // 시작 자산 추가
    pathItems.add({
      'emoji': widget.asset.category.emoji,
      'name': widget.asset.category.label,
      'isStart': true,
    });

    // 이동 기록 추가
    for (int i = 0; i < assetMoves.length; i++) {
      final move = assetMoves[i];

      // 이동 타입 정보 (금액, 날짜 포함)
      pathItems.add({
        'emoji': _getMoveTypeEmoji(move.type),
        'name': move.type.label,
        'isMoveType': true,
        'date': move.date,
        'amount': CurrencyFormatter.format(move.amount),
        'dateLabel': DateFormatter.shortMonth.format(move.date),
      });

      // 대상 자산 추가
      if (move.fromAssetId == widget.asset.id) {
        // 출발
        if (move.toAssetId != null) {
          final toAsset = allAssets.firstWhere(
            (a) => a.id == move.toAssetId,
            orElse: () => widget.asset,
          );
          pathItems.add({
            'emoji': toAsset.category.emoji,
            'name': toAsset.category.label,
          });
        } else if (move.toCategoryName != null) {
          final toCategory = AssetCategory.values.firstWhere(
            (c) => c.name == move.toCategoryName,
            orElse: () => AssetCategory.other,
          );
          pathItems.add({'emoji': toCategory.emoji, 'name': toCategory.label});
        }
      } else {
        // 도착
        final fromAsset = allAssets.firstWhere(
          (a) => a.id == move.fromAssetId,
          orElse: () => widget.asset,
        );
        // 이미 경로에 있으면 추가하지 않음
        final alreadyIncluded = pathItems.any(
          (item) => item['emoji'] == fromAsset.category.emoji,
        );
        if (!alreadyIncluded) {
          pathItems.insert(pathItems.length - 1, {
            'emoji': fromAsset.category.emoji,
            'name': fromAsset.category.label,
          });
        }
      }
    }

    // 최대 15개까지만 표시
    final displayItems = pathItems.length > 15
        ? [
            ...pathItems.take(14),
            {'emoji': '...', 'name': '더보기', 'isMore': true},
          ]
        : pathItems;

    return Column(
      children: [
        // 상단: 흐름 표시
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < displayItems.length; i++) ...[
                  _buildPathNode(theme, displayItems[i]),
                  // 화살표
                  if (i < displayItems.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        // 하단: 통계
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                theme,
                '총 이동',
                '${assetMoves.length}회',
                Icons.swap_horiz,
              ),
              _buildStatItem(
                theme,
                '이동 유형',
                _getUniqueMoveTypes(assetMoves),
                Icons.category,
              ),
              _buildStatItem(
                theme,
                '기간',
                _getMoveDateRange(assetMoves),
                Icons.calendar_today,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 경로 노드 빌드
  Widget _buildPathNode(ThemeData theme, Map<String, dynamic> item) {
    final isStart = item['isStart'] ?? false;
    final isMoveType = item['isMoveType'] ?? false;

    if (isMoveType) {
      // 이동 타입 표시 (액션 노드)
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item['emoji'], style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  item['name'],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (item['amount'] != null) ...[
            const SizedBox(height: 4),
            Text(
              item['amount'],
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
          if (item['dateLabel'] != null)
            Text(
              item['dateLabel'],
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      );
    }

    // 자산 카테고리 표시 (상태 노드)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isStart
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStart
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.secondary.withValues(alpha: 0.3),
          width: isStart ? 2 : 1,
        ),
        boxShadow: isStart
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item['emoji'], style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            item['name'],
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 통계 항목 빌드
  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }

  /// 이동 타입에 따른 이모지
  String _getMoveTypeEmoji(AssetMoveType type) {
    switch (type) {
      case AssetMoveType.purchase:
        return '💳'; // 구매
      case AssetMoveType.sale:
        return '💰'; // 판매
      case AssetMoveType.transfer:
        return '➡️'; // 이동
      case AssetMoveType.exchange:
        return '🔄'; // 교환
      case AssetMoveType.deposit:
        return '🏦'; // 예금
    }
  }

  /// 고유 이동 타입 개수
  String _getUniqueMoveTypes(List<AssetMove> moves) {
    final types = moves.map((m) => m.type).toSet();
    return '${types.length}가지';
  }

  /// 이동 기간
  String _getMoveDateRange(List<AssetMove> moves) {
    if (moves.isEmpty) return '-';
    final dates = moves.map((move) => move.date).toList()..sort();
    if (dates.length == 1) {
      return DateFormatter.mmdd.format(dates.first);
    }
    final startLabel = DateFormatter.mmdd.format(dates.first);
    final endLabel = DateFormatter.mmdd.format(dates.last);
    return '$startLabel ~ $endLabel';
  }

  /// 손익 정보 표시 위젯
  Widget _buildProfitLossDisplay(ThemeData theme) {
    if (_currentAsset.costBasis == null || _currentAsset.costBasis! == 0) {
      return const SizedBox.shrink();
    }

    final profitLoss = ProfitLossCalculator.calculateProfitLoss(
      _currentAsset.amount,
      _currentAsset.costBasis,
    );
    final profitLossRate = ProfitLossCalculator.calculateProfitLossRate(
      _currentAsset.amount,
      _currentAsset.costBasis,
    );
    final profitLossColor = ProfitLossCalculator.getProfitLossColor(profitLoss);
    final profitLossLabel = ProfitLossCalculator.getProfitLossLabel(profitLoss);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: profitLossColor.withValues(alpha: 0.1),
        border: Border.all(color: profitLossColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profitLossLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: profitLossColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ProfitLossCalculator.formatProfitLoss(profitLoss),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: profitLossColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            '(${ProfitLossCalculator.formatProfitLossRate(profitLossRate)})',
            style: theme.textTheme.labelMedium?.copyWith(
              color: profitLossColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
