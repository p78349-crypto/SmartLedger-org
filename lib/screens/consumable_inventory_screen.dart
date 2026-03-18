import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../models/shopping_cart_item.dart';
import '../repositories/app_repositories.dart';
import '../services/consumable_inventory_service.dart';
import '../services/user_pref_service.dart';
import '../utils/wms_data_gateway.dart';
import '../utils/snackbar_utils.dart';
import 'consumable_inventory_dialogs.dart';
import 'consumable_inventory_screen_widgets.dart';
import 'wms_io_screen.dart';

part 'consumable_inventory_screen_logic.dart';
part 'consumable_inventory_screen_ui.dart';

class ConsumableInventoryScreen extends StatefulWidget {
  final String accountName;

  const ConsumableInventoryScreen({super.key, required this.accountName});

  @override
  State<ConsumableInventoryScreen> createState() =>
      _ConsumableInventoryScreenState();
}

class _ConsumableInventoryScreenState extends State<ConsumableInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  String _locationFilter = '전체';
  String _categoryFilter = '전체';
  String _expiryFilter = '전체';
  bool _isCartSelectionMode = false;
  final Set<String> _selectedForCartIds = {};

  Set<String> _countLikeUnits = UserPrefService.defaultCountLikeUnitsV1.toSet();

  String _formatQty(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  bool _isCountLikeUnit(String unit) {
    final u = unit.trim();
    if (u.isEmpty) return false;
    return _countLikeUnits.contains(u);
  }

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      if (_mainTabController.indexIsChanging) {
        setState(() {
          _locationFilter = '전체';
        });
      }
    });

    // ✅ Gateway를 통한 초기 로드 (캐싱 적용)
    WmsInventoryGateway.instance.getItems();
    _loadCountLikeUnits();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  // 로케이션 필터 옵션 (전체 + 실제 데이터에 존재하는 위치들)
  List<String> get _locationOptions {
    final items = ConsumableInventoryService.instance.items.value;
    final isWarehouseTab = _mainTabController.index == 1;

    final locs =
        items
            .where(
              (e) =>
                  isWarehouseTab ? (e.location == '창고') : (e.location != '창고'),
            )
            .map((e) => e.location)
            .toSet()
            .toList()
          ..sort();

    if (isWarehouseTab) return ['전체']; // 창고 탭은 사실상 단일 위치라 필터가 필요없을 수 있음
    return ['전체', ...locs];
  }

  List<String> get _categoryOptions {
    final items = ConsumableInventoryService.instance.items.value;
    final cats = items.map((e) => e.category).toSet().toList()..sort();
    return ['전체', ...cats];
  }

  List<String> get _expiryOptions => ['전체', '임박', '경과'];

  @override
  @override
  Widget build(BuildContext context) => _buildContent(context);
}
