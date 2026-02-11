library asset_dashboard_screen;

import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../models/asset_move.dart';
import '../services/asset_move_service.dart';
import '../services/asset_service.dart';
import '../services/asset_security_service.dart';
import '../services/transaction_service.dart';
import '../utils/asset_dashboard_utils.dart';
import '../utils/icon_catalog.dart';
import 'asset_detail_screen.dart';
import 'asset_allocation_screen.dart';
import 'one_hundred_million_project_screen.dart';

part 'asset_dashboard_screen_ui.dart';

/// 자산 대시보드 - 총 자산, 총 손익, 자산별 카드 뷰, 타임라인
class AssetDashboardScreen extends StatefulWidget {
  final String accountName;
  final List<Asset>? assets;

  const AssetDashboardScreen({
    super.key,
    required this.accountName,
    this.assets,
  });

  @override
  State<AssetDashboardScreen> createState() => _AssetDashboardScreenState();
}

class _AssetDashboardScreenState extends State<AssetDashboardScreen> {
  List<Asset> _internalAssets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.assets != null) {
      _internalAssets = widget.assets!;
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  @override
  void didUpdateWidget(AssetDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.assets != null) {
      setState(() {
        _internalAssets = widget.assets!;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (widget.assets != null) return;
    if (mounted) {
      setState(() => _isLoading = true);
    }
    await AssetService().loadAssets();
    await AssetMoveService().loadMoves();
    await TransactionService().loadTransactions();
    if (!mounted) return;
    setState(() {
      _internalAssets = AssetService().getAssets(widget.accountName);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) => buildUi(context);
}
