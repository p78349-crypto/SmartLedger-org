import 'package:flutter/material.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/utils/constants.dart';
import 'package:smart_ledger/utils/icon_launch_utils.dart';
import 'package:smart_ledger/utils/main_feature_icon_catalog.dart';
import 'package:smart_ledger/widgets/theme_preview_widget.dart';

/// 기능 아이콘 카탈로그를 파트별로 표시하는 화면
class FeatureIconsCatalogScreen extends StatefulWidget {
  const FeatureIconsCatalogScreen({super.key});

  @override
  State<FeatureIconsCatalogScreen> createState() =>
      _FeatureIconsCatalogScreenState();
}

class _FeatureIconsCatalogScreenState extends State<FeatureIconsCatalogScreen> {
  static const Map<String, String> _partLabelsKo = {
    '0': '대시보드',
    '1': '거래',
    '2': '수입',
    '3': '통계',
    '4': '자산',
    '5': 'ROOT',
    '6': '설정',
    '7': '예비',
    '8': '예비',
    '9': '예약됨',
    '10': '예약됨',
    '11': '예약됨',
    '12': '예약됨',
    '13': '예약됨',
    '14': '예약됨',
  };

  static const Map<String, String> _partLabelsEn = {
    '0': 'Dashboard',
    '1': 'Transactions',
    '2': 'Income',
    '3': 'Stats',
    '4': 'Assets',
    '5': 'ROOT',
    '6': 'Settings',
    '7': 'Spare',
    '8': 'Spare',
    '9': 'Reserved',
    '10': 'Reserved',
    '11': 'Reserved',
    '12': 'Reserved',
    '13': 'Reserved',
    '14': 'Reserved',
  };

  String _partLabelFor(BuildContext context, int pageIndex) {
    final locale = Localizations.localeOf(context);
    final key = '$pageIndex';
    final fallback = 'Page ${pageIndex + 1}';
    final ko = _partLabelsKo[key] ?? fallback;
    final en = _partLabelsEn[key] ?? fallback;

    if (locale.languageCode == 'en') return en;
    if (locale.languageCode == 'ko') return '$ko ($en)';
    return ko;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageCount = MainFeatureIconCatalog.pageCount;

    return Scaffold(
      appBar: AppBar(title: const Text('기능 아이콘 카탈로그')),
      body: pageCount == 0
          ? Center(
              child: Text('표시할 페이지가 없습니다', style: theme.textTheme.bodyMedium),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pageCount,
              itemBuilder: (context, pageIndex) {
                final page = MainFeatureIconCatalog.pages[pageIndex];
                final partLabel = _partLabelFor(context, pageIndex);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageSection(context, theme, partLabel, page),
                    if (page.index == 6)
                      // Page 7 (UI page 7) - show theme preview
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: ThemePreviewWidget(),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildPageSection(
    BuildContext context,
    ThemeData theme,
    String partLabel,
    MainFeaturePage page,
  ) {
    final items = page.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          partLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '(아이콘 없음)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          )
        else
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildIconTile(context, theme, item);
            },
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIconTile(
    BuildContext context,
    ThemeData theme,
    MainFeatureIcon item,
  ) {
    final label = item.labelFor(context);
    return InkWell(
      onTap: () async {
        if (item.routeName == null) return;
        final navigator = Navigator.of(context);
        await AccountService().loadAccounts();
        if (!mounted) return;
        final accountName = AccountService().accounts.isNotEmpty
            ? AccountService().accounts.first.name
            : AppConstants.defaultAccountName;

        final req = IconLaunchUtils.buildRequest(
          routeName: item.routeName!,
          accountName: accountName,
        );

        if (!mounted) return;
        if (req != null) {
          navigator.pushNamed(req.routeName, arguments: req.arguments);
        } else {
          navigator.pushNamed(item.routeName!);
        }
      },
      child: Tooltip(
        message: label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: theme.colorScheme.onSurfaceVariant,
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
