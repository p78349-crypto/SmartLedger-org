import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_move.dart';
import '../services/asset_move_service.dart';
import '../services/asset_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/profit_loss_calculator.dart';
import 'asset_evaluation_screen.dart';

part 'asset_detail_screen_detail.dart';
part 'asset_detail_screen_timeline.dart';
part 'asset_detail_screen_flow.dart';
part 'asset_detail_screen_widgets.dart';
part 'asset_detail_screen_performance.dart';

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
}
