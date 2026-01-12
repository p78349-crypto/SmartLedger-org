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

part 'asset_dashboard_screen_ui.dart';

/// 자산 대시보드 - 총 자산, 총 손익, 자산별 카드 뷰, 타임라인
class AssetDashboardScreen extends StatefulWidget {
  final String accountName;

  const AssetDashboardScreen({super.key, required this.accountName});

  @override
  State<AssetDashboardScreen> createState() => _AssetDashboardScreenState();
}

class _AssetDashboardScreenState extends State<AssetDashboardScreen> {
  List<Asset> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    await AssetService().loadAssets();
    await AssetMoveService().loadMoves();
    await TransactionService().loadTransactions();
    if (!mounted) return;
    setState(() {
      _assets = AssetService().getAssets(widget.accountName);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) => buildUi(context);
}
