import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/screens/asset_detail_screen.dart';
import 'package:smart_ledger/screens/asset_input_screen.dart';
import 'package:smart_ledger/services/asset_service.dart';
import 'package:smart_ledger/utils/date_formatter.dart';
import 'package:smart_ledger/utils/dialog_utils.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/profit_loss_calculator.dart';
import 'package:smart_ledger/utils/snackbar_utils.dart';
import 'package:smart_ledger/widgets/asset_move_dialog.dart';
import 'package:smart_ledger/widgets/smart_input_field.dart';
import 'package:smart_ledger/widgets/state_placeholders.dart';

class AssetListScreen extends StatefulWidget {
  final String accountName;
  const AssetListScreen({super.key, required this.accountName});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormats.currency;
  final DateFormat _dateFormat = DateFormatter.defaultDate;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: '삭제 확인',
      message: '선택한 ${_selectedIds.length}개 항목을 삭제하시겠습니까?',
      confirmText: '삭제',
      isDangerous: true,
    );

    if (confirmed) {
      final assetService = AssetService();
      for (final id in _selectedIds) {
        await assetService.deleteAsset(widget.accountName, id);
      }
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      if (mounted) {
        SnackbarUtils.showSuccess(context, '삭제되었습니다');
      }
    }
  }

  Future<void> _editSelected() async {
    if (_selectedIds.length != 1) {
      SnackbarUtils.showWarning(context, '수정할 항목을 1개만 선택하세요');
      return;
    }

    final assets = AssetService().getAssets(widget.accountName);
    final asset = assets.firstWhere((a) => a.id == _selectedIds.first);

    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AssetInputScreen(
          accountName: widget.accountName,
          initialAsset: asset,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  List<Asset> _getFilteredAssets() {
    final assets = AssetService().getAssets(widget.accountName);
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return assets;
    }

    return assets.where((asset) {
      return asset.name.toLowerCase().contains(query) ||
          asset.memo.toLowerCase().contains(query);
    }).toList();
  }

  String _getAssetTypeLabel(Asset asset) {
    return asset.inputType == AssetInputType.simple ? '간단' : '상세';
  }

  Future<void> _showAssetActionSheet(Asset asset) async {
    final rootContext = context;
    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                asset.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${asset.category.label} · '
                    '${_dateFormat.format(asset.date)}',
                  ),
                  if (asset.memo.isNotEmpty) Text(asset.memo),
                ],
              ),
              trailing: Text(
                '${_currencyFormat.format(asset.amount)}원',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 4),
            ListTile(
              leading: Icon(
                IconCatalog.infoOutline,
                color: theme.colorScheme.secondary,
              ),
              title: const Text('상세보기'),
              subtitle: const Text('이동 기록 타임라인'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  rootContext,
                  MaterialPageRoute(
                    builder: (_) => AssetDetailScreen(
                      accountName: widget.accountName,
                      asset: asset,
                    ),
                  ),
                );
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: Icon(IconCatalog.edit, color: theme.colorScheme.primary),
              title: const Text('편집'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssetInputScreen(
                      accountName: widget.accountName,
                      initialAsset: asset,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(IconCatalog.refresh, color: Colors.blue),
              title: const Text('이동'),
              subtitle: const Text('다른 자산으로 이동'),
              onTap: () async {
                Navigator.pop(context);
                final result = await showDialog<bool>(
                  context: rootContext,
                  builder: (_) => AssetMoveDialog(
                    accountName: widget.accountName,
                    fromAsset: asset,
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(IconCatalog.delete, color: Colors.red),
              title: const Text('삭제'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await DialogUtils.showConfirmDialog(
                  rootContext,
                  title: '자산 삭제',
                  message: '${asset.name}을(를) 삭제할까요?',
                  confirmText: '삭제',
                  isDangerous: true,
                );
                if (confirmed) {
                  await AssetService().deleteAsset(
                    widget.accountName,
                    asset.id,
                  );
                  if (!mounted) return;
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAssets = _getFilteredAssets();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.accountName} - 자산 목록')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '자산 목록',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _toggleSelectionMode,
                  child: Text(_isSelectionMode ? '취소' : '선택'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SmartInputField(
              hint: '자산명 또는 메모로 검색',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: filteredAssets.isEmpty
                ? EmptyState(
                    title: _searchController.text.trim().isEmpty
                        ? '자산이 없습니다'
                        : '검색 결과가 없습니다',
                    message: _searchController.text.trim().isEmpty
                        ? '자산을 추가해 관리하세요.'
                        : '검색어를 변경하거나 초기화하세요.',
                    secondaryLabel: _searchController.text.trim().isNotEmpty
                        ? '검색 초기화'
                        : null,
                    onSecondary: _searchController.text.trim().isNotEmpty
                        ? () {
                            _searchController.clear();
                            setState(() {});
                          }
                        : null,
                  )
                : isLandscape
                ? ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredAssets.length + 1,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        const headerStyle = TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        );

                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 40),
                              Expanded(
                                flex: 7,
                                child: Text(
                                  '자산',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: headerStyle,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  '손익',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: headerStyle,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '금액',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: headerStyle,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '타입',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: headerStyle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final asset = filteredAssets[index - 1];
                      final isSelected = _selectedIds.contains(asset.id);

                      final profitLoss =
                          ProfitLossCalculator.calculateProfitLoss(
                            asset.amount,
                            asset.costBasis,
                          );
                      final profitLossRate =
                          ProfitLossCalculator.calculateProfitLossRate(
                            asset.amount,
                            asset.costBasis,
                          );
                      final profitLossColor =
                          ProfitLossCalculator.getProfitLossColor(profitLoss);
                      final profitLossLabel =
                          ProfitLossCalculator.formatProfitLoss(profitLoss);
                      final profitLossRateLabel =
                          ProfitLossCalculator.formatProfitLossRate(
                            profitLossRate,
                          );

                      final hasProfitLoss =
                          asset.costBasis != null && asset.costBasis! > 0;
                      final profitLossText = hasProfitLoss
                          ? '$profitLossLabel ($profitLossRateLabel)'
                          : '';

                      final assetLabel = asset.memo.isNotEmpty
                          ? '${asset.name} · ${asset.memo}'
                          : asset.name;

                      final amountLabel =
                          '${_currencyFormat.format(asset.amount)}원';

                      return InkWell(
                        onTap: _isSelectionMode
                            ? () => _toggleSelection(asset.id)
                            : () => _showAssetActionSheet(asset),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: _isSelectionMode
                                    ? Checkbox(
                                        value: isSelected,
                                        onChanged: (_) =>
                                            _toggleSelection(asset.id),
                                      )
                                    : null,
                              ),
                              Expanded(
                                flex: 7,
                                child: Text(
                                  assetLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  profitLossText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: profitLossColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    amountLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _getAssetTypeLabel(asset),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredAssets.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final asset = filteredAssets[index];
                      final isSelected = _selectedIds.contains(asset.id);
                      // ✅ 손익 계산
                      final profitLoss =
                          ProfitLossCalculator.calculateProfitLoss(
                            asset.amount,
                            asset.costBasis,
                          );
                      final profitLossRate =
                          ProfitLossCalculator.calculateProfitLossRate(
                            asset.amount,
                            asset.costBasis,
                          );
                      final profitLossColor =
                          ProfitLossCalculator.getProfitLossColor(profitLoss);
                      final profitLossLabel =
                          ProfitLossCalculator.formatProfitLoss(profitLoss);
                      final profitLossRateLabel =
                          ProfitLossCalculator.formatProfitLossRate(
                            profitLossRate,
                          );

                      return ListTile(
                        leading: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(asset.id),
                              )
                            : null,
                        title: Text(asset.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (asset.memo.isNotEmpty) Text(asset.memo),
                            // ✅ 손익 표시 (원가가 있는 경우만)
                            if (asset.costBasis != null && asset.costBasis! > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '$profitLossLabel ($profitLossRateLabel)',
                                  style: TextStyle(
                                    color: profitLossColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_currencyFormat.format(asset.amount)}원',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _getAssetTypeLabel(asset),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        onTap: _isSelectionMode
                            ? () => _toggleSelection(asset.id)
                            : () => _showAssetActionSheet(asset),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode && _selectedIds.isNotEmpty
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteSelected,
                        icon: const Icon(Icons.delete),
                        label: Text('삭제 (${_selectedIds.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedIds.length == 1
                            ? _editSelected
                            : null,
                        icon: const Icon(Icons.edit),
                        label: const Text('수정'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
