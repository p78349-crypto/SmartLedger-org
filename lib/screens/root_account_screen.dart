import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/root_overview_service.dart';
import '../utils/date_formatter.dart';
import '../utils/dialog_utils.dart';
import '../utils/icon_catalog.dart';
import '../utils/number_formats.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/background_widget.dart';
import '../widgets/root_memo_widget_v2.dart';

part 'root_account_screen_toolbar.dart';
part 'root_account_screen_summary.dart';
part 'root_account_screen_accounts.dart';
part 'root_account_screen_dialogs.dart';
part 'root_account_screen_widgets.dart';

class RootAccountScreen extends StatelessWidget {
  RootAccountScreen({
    super.key,
    required this.overview,
    required this.isLoading,
    required this.errorMessage,
    required this.searchController,
    required this.onRefresh,
    required this.onEnterAccount,
    required this.onDeleteAccount,
    required this.onCreateAccount,
    this.showInlineAccountControls = true,
    this.showSearchField = true,
    this.onOpenSearch,
    this.onOpenTrash,
    this.useScaffold = true,
  });

  final RootFinancialOverview? overview;
  final bool isLoading;
  final String? errorMessage;
  final TextEditingController searchController;
  final Future<void> Function() onRefresh;
  final void Function(String) onEnterAccount;
  final void Function(String) onDeleteAccount;
  final void Function() onCreateAccount;
  final bool showInlineAccountControls;
  final bool showSearchField;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenTrash;
  final bool useScaffold;

  final NumberFormat _numberFormat = NumberFormats.currency;
  final DateFormat _dateFormat = DateFormatter.defaultDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final query = searchController.text.trim().toLowerCase();
    final summaries = (overview?.accountSummaries ?? [])
        .where(
          (summary) => query.isEmpty
              ? true
              : summary.accountName.toLowerCase().contains(query),
        )
        .toList();
    final actionsSection = _buildAccountActions(context, theme);

    final content = SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildAccountToolbar(context, theme),
            const SizedBox(height: 12),
            if (actionsSection != null) ...[
              actionsSection,
              const SizedBox(height: 16),
            ],
            if (errorMessage != null) _buildErrorCard(theme, errorMessage!),
            if (overview != null) ...[
              if (isLoading) const LinearProgressIndicator(),
              if (!isLoading) _buildSummarySection(theme, overview!),
              const SizedBox(height: 16),
              // 📝 ROOT 전용 메모 섹션 추가
              const RootMemoSectionV2(), const SizedBox(height: 24),
              _buildAccountSection(theme, summaries, query, isLandscape),
            ] else if (isLoading) ...[
              const SizedBox(height: 120),
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              _buildEmptyState(theme),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (!useScaffold) {
      return content;
    }

    return ValueListenableBuilder<Color>(
      valueListenable: BackgroundHelper.colorNotifier,
      builder: (context, bgColor, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(title: const Text('ROOT 계정 관리')),
          body: content,
        );
      },
    );
  }

  String _formatCurrency(double value) {
    final sign = value < 0 ? '-' : '';
    final formatted = _numberFormat.format(value.abs());
    return '$sign$formatted원';
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '거래 내역 없음';
    }
    return _dateFormat.format(value);
  }
}
